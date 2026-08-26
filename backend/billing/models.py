from decimal import Decimal
from uuid import uuid4

from django.contrib.auth.models import AbstractUser
from django.core.validators import MinValueValidator
from django.db import models
from django.utils import timezone


MONEY = {"max_digits": 14, "decimal_places": 2, "default": Decimal("0.00")}


def make_number(prefix):
    return f"{prefix}-{timezone.now():%Y%m%d}-{uuid4().hex[:6].upper()}"


def quotation_number():
    return make_number("QT")


def invoice_number():
    return make_number("INV")


def receipt_number():
    return make_number("RCPT")


def purchase_order_number():
    return make_number("PO")


def return_number():
    return make_number("RET")


class TimeStampedModel(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        abstract = True


class User(AbstractUser):
    class Role(models.TextChoices):
        SALES = "sales", "Sales"
        ACCOUNTANT = "accountant", "Accountant"
        INVENTORY = "inventory", "Inventory"
        MANAGER = "manager", "Store Manager"
        CASHIER = "cashier", "Cashier"
        ADMIN = "admin", "Admin"

    email = models.EmailField(unique=True)
    employee_id = models.CharField(max_length=30, unique=True, null=True, blank=True, db_index=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.SALES)
    phone = models.CharField(max_length=20, blank=True)
    branch = models.CharField(max_length=120, default="Main Branch")
    last_logout = models.DateTimeField(null=True, blank=True)

    def __str__(self):
        return self.get_full_name() or self.username


class Client(TimeStampedModel):
    name = models.CharField(max_length=200)
    contact_person = models.CharField(max_length=150)
    whatsapp_mobile = models.CharField(max_length=20)
    email = models.EmailField(blank=True)
    gstin = models.CharField(max_length=15, blank=True, db_index=True)
    billing_address = models.TextField()
    credit_limit = models.DecimalField(**MONEY)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Category(TimeStampedModel):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]
        verbose_name_plural = "categories"

    def __str__(self):
        return self.name


class Supplier(TimeStampedModel):
    name = models.CharField(max_length=200)
    contact_person = models.CharField(max_length=150, blank=True)
    phone = models.CharField(max_length=20, blank=True)
    email = models.EmailField(blank=True)
    gstin = models.CharField(max_length=15, blank=True)
    address = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Brand(TimeStampedModel):
    name = models.CharField(max_length=120, unique=True)
    categories = models.ManyToManyField(Category, related_name="brands", blank=True)
    manufacturer = models.CharField(max_length=160, blank=True)
    country = models.CharField(max_length=80, blank=True)
    website = models.URLField(blank=True)
    contact_email = models.EmailField(blank=True)
    description = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    def __str__(self):
        return self.name


class Rack(TimeStampedModel):
    name = models.CharField(max_length=100)
    branch = models.CharField(max_length=120, default="Main Branch")
    display_order = models.PositiveIntegerField(default=0)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["display_order", "name"]
        constraints = [
            models.UniqueConstraint(fields=["name", "branch"], name="unique_rack_name_branch")
        ]

    def __str__(self):
        return self.name


class Item(TimeStampedModel):
    class ItemType(models.TextChoices):
        SERVICE = "service", "Service"
        MATERIAL = "material", "Material"

    item_type = models.CharField(max_length=10, choices=ItemType.choices)
    name = models.CharField(max_length=200)
    sku = models.CharField(max_length=50, unique=True)
    barcode = models.CharField(max_length=80, unique=True, null=True, blank=True, db_index=True)
    description = models.TextField(blank=True)
    manual_details = models.JSONField(default=dict, blank=True)
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="items")
    brand = models.ForeignKey(Brand, on_delete=models.SET_NULL, null=True, blank=True, related_name="items")
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name="items")
    rack = models.ForeignKey(Rack, on_delete=models.SET_NULL, null=True, blank=True, related_name="items")
    unit = models.CharField(max_length=30, default="unit")
    store_section = models.CharField(max_length=100, default="General", db_index=True)
    rack_location = models.CharField(max_length=60, blank=True, db_index=True)
    selling_price = models.DecimalField(**MONEY)
    purchase_price = models.DecimalField(**MONEY)
    mrp = models.DecimalField(max_digits=14, decimal_places=2, null=True, blank=True)
    image = models.ImageField(upload_to="products/%Y/%m/", blank=True)
    price_source_url = models.URLField(blank=True)
    price_verified_at = models.DateField(null=True, blank=True)
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("18.00"))
    stock_quantity = models.IntegerField(default=0)
    store_stock = models.PositiveIntegerField(default=0)
    shelf_stock = models.PositiveIntegerField(default=0)
    shelf_added_date = models.DateField(null=True, blank=True)
    last_stock_review_date = models.DateField(null=True, blank=True)
    reorder_level = models.PositiveIntegerField(default=5)
    expiry_date = models.DateField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    class Meta:
        ordering = ["name"]

    @property
    def stock_status(self):
        if self.item_type == self.ItemType.SERVICE:
            return "not_applicable"
        if self.stock_quantity <= 0:
            return "out_of_stock"
        if self.stock_quantity <= self.reorder_level:
            return "low_stock"
        return "in_stock"

    @property
    def total_stock(self):
        split_total = self.store_stock + self.shelf_stock
        return split_total if split_total or self.stock_quantity == 0 else self.stock_quantity

    def __str__(self):
        return f"{self.name} ({self.sku})"

class ProductPriceHistory(TimeStampedModel):
    """A manual price schedule.  Future prices never rewrite old invoices."""
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="price_history")
    purchase_price = models.DecimalField(**MONEY)
    selling_price = models.DecimalField(**MONEY)
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("18.00"))
    effective_date = models.DateField(db_index=True)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="product_price_changes")

    class Meta:
        ordering = ["-effective_date", "-created_at"]
        constraints = [models.UniqueConstraint(fields=["item", "effective_date"], name="unique_item_price_effective_date")]


class StoreStock(TimeStampedModel):
    product = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="store_stocks")
    branch = models.CharField(max_length=120, default="Main Branch", db_index=True)
    quantity = models.PositiveIntegerField(default=0)
    minimum_quantity = models.PositiveIntegerField(default=0)
    updated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="store_stock_updates")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["product", "branch"], name="unique_store_stock_product_branch")]


class ShelfStock(TimeStampedModel):
    product = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="shelf_stocks")
    branch = models.CharField(max_length=120, default="Main Branch", db_index=True)
    quantity = models.PositiveIntegerField(default=0)
    target_quantity = models.PositiveIntegerField(default=0)
    minimum_quantity = models.PositiveIntegerField(default=0)
    shelf_added_date = models.DateTimeField(null=True, blank=True)
    last_refill_date = models.DateTimeField(null=True, blank=True)
    updated_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="shelf_stock_updates")

    class Meta:
        constraints = [models.UniqueConstraint(fields=["product", "branch"], name="unique_shelf_stock_product_branch")]

    @property
    def refill_required(self):
        return max(self.target_quantity - self.quantity, 0)

    @property
    def shelf_status(self):
        if self.quantity == 0:
            return "OUT_OF_SHELF_STOCK"
        if self.quantity < self.minimum_quantity:
            return "LOW_SHELF_STOCK"
        if self.quantity < self.target_quantity:
            return "REFILL_REQUIRED"
        return "FULL"


class StockMovement(TimeStampedModel):
    class MovementType(models.TextChoices):
        PURCHASE_TO_STORE = "PURCHASE_TO_STORE", "Purchase to store"
        STORE_TO_SHELF = "STORE_TO_SHELF", "Store to shelf"
        SHELF_TO_STORE = "SHELF_TO_STORE", "Shelf to store"
        SALE_FROM_SHELF = "SALE_FROM_SHELF", "Sale from shelf"
        STOCK_ADJUSTMENT = "STOCK_ADJUSTMENT", "Stock adjustment"
        RETURN_TO_SUPPLIER = "RETURN_TO_SUPPLIER", "Return to supplier"
        DISPOSAL = "DISPOSAL", "Disposal"
        CLEARANCE_SALE = "CLEARANCE_SALE", "Clearance sale"
        MANUAL_REFILL = "MANUAL_REFILL", "Manual refill"
        AUTO_REFILL = "AUTO_REFILL", "Auto refill"
        INITIAL_STORE_STOCK = "INITIAL_STORE_STOCK", "Initial store stock"
        INITIAL_SHELF_STOCK = "INITIAL_SHELF_STOCK", "Initial shelf stock"

    product = models.ForeignKey(Item, on_delete=models.PROTECT, related_name="stock_movements")
    branch = models.CharField(max_length=120, default="Main Branch", db_index=True)
    movement_type = models.CharField(max_length=32, choices=MovementType.choices)
    source_location = models.CharField(max_length=20, blank=True)
    destination_location = models.CharField(max_length=20, blank=True)
    quantity = models.PositiveIntegerField()
    store_before = models.PositiveIntegerField()
    store_after = models.PositiveIntegerField()
    shelf_before = models.PositiveIntegerField()
    shelf_after = models.PositiveIntegerField()
    reference_type = models.CharField(max_length=40, blank=True)
    reference_id = models.CharField(max_length=80, blank=True)
    performed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name="stock_movements")
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]


class InventoryTransaction(TimeStampedModel):
    class TransactionType(models.TextChoices):
        STOCK_IN = "stock_in", "Stock In"
        STOCK_OUT = "stock_out", "Stock Out"
        ADJUSTMENT = "adjustment", "Adjustment"
        SALE = "sale", "Sale"

    item = models.ForeignKey(Item, on_delete=models.PROTECT, related_name="stock_transactions")
    transaction_type = models.CharField(max_length=20, choices=TransactionType.choices)
    quantity = models.IntegerField(help_text="Signed quantity: positive adds, negative removes")
    previous_stock = models.IntegerField()
    new_stock = models.IntegerField()
    reference = models.CharField(max_length=100, blank=True)
    notes = models.TextField(blank=True)
    performed_by = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, related_name="inventory_transactions"
    )

    class Meta:
        ordering = ["-created_at"]


class ProductBatch(TimeStampedModel):
    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="batches")
    batch_number = models.CharField(max_length=80, db_index=True)
    quantity = models.PositiveIntegerField(default=0)
    manufactured_date = models.DateField(null=True, blank=True)
    expiry_date = models.DateField(db_index=True)
    purchase_date = models.DateField(default=timezone.localdate)
    supplier = models.ForeignKey(Supplier, on_delete=models.SET_NULL, null=True, blank=True)
    shelf_quantity = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=20, default="active")

    class Meta:
        ordering = ["expiry_date"]
        constraints = [models.UniqueConstraint(fields=["item", "batch_number"], name="unique_item_batch")]


class StockReview(TimeStampedModel):
    class Status(models.TextChoices):
        DUE = "due", "Due"
        UPDATED = "updated", "Updated"
        OVERDUE = "overdue", "Overdue"

    item = models.ForeignKey(Item, on_delete=models.CASCADE, related_name="stock_reviews")
    system_quantity = models.IntegerField()
    physical_quantity = models.IntegerField()
    difference = models.IntegerField(default=0)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.UPDATED)
    reviewed_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="stock_reviews")
    reviewed_at = models.DateTimeField(default=timezone.now)
    next_review_date = models.DateField(db_index=True)

    class Meta:
        ordering = ["next_review_date"]


class StockAdjustment(TimeStampedModel):
    item = models.ForeignKey(Item, on_delete=models.PROTECT, related_name="stock_adjustments")
    previous_quantity = models.IntegerField()
    new_quantity = models.IntegerField()
    difference = models.IntegerField()
    reason = models.TextField()
    adjusted_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="stock_adjustments")

    class Meta:
        ordering = ["-created_at"]


class Quotation(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PENDING_APPROVAL = "pending_approval", "Pending Approval"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        CONVERTED = "converted", "Converted to Invoice"

    number = models.CharField(max_length=40, unique=True, default=quotation_number)
    client = models.ForeignKey(Client, on_delete=models.PROTECT, related_name="quotations")
    created_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="quotations")
    status = models.CharField(max_length=25, choices=Status.choices, default=Status.DRAFT)
    delivery_date = models.DateField(null=True, blank=True)
    notes = models.TextField(blank=True)
    discount_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("0.00")
    )
    cgst_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("9.00")
    )
    sgst_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("9.00")
    )
    subtotal = models.DecimalField(**MONEY)
    discount_amount = models.DecimalField(**MONEY)
    taxable_amount = models.DecimalField(**MONEY)
    cgst_amount = models.DecimalField(**MONEY)
    sgst_amount = models.DecimalField(**MONEY)
    total = models.DecimalField(**MONEY)

    class Meta:
        ordering = ["-created_at"]

    def recalculate(self):
        subtotal = sum((line.amount for line in self.items.all()), Decimal("0.00"))
        discount = subtotal * self.discount_percent / Decimal("100")
        taxable = subtotal - discount
        self.subtotal = subtotal
        self.discount_amount = discount
        self.taxable_amount = taxable
        self.cgst_amount = taxable * self.cgst_percent / Decimal("100")
        self.sgst_amount = taxable * self.sgst_percent / Decimal("100")
        self.total = taxable + self.cgst_amount + self.sgst_amount
        self.save(update_fields=[
            "subtotal", "discount_amount", "taxable_amount", "cgst_amount",
            "sgst_amount", "total", "updated_at"
        ])

    def __str__(self):
        return self.number


class QuotationItem(TimeStampedModel):
    quotation = models.ForeignKey(Quotation, on_delete=models.CASCADE, related_name="items")
    item = models.ForeignKey(Item, on_delete=models.PROTECT, related_name="quotation_lines")
    name = models.CharField(max_length=200)
    sku = models.CharField(max_length=50)
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    unit_price = models.DecimalField(**MONEY)
    amount = models.DecimalField(**MONEY)

    class Meta:
        ordering = ["id"]

    def save(self, *args, **kwargs):
        self.name = self.name or self.item.name
        self.sku = self.sku or self.item.sku
        self.amount = self.unit_price * self.quantity
        super().save(*args, **kwargs)


class DiscountApproval(TimeStampedModel):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    quotation = models.ForeignKey(Quotation, on_delete=models.CASCADE, related_name="approvals")
    requested_percent = models.DecimalField(max_digits=5, decimal_places=2)
    requested_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="requested_approvals")
    reviewed_by = models.ForeignKey(
        User, on_delete=models.PROTECT, null=True, blank=True, related_name="reviewed_approvals"
    )
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    request_note = models.TextField(blank=True)
    review_note = models.TextField(blank=True)
    decided_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]


class Invoice(TimeStampedModel):
    class Status(models.TextChoices):
        UNPAID = "unpaid", "Unpaid"
        PARTIAL = "partial", "Partially Paid"
        PAID = "paid", "Paid"
        OVERDUE = "overdue", "Overdue"
        CANCELLED = "cancelled", "Cancelled"

    number = models.CharField(max_length=40, unique=True, default=invoice_number)
    quotation = models.OneToOneField(
        Quotation, on_delete=models.PROTECT, null=True, blank=True, related_name="invoice"
    )
    client = models.ForeignKey(Client, on_delete=models.PROTECT, related_name="invoices")
    created_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="invoices")
    invoice_date = models.DateField(default=timezone.localdate)
    due_date = models.DateField()
    status = models.CharField(max_length=15, choices=Status.choices, default=Status.UNPAID)
    subtotal = models.DecimalField(**MONEY)
    discount_amount = models.DecimalField(**MONEY)
    taxable_amount = models.DecimalField(**MONEY)
    cgst_amount = models.DecimalField(**MONEY)
    sgst_amount = models.DecimalField(**MONEY)
    total = models.DecimalField(**MONEY)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-invoice_date", "-created_at"]

    @property
    def paid_amount(self):
        return sum(
            (payment.amount for payment in self.payments.filter(status=Payment.Status.VERIFIED)),
            Decimal("0.00"),
        )

    @property
    def balance_due(self):
        return max(self.total - self.paid_amount, Decimal("0.00"))

    def __str__(self):
        return self.number


class InvoiceItem(TimeStampedModel):
    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="items")
    item = models.ForeignKey(Item, on_delete=models.PROTECT, related_name="invoice_lines")
    name = models.CharField(max_length=200)
    sku = models.CharField(max_length=50)
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    unit_price = models.DecimalField(**MONEY)
    amount = models.DecimalField(**MONEY)

    class Meta:
        ordering = ["id"]

    def save(self, *args, **kwargs):
        self.name = self.name or self.item.name
        self.sku = self.sku or self.item.sku
        self.amount = self.unit_price * self.quantity
        super().save(*args, **kwargs)


class Payment(TimeStampedModel):
    class PaymentType(models.TextChoices):
        FULL = "full", "Full"
        ADVANCE = "advance", "Advance"
        PARTIAL = "partial", "Partial"

    class Method(models.TextChoices):
        UPI = "upi", "UPI"
        RAZORPAY = "razorpay", "Razorpay"
        BANK = "bank", "Bank Transfer"
        CARD = "card", "Card"
        CASH = "cash", "Cash"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending Verification"
        VERIFIED = "verified", "Verified"
        REJECTED = "rejected", "Rejected"

    receipt_number = models.CharField(max_length=40, unique=True, default=receipt_number)
    invoice = models.ForeignKey(Invoice, on_delete=models.PROTECT, related_name="payments")
    payment_type = models.CharField(max_length=10, choices=PaymentType.choices)
    method = models.CharField(max_length=10, choices=Method.choices)
    amount = models.DecimalField(max_digits=14, decimal_places=2, validators=[MinValueValidator(Decimal("0.01"))])
    transaction_reference = models.CharField(max_length=100, blank=True)
    cash_received = models.DecimalField(**MONEY)
    balance_returned = models.DecimalField(**MONEY)
    proof = models.ImageField(upload_to="payment_proofs/%Y/%m/", blank=True)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    collected_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="collected_payments")
    verified_by = models.ForeignKey(
        User, on_delete=models.PROTECT, null=True, blank=True, related_name="verified_payments"
    )
    verified_at = models.DateTimeField(null=True, blank=True)
    stock_processed = models.BooleanField(default=False)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ["-created_at"]
        constraints = [
            models.UniqueConstraint(
                fields=["transaction_reference"],
                condition=models.Q(method="razorpay"),
                name="unique_razorpay_payment_reference",
            )
        ]

    def __str__(self):
        return self.receipt_number


class WhatsAppMessage(TimeStampedModel):
    class MessageType(models.TextChoices):
        INVOICE = "invoice", "Invoice"
        REMINDER = "reminder", "Reminder"
        TEXT = "text", "Text"

    class Status(models.TextChoices):
        QUEUED = "queued", "Queued"
        SENT = "sent", "Sent"
        DELIVERED = "delivered", "Delivered"
        READ = "read", "Read"
        FAILED = "failed", "Failed"

    invoice = models.ForeignKey(Invoice, on_delete=models.CASCADE, related_name="whatsapp_messages")
    recipient = models.CharField(max_length=20)
    message = models.TextField()
    message_type = models.CharField(max_length=10, choices=MessageType.choices, default=MessageType.TEXT)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.QUEUED)
    provider_message_id = models.CharField(max_length=150, blank=True)
    sent_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="sent_messages")
    sent_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["created_at"]


class RolePermission(TimeStampedModel):
    role = models.CharField(max_length=30, unique=True)
    dashboard = models.BooleanField(default=True)
    products = models.BooleanField(default=False)
    billing = models.BooleanField(default=False)
    inventory = models.BooleanField(default=False)
    discounts = models.BooleanField(default=False)
    reports = models.BooleanField(default=False)
    returns = models.BooleanField(default=False)
    settings = models.BooleanField(default=False)

    class Meta:
        ordering = ["role"]

    def __str__(self):
        return self.role.replace("_", " ").title()


class PurchaseOrder(TimeStampedModel):
    class Status(models.TextChoices):
        DRAFT = "draft", "Draft"
        PENDING = "pending", "Pending Approval"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"
        RECEIVED = "received", "Received"

    number = models.CharField(max_length=40, unique=True, default=purchase_order_number)
    supplier = models.ForeignKey(Supplier, on_delete=models.PROTECT, related_name="purchase_orders")
    order_date = models.DateField(default=timezone.localdate)
    status = models.CharField(max_length=12, choices=Status.choices, default=Status.PENDING)
    subtotal = models.DecimalField(**MONEY)
    tax_amount = models.DecimalField(**MONEY)
    total = models.DecimalField(**MONEY)
    notes = models.TextField(blank=True)
    created_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="created_purchase_orders")
    reviewed_by = models.ForeignKey(User, on_delete=models.PROTECT, null=True, blank=True, related_name="reviewed_purchase_orders")
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-order_date", "-created_at"]

    def recalculate(self):
        subtotal = sum((line.amount for line in self.items.all()), Decimal("0.00"))
        tax = sum((line.tax_amount for line in self.items.all()), Decimal("0.00"))
        self.subtotal, self.tax_amount, self.total = subtotal, tax, subtotal + tax
        self.save(update_fields=["subtotal", "tax_amount", "total", "updated_at"])

    def __str__(self):
        return self.number


class PurchaseOrderItem(TimeStampedModel):
    purchase_order = models.ForeignKey(PurchaseOrder, on_delete=models.CASCADE, related_name="items")
    item = models.ForeignKey(Item, on_delete=models.PROTECT, related_name="purchase_order_lines")
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    unit_cost = models.DecimalField(**MONEY)
    tax_percent = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("0.00"))
    amount = models.DecimalField(**MONEY)
    tax_amount = models.DecimalField(**MONEY)

    class Meta:
        ordering = ["id"]

    def save(self, *args, **kwargs):
        self.amount = self.unit_cost * self.quantity
        self.tax_amount = self.amount * self.tax_percent / Decimal("100")
        super().save(*args, **kwargs)


class ReturnRequest(TimeStampedModel):
    class Method(models.TextChoices):
        CASH = "cash", "Cash"
        ORIGINAL = "original", "Original Payment"
        CREDIT = "credit", "Store Credit"
        REPLACEMENT = "replacement", "Replacement"

    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        APPROVED = "approved", "Approved"
        REJECTED = "rejected", "Rejected"

    number = models.CharField(max_length=40, unique=True, default=return_number)
    invoice = models.ForeignKey(Invoice, on_delete=models.PROTECT, related_name="returns")
    reason = models.TextField()
    refund_method = models.CharField(max_length=15, choices=Method.choices)
    refund_amount = models.DecimalField(**MONEY)
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    requested_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name="requested_returns")
    reviewed_by = models.ForeignKey(User, on_delete=models.PROTECT, null=True, blank=True, related_name="reviewed_returns")
    reviewed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        ordering = ["-created_at"]


class ReturnItem(TimeStampedModel):
    return_request = models.ForeignKey(ReturnRequest, on_delete=models.CASCADE, related_name="items")
    invoice_item = models.ForeignKey(InvoiceItem, on_delete=models.PROTECT, related_name="return_lines")
    quantity = models.PositiveIntegerField(validators=[MinValueValidator(1)])
    amount = models.DecimalField(**MONEY)


class StoreSettings(TimeStampedModel):
    store_name = models.CharField(max_length=150, default="Supermarket")
    invoice_prefix = models.CharField(max_length=12, default="BILL-")
    default_gst = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("5.00"))
    max_cashier_discount = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("10.00"))
    approval_threshold = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("10.00"))
    round_off = models.DecimalField(max_digits=5, decimal_places=2, default=Decimal("0.01"))
    whatsapp_enabled = models.BooleanField(default=False)
    auto_refill_enabled = models.BooleanField(default=True)

    class Meta:
        verbose_name_plural = "store settings"


class AuditLog(models.Model):
    user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="audit_logs")
    action = models.CharField(max_length=120)
    module = models.CharField(max_length=50)
    object_type = models.CharField(max_length=80, blank=True)
    object_id = models.CharField(max_length=80, blank=True)
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    device = models.CharField(max_length=255, blank=True)
    description = models.TextField(blank=True)
    metadata = models.JSONField(default=dict, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
