from django.core.exceptions import ValidationError
from django.db import transaction
from django.utils import timezone

from ...models import Item, ShelfStock, StockMovement, StoreSettings, StoreStock


DEFAULT_BRANCH = "Main Branch"


def branch_for(user=None, branch=None):
    return (branch or getattr(user, "branch", None) or DEFAULT_BRANCH).strip()


def _legacy_opening(product):
    store = product.store_stock
    shelf = product.shelf_stock
    if store == 0 and shelf == 0 and product.stock_quantity:
        store = product.stock_quantity
    return store, shelf


def get_stock(product, branch=DEFAULT_BRANCH, *, lock=False, user=None):
    branch = branch_for(user, branch)
    store_manager = StoreStock.objects.select_for_update() if lock else StoreStock.objects
    shelf_manager = ShelfStock.objects.select_for_update() if lock else ShelfStock.objects
    initial_store, initial_shelf = _legacy_opening(product)
    store, _ = store_manager.get_or_create(
        product=product,
        branch=branch,
        defaults={"quantity": initial_store, "minimum_quantity": product.reorder_level},
    )
    shelf, _ = shelf_manager.get_or_create(
        product=product,
        branch=branch,
        defaults={
            "quantity": initial_shelf,
            "target_quantity": initial_shelf,
            "minimum_quantity": min(product.reorder_level, initial_shelf),
            "shelf_added_date": timezone.now() if initial_shelf else None,
        },
    )
    return store, shelf


def _sync_legacy(product, store, shelf):
    product.store_stock = store.quantity
    product.shelf_stock = shelf.quantity
    product.stock_quantity = store.quantity + shelf.quantity
    product.shelf_added_date = shelf.shelf_added_date.date() if shelf.shelf_added_date else None
    product.save(update_fields=["store_stock", "shelf_stock", "stock_quantity", "shelf_added_date", "updated_at"])


def _movement(product, branch, movement_type, quantity, store_before, store, shelf_before, shelf, *, user=None, source="", destination="", reference_type="", reference_id="", notes=""):
    return StockMovement.objects.create(
        product=product, branch=branch, movement_type=movement_type,
        source_location=source, destination_location=destination, quantity=quantity,
        store_before=store_before, store_after=store.quantity,
        shelf_before=shelf_before, shelf_after=shelf.quantity,
        reference_type=reference_type, reference_id=str(reference_id or ""),
        performed_by=user, notes=notes,
    )


@transaction.atomic
def initialize_stock(product, *, branch=DEFAULT_BRANCH, store_quantity=None, shelf_quantity=None, target_quantity=None, minimum_quantity=None, user=None):
    branch = branch_for(user, branch)
    legacy_store, legacy_shelf = _legacy_opening(product)
    store_quantity = legacy_store if store_quantity is None else int(store_quantity)
    shelf_quantity = legacy_shelf if shelf_quantity is None else int(shelf_quantity)
    if min(store_quantity, shelf_quantity) < 0:
        raise ValidationError("Opening stock cannot be negative.")
    store, _ = StoreStock.objects.update_or_create(
        product=product, branch=branch,
        defaults={"quantity": store_quantity, "minimum_quantity": minimum_quantity if minimum_quantity is not None else product.reorder_level, "updated_by": user},
    )
    shelf, _ = ShelfStock.objects.update_or_create(
        product=product, branch=branch,
        defaults={"quantity": shelf_quantity, "target_quantity": target_quantity if target_quantity is not None else shelf_quantity, "minimum_quantity": min(product.reorder_level, shelf_quantity), "shelf_added_date": timezone.now() if shelf_quantity else None, "updated_by": user},
    )
    _sync_legacy(product, store, shelf)
    if store_quantity:
        _movement(product, branch, StockMovement.MovementType.INITIAL_STORE_STOCK, store_quantity, 0, store, 0, ShelfStock(quantity=0), user=user, destination="STORE", notes="Opening store stock")
    if shelf_quantity:
        _movement(product, branch, StockMovement.MovementType.INITIAL_SHELF_STOCK, shelf_quantity, store.quantity, store, 0, shelf, user=user, destination="SHELF", notes="Opening shelf stock")
    return store, shelf


@transaction.atomic
def transfer_store_to_shelf(product, quantity, *, branch=DEFAULT_BRANCH, user=None, movement_type=StockMovement.MovementType.MANUAL_REFILL, notes=""):
    quantity = int(quantity)
    if quantity <= 0:
        raise ValidationError("Quantity must be greater than zero.")
    branch = branch_for(user, branch)
    store, shelf = get_stock(product, branch, lock=True)
    if store.quantity < quantity:
        raise ValidationError(f"Insufficient store stock. Available: {store.quantity}.")
    store_before, shelf_before = store.quantity, shelf.quantity
    store.quantity -= quantity
    shelf.quantity += quantity
    shelf.last_refill_date = timezone.now()
    shelf.shelf_added_date = shelf.shelf_added_date or timezone.now()
    store.updated_by = shelf.updated_by = user
    store.save()
    shelf.save()
    _sync_legacy(product, store, shelf)
    _movement(product, branch, movement_type, quantity, store_before, store, shelf_before, shelf, user=user, source="STORE", destination="SHELF", notes=notes)
    return stock_result(store, shelf, transferred=quantity)


@transaction.atomic
def transfer_shelf_to_store(product, quantity, *, branch=DEFAULT_BRANCH, user=None, notes=""):
    quantity = int(quantity)
    if quantity <= 0:
        raise ValidationError("Quantity must be greater than zero.")
    branch = branch_for(user, branch)
    store, shelf = get_stock(product, branch, lock=True)
    if shelf.quantity < quantity:
        raise ValidationError(f"Insufficient shelf stock. Available: {shelf.quantity}.")
    store_before, shelf_before = store.quantity, shelf.quantity
    shelf.quantity -= quantity
    store.quantity += quantity
    store.updated_by = shelf.updated_by = user
    store.save()
    shelf.save()
    _sync_legacy(product, store, shelf)
    _movement(product, branch, StockMovement.MovementType.SHELF_TO_STORE, quantity, store_before, store, shelf_before, shelf, user=user, source="SHELF", destination="STORE", notes=notes)
    return stock_result(store, shelf, transferred=quantity)


def calculate_refill_quantity(shelf):
    return max(shelf.target_quantity - shelf.quantity, 0)


@transaction.atomic
def adjust_store_stock(product, quantity, *, branch=DEFAULT_BRANCH, user=None, notes="", movement_type=StockMovement.MovementType.STOCK_ADJUSTMENT, reference_id=""):
    quantity = int(quantity)
    if quantity == 0:
        raise ValidationError("Stock change cannot be zero.")
    branch = branch_for(user, branch)
    store, shelf = get_stock(product, branch, lock=True)
    if store.quantity + quantity < 0:
        raise ValidationError(f"Store stock cannot become negative. Available: {store.quantity}.")
    store_before, shelf_before = store.quantity, shelf.quantity
    store.quantity += quantity
    store.updated_by = user
    store.save()
    _sync_legacy(product, store, shelf)
    _movement(product, branch, movement_type, abs(quantity), store_before, store, shelf_before, shelf, user=user, source="SUPPLIER" if quantity > 0 else "STORE", destination="STORE" if quantity > 0 else "ADJUSTMENT", reference_type="ADJUSTMENT", reference_id=reference_id, notes=notes)
    return stock_result(store, shelf)


@transaction.atomic
def adjust_shelf_stock(product, quantity, *, branch=DEFAULT_BRANCH, user=None, notes="", movement_type=StockMovement.MovementType.STOCK_ADJUSTMENT, reference_id=""):
    quantity = int(quantity)
    if quantity == 0:
        raise ValidationError("Stock change cannot be zero.")
    branch = branch_for(user, branch)
    store, shelf = get_stock(product, branch, lock=True)
    if shelf.quantity + quantity < 0:
        raise ValidationError(f"Shelf stock cannot become negative. Available: {shelf.quantity}.")
    store_before, shelf_before = store.quantity, shelf.quantity
    shelf.quantity += quantity
    shelf.updated_by = user
    shelf.save()
    _sync_legacy(product, store, shelf)
    _movement(product, branch, movement_type, abs(quantity), store_before, store, shelf_before, shelf, user=user, source="ADJUSTMENT" if quantity > 0 else "SHELF", destination="SHELF" if quantity > 0 else "ADJUSTMENT", reference_type="ADJUSTMENT", reference_id=reference_id, notes=notes)
    return stock_result(store, shelf)


@transaction.atomic
def auto_refill_shelf(product, *, branch=DEFAULT_BRANCH, user=None):
    branch = branch_for(user, branch)
    store, shelf = get_stock(product, branch, lock=True)
    required = calculate_refill_quantity(shelf)
    transfer = min(required, store.quantity)
    if transfer <= 0:
        result = stock_result(store, shelf, transferred=0, required=required)
        result["status"] = "STORE_OUT_OF_STOCK" if required else shelf.shelf_status
        return result
    store_before, shelf_before = store.quantity, shelf.quantity
    store.quantity -= transfer
    shelf.quantity += transfer
    shelf.last_refill_date = timezone.now()
    store.updated_by = shelf.updated_by = user
    store.save()
    shelf.save()
    _sync_legacy(product, store, shelf)
    _movement(product, branch, StockMovement.MovementType.AUTO_REFILL, transfer, store_before, store, shelf_before, shelf, user=user, source="STORE", destination="SHELF", notes="Automatic refill to shelf target")
    result = stock_result(store, shelf, transferred=transfer, required=required)
    if transfer < required:
        result["status"] = "PARTIAL_REFILL"
    return result


@transaction.atomic
def deduct_shelf_for_sale(product, quantity, *, branch=DEFAULT_BRANCH, user=None, reference_id=""):
    quantity = int(quantity)
    if quantity <= 0:
        raise ValidationError("Sale quantity must be greater than zero.")
    branch = branch_for(user, branch)
    store, shelf = get_stock(product, branch, lock=True)
    if quantity > store.quantity + shelf.quantity:
        raise ValidationError(f"Insufficient stock. Available: {store.quantity + shelf.quantity}.")
    missing = max(quantity - shelf.quantity, 0)
    if missing:
        transfer_store_to_shelf(product, missing, branch=branch, user=user, movement_type=StockMovement.MovementType.AUTO_REFILL, notes="Pre-sale shelf refill")
        store, shelf = get_stock(product, branch, lock=True)
    store_before, shelf_before = store.quantity, shelf.quantity
    shelf.quantity -= quantity
    shelf.updated_by = user
    shelf.save()
    _sync_legacy(product, store, shelf)
    _movement(product, branch, StockMovement.MovementType.SALE_FROM_SHELF, quantity, store_before, store, shelf_before, shelf, user=user, source="SHELF", destination="CUSTOMER", reference_type="INVOICE", reference_id=reference_id, notes="POS sale")
    settings = StoreSettings.objects.first()
    refill = auto_refill_shelf(product, branch=branch, user=user) if settings is None or settings.auto_refill_enabled else None
    return {**stock_result(store, shelf, transferred=0), "refill": refill}


def stock_result(store, shelf, *, transferred=0, required=None):
    required = calculate_refill_quantity(shelf) if required is None else required
    return {
        "success": True, "transferred_quantity": transferred,
        "store_quantity": store.quantity, "shelf_quantity": shelf.quantity,
        "total_quantity": store.quantity + shelf.quantity,
        "target_quantity": shelf.target_quantity, "refill_required": required,
        "status": shelf.shelf_status,
    }
