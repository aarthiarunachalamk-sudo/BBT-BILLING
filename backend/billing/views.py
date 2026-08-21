from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.db import models, transaction
from django.db.models import Count, Q, Sum
from django.db.models.functions import TruncDate
from django.utils import timezone
from rest_framework import filters, permissions, status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response
from rest_framework_simplejwt.views import TokenObtainPairView

from .models import (
    AuditLog,
    Category,
    Client,
    DiscountApproval,
    InventoryTransaction,
    Invoice,
    InvoiceItem,
    Item,
    Payment,
    ProductBatch,
    PurchaseOrder,
    Quotation,
    Supplier,
    ReturnRequest,
    RolePermission,
    StoreSettings,
    StockAdjustment,
    StockReview,
    WhatsAppMessage,
)
from .serializers import (
    AuditLogSerializer,
    CategorySerializer,
    ClientSerializer,
    DiscountApprovalSerializer,
    EmailTokenObtainPairSerializer,
    InventoryTransactionSerializer,
    InvoiceSerializer,
    ItemSerializer,
    PaymentSerializer,
    ProductBatchSerializer,
    PurchaseOrderSerializer,
    QuotationSerializer,
    SupplierSerializer,
    ReturnRequestSerializer,
    RolePermissionSerializer,
    StoreSettingsSerializer,
    StockAdjustmentSerializer,
    StockReviewSerializer,
    UserSerializer,
    WhatsAppMessageSerializer,
)


User = get_user_model()


class IsAdminOrManager(permissions.BasePermission):
    def has_permission(self, request, view):
        return bool(
            request.user
            and request.user.is_authenticated
            and (request.user.is_superuser or request.user.role in {User.Role.ADMIN, User.Role.MANAGER})
        )


class AdminTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == status.HTTP_200_OK and response.data.get("user"):
            user = User.objects.filter(pk=response.data["user"]["id"]).first()
            forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip()
            AuditLog.objects.create(user=user, action="Login", module="Auth", ip_address=forwarded or request.META.get("REMOTE_ADDR"), device=request.META.get("HTTP_USER_AGENT", "")[:255])
        return response


@api_view(["POST"])
@permission_classes([permissions.AllowAny])
def change_password(request):
    identifier = str(request.data.get("identifier", "")).strip()
    current_password = str(request.data.get("current_password", ""))
    new_password = str(request.data.get("new_password", ""))
    if not identifier or not current_password or not new_password:
        return Response(
            {"detail": "Username/email, current password, and new password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    query = {"email__iexact": identifier} if "@" in identifier else {"username__iexact": identifier}
    user = User.objects.filter(**query).first()
    if user is None or not user.is_active or not user.check_password(current_password):
        return Response(
            {"detail": "The username/email or current password is incorrect."},
            status=status.HTTP_400_BAD_REQUEST,
        )
    if user.check_password(new_password):
        return Response(
            {"detail": "The new password must be different from the current password."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        validate_password(new_password, user=user)
    except ValidationError as exception:
        return Response(
            {"detail": " ".join(exception.messages)},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.set_password(new_password)
    user.save(update_fields=["password"])
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip()
    AuditLog.objects.create(
        user=user,
        action="Password changed",
        module="Auth",
        ip_address=forwarded or request.META.get("REMOTE_ADDR"),
        device=request.META.get("HTTP_USER_AGENT", "")[:255],
    )
    return Response({"detail": "Password changed successfully."})


@api_view(["POST"])
@permission_classes([permissions.IsAuthenticated])
def logout_view(request):
    request.user.last_logout = timezone.now()
    request.user.save(update_fields=["last_logout"])
    record_audit(request, "Logout", "Auth")
    return Response({"detail": "Logged out successfully."})


@api_view(["GET"])
@permission_classes([permissions.IsAuthenticated])
def current_user(request):
    return Response(UserSerializer(request.user).data)


def record_audit(request, action, module, instance=None, metadata=None):
    forwarded = request.META.get("HTTP_X_FORWARDED_FOR", "").split(",")[0].strip()
    AuditLog.objects.create(
        user=request.user if request.user.is_authenticated else None,
        action=action,
        module=module,
        object_type=instance.__class__.__name__ if instance else "",
        object_id=str(instance.pk) if instance else "",
        ip_address=forwarded or request.META.get("REMOTE_ADDR"),
        device=request.META.get("HTTP_USER_AGENT", "")[:255],
        metadata=metadata or {},
    )


class SearchableModelViewSet(viewsets.ModelViewSet):
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]

    def perform_create(self, serializer):
        instance = serializer.save()
        record_audit(self.request, f"{instance.__class__.__name__} created", instance.__class__.__name__, instance)

    def perform_update(self, serializer):
        instance = serializer.save()
        record_audit(self.request, f"{instance.__class__.__name__} updated", instance.__class__.__name__, instance)

    def perform_destroy(self, instance):
        record_audit(self.request, f"{instance.__class__.__name__} deleted", instance.__class__.__name__, instance)
        instance.delete()


class UserViewSet(SearchableModelViewSet):
    queryset = User.objects.all().order_by("first_name", "username")
    serializer_class = UserSerializer
    permission_classes = [IsAdminOrManager]
    search_fields = ["username", "employee_id", "email", "first_name", "last_name", "phone", "branch"]
    ordering_fields = ["username", "first_name", "date_joined"]

    def get_queryset(self):
        queryset = super().get_queryset()
        role = self.request.query_params.get("role")
        branch = self.request.query_params.get("branch")
        active = self.request.query_params.get("status")
        if role:
            queryset = queryset.filter(role=role)
        if branch:
            queryset = queryset.filter(branch__iexact=branch)
        if active in {"active", "inactive"}:
            queryset = queryset.filter(is_active=active == "active")
        return queryset

    @action(detail=True, methods=["post"])
    def activate(self, request, pk=None):
        user = self.get_object()
        user.is_active = True
        user.save(update_fields=["is_active"])
        record_audit(request, "User activated", "Users", user)
        return Response(self.get_serializer(user).data)

    @action(detail=True, methods=["post"])
    def deactivate(self, request, pk=None):
        user = self.get_object()
        user.is_active = False
        user.save(update_fields=["is_active"])
        record_audit(request, "User deactivated", "Users", user)
        return Response(self.get_serializer(user).data)

    @action(detail=True, methods=["get"])
    def activity(self, request, pk=None):
        return Response(AuditLogSerializer(self.get_object().audit_logs.all()[:100], many=True).data)

    @action(detail=True, methods=["get"])
    def summary(self, request, pk=None):
        user = self.get_object()
        today = timezone.localdate()
        invoices = Invoice.objects.filter(created_by=user, invoice_date=today)
        payments = Payment.objects.filter(collected_by=user, status=Payment.Status.VERIFIED, verified_at__date=today)
        by_method = {row["method"]: row["total"] for row in payments.values("method").annotate(total=Sum("amount"))}
        return Response({
            **UserSerializer(user).data,
            "today_bills": invoices.count(),
            "today_sales": invoices.aggregate(total=Sum("total"))["total"] or Decimal("0.00"),
            "cash_collection": by_method.get(Payment.Method.CASH, Decimal("0.00")),
            "upi_collection": by_method.get(Payment.Method.UPI, Decimal("0.00")),
            "card_collection": by_method.get(Payment.Method.CARD, Decimal("0.00")),
            "stock_updated_count": InventoryTransaction.objects.filter(performed_by=user, created_at__date=today).count(),
            "last_activity": AuditLogSerializer(user.audit_logs.first()).data if user.audit_logs.exists() else None,
        })


class ClientViewSet(SearchableModelViewSet):
    queryset = Client.objects.all()
    serializer_class = ClientSerializer
    search_fields = ["name", "contact_person", "whatsapp_mobile", "email", "gstin"]
    ordering_fields = ["name", "created_at"]


class CategoryViewSet(SearchableModelViewSet):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    search_fields = ["name"]
    ordering_fields = ["name", "created_at"]


class SupplierViewSet(SearchableModelViewSet):
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer
    search_fields = ["name", "contact_person", "phone", "gstin"]
    ordering_fields = ["name", "created_at"]


class ItemViewSet(SearchableModelViewSet):
    queryset = Item.objects.select_related("category", "supplier").all()
    serializer_class = ItemSerializer
    search_fields = ["name", "sku", "description", "category__name"]
    ordering_fields = ["name", "selling_price", "stock_quantity", "created_at"]

    def perform_create(self, serializer):
        item = serializer.save()
        if item.stock_quantity and not item.store_stock and not item.shelf_stock:
            item.store_stock = item.stock_quantity
            item.save(update_fields=["store_stock"])
        if item.item_type == Item.ItemType.MATERIAL and item.stock_quantity > 0:
            InventoryTransaction.objects.create(
                item=item,
                transaction_type=InventoryTransaction.TransactionType.STOCK_IN,
                quantity=item.stock_quantity,
                previous_stock=0,
                new_stock=item.stock_quantity,
                reference="Opening stock",
                notes="Opening stock recorded when product was created.",
                performed_by=self.request.user,
            )
        record_audit(self.request, "Item created", "Item", item)

    def perform_update(self, serializer):
        old_price = serializer.instance.selling_price
        item = serializer.save()
        # If the selling price changed, update all open quotation lines that
        # reference this item so the cashier always sees the current price.
        if item.selling_price != old_price:
            open_statuses = {
                Quotation.Status.DRAFT,
                Quotation.Status.PENDING_APPROVAL,
                Quotation.Status.APPROVED,
            }
            from .models import QuotationItem  # local import avoids circular
            affected_quotation_ids = set()
            for line in QuotationItem.objects.filter(
                item=item,
                quotation__status__in=open_statuses,
            ).select_related("quotation"):
                line.unit_price = item.selling_price
                line.amount = line.unit_price * line.quantity
                line.save(update_fields=["unit_price", "amount", "updated_at"])
                affected_quotation_ids.add(line.quotation_id)
            # Recalculate totals on each affected quotation.
            for quotation in Quotation.objects.filter(pk__in=affected_quotation_ids):
                quotation.recalculate()
        record_audit(
            self.request,
            "Item updated",
            "Item",
            item,
            metadata={"price_cascaded": item.selling_price != old_price},
        )

    def get_queryset(self):
        queryset = super().get_queryset()
        item_type = self.request.query_params.get("type")
        active = self.request.query_params.get("active")
        category = self.request.query_params.get("category")
        stock_status = self.request.query_params.get("stock_status")
        if item_type:
            queryset = queryset.filter(item_type=item_type)
        if active in {"true", "false"}:
            queryset = queryset.filter(is_active=active == "true")
        if category:
            queryset = queryset.filter(category_id=category)
        if stock_status == "low_stock":
            queryset = queryset.filter(stock_quantity__gt=0, stock_quantity__lte=models.F("reorder_level"))
        elif stock_status == "out_of_stock":
            queryset = queryset.filter(stock_quantity=0)
        return queryset

    @action(detail=False, methods=["get"], url_path="current-stock")
    def current_stock(self, request):
        return Response(self.get_serializer(self.filter_queryset(self.get_queryset()), many=True).data)

    @action(detail=False, methods=["get"], url_path="shelf-stock")
    def shelf_stock_list(self, request):
        queryset = self.get_queryset().filter(shelf_stock__gt=0)
        age_days = int(request.query_params.get("age_days", 0) or 0)
        if age_days:
            queryset = queryset.filter(shelf_added_date__lte=timezone.localdate() - timedelta(days=age_days))
        return Response(self.get_serializer(queryset, many=True).data)

    @action(detail=True, methods=["post"])
    def adjust_stock(self, request, pk=None):
        item = self.get_object()
        if item.item_type != Item.ItemType.MATERIAL:
            return Response({"detail": "Services do not have stock."}, status=status.HTTP_400_BAD_REQUEST)
        try:
            quantity = int(request.data.get("quantity"))
        except (TypeError, ValueError):
            return Response({"quantity": "Enter a signed whole number."}, status=status.HTTP_400_BAD_REQUEST)
        if quantity == 0 or item.stock_quantity + quantity < 0:
            return Response({"quantity": "Stock cannot become negative and change cannot be zero."}, status=status.HTTP_400_BAD_REQUEST)

        previous = item.total_stock
        item.store_stock = max(item.store_stock + quantity, 0)
        item.stock_quantity = item.store_stock + item.shelf_stock
        item.save(update_fields=["store_stock", "stock_quantity", "updated_at"])
        transaction_type = request.data.get("transaction_type", InventoryTransaction.TransactionType.ADJUSTMENT)
        stock_entry = InventoryTransaction.objects.create(
            item=item,
            transaction_type=transaction_type,
            quantity=quantity,
            previous_stock=previous,
            new_stock=item.stock_quantity,
            reference=request.data.get("reference", ""),
            notes=request.data.get("notes", ""),
            performed_by=request.user,
        )
        return Response(InventoryTransactionSerializer(stock_entry).data, status=status.HTTP_201_CREATED)


class ProductBatchViewSet(SearchableModelViewSet):
    queryset = ProductBatch.objects.select_related("item", "supplier").all()
    serializer_class = ProductBatchSerializer
    search_fields = ["item__name", "item__sku", "batch_number"]

    def get_queryset(self):
        queryset = super().get_queryset()
        range_name = self.request.query_params.get("range")
        today = timezone.localdate()
        ranges = {"expired": (None, -1), "7": (0, 7), "30": (8, 30), "90": (31, 90)}
        if range_name in ranges:
            start, end = ranges[range_name]
            if start is None:
                queryset = queryset.filter(expiry_date__lt=today)
            else:
                queryset = queryset.filter(expiry_date__range=(today + timedelta(days=start), today + timedelta(days=end)))
        return queryset

    @action(detail=True, methods=["post"], url_path="remove-from-shelf")
    def remove_from_shelf(self, request, pk=None):
        return self._set_status(request, "removed")

    @action(detail=True, methods=["post"], url_path="return-supplier")
    def return_supplier(self, request, pk=None):
        return self._set_status(request, "returned")

    @action(detail=True, methods=["post"])
    def dispose(self, request, pk=None):
        return self._set_status(request, "disposed")

    @action(detail=True, methods=["post"])
    def clearance(self, request, pk=None):
        return self._set_status(request, "clearance")

    def _set_status(self, request, value):
        batch = self.get_object()
        batch.status = value
        batch.save(update_fields=["status", "updated_at"])
        record_audit(request, f"Expiry batch {value}", "Inventory", batch)
        return Response(self.get_serializer(batch).data)


class StockReviewViewSet(viewsets.ModelViewSet):
    queryset = StockReview.objects.select_related("item", "reviewed_by").all()
    serializer_class = StockReviewSerializer

    def get_queryset(self):
        queryset = super().get_queryset()
        status_name = self.request.query_params.get("status")
        today = timezone.localdate()
        if status_name == "due": queryset = queryset.filter(next_review_date=today)
        if status_name == "overdue": queryset = queryset.filter(next_review_date__lt=today).exclude(status=StockReview.Status.UPDATED)
        if status_name == "updated": queryset = queryset.filter(status=StockReview.Status.UPDATED)
        return queryset

    @transaction.atomic
    def perform_create(self, serializer):
        item = Item.objects.select_for_update().get(pk=self.request.data.get("item"))
        physical = int(self.request.data.get("physical_quantity"))
        previous = item.total_stock
        difference = physical - previous
        review = serializer.save(system_quantity=previous, difference=difference, status=StockReview.Status.UPDATED, reviewed_by=self.request.user, reviewed_at=timezone.now(), next_review_date=timezone.localdate() + timedelta(days=14))
        if difference:
            StockAdjustment.objects.create(item=item, previous_quantity=previous, new_quantity=physical, difference=difference, reason=self.request.data.get("reason", "Physical stock review"), adjusted_by=self.request.user)
            item.store_stock = max(physical - item.shelf_stock, 0)
            item.stock_quantity = item.store_stock + item.shelf_stock
        item.last_stock_review_date = timezone.localdate()
        item.save(update_fields=["store_stock", "stock_quantity", "last_stock_review_date", "updated_at"])
        record_audit(self.request, "Quantity review completed", "Inventory", review, {"difference": difference})


class StockAdjustmentViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = StockAdjustment.objects.select_related("item", "adjusted_by").all()
    serializer_class = StockAdjustmentSerializer


class InventoryTransactionViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = InventoryTransaction.objects.select_related("item", "performed_by").all()
    serializer_class = InventoryTransactionSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["item__name", "item__sku", "reference", "notes"]
    ordering_fields = ["created_at", "new_stock"]


class QuotationViewSet(SearchableModelViewSet):
    queryset = Quotation.objects.select_related("client", "created_by").prefetch_related("items").all()
    serializer_class = QuotationSerializer
    search_fields = ["number", "client__name"]
    ordering_fields = ["created_at", "delivery_date", "total"]

    def perform_create(self, serializer):
        serializer.save(created_by=self.request.user)

    @action(detail=True, methods=["post"])
    def request_discount(self, request, pk=None):
        quotation = self.get_object()
        serializer = DiscountApprovalSerializer(data={
            "quotation": quotation.pk,
            "requested_percent": request.data.get("requested_percent"),
            "request_note": request.data.get("request_note", ""),
        })
        serializer.is_valid(raise_exception=True)
        approval = serializer.save(requested_by=request.user)
        quotation.status = Quotation.Status.PENDING_APPROVAL
        quotation.save(update_fields=["status", "updated_at"])
        return Response(DiscountApprovalSerializer(approval).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def convert_to_invoice(self, request, pk=None):
        quotation = self.get_object()
        if quotation.status not in {Quotation.Status.APPROVED, Quotation.Status.DRAFT}:
            return Response({"detail": "Only a draft or approved quotation can be invoiced."}, status=status.HTTP_400_BAD_REQUEST)
        if hasattr(quotation, "invoice"):
            return Response(InvoiceSerializer(quotation.invoice).data)
        due_date = request.data.get("due_date")
        if not due_date:
            return Response({"due_date": "This field is required (YYYY-MM-DD)."}, status=status.HTTP_400_BAD_REQUEST)

        invoice = Invoice.objects.create(
            quotation=quotation,
            client=quotation.client,
            created_by=request.user,
            due_date=due_date,
            subtotal=quotation.subtotal,
            discount_amount=quotation.discount_amount,
            taxable_amount=quotation.taxable_amount,
            cgst_amount=quotation.cgst_amount,
            sgst_amount=quotation.sgst_amount,
            total=quotation.total,
            notes=quotation.notes,
        )
        InvoiceItem.objects.bulk_create([
            InvoiceItem(
                invoice=invoice,
                item=line.item,
                name=line.name,
                sku=line.sku,
                quantity=line.quantity,
                unit_price=line.unit_price,
                amount=line.amount,
            )
            for line in quotation.items.all()
        ])
        quotation.status = Quotation.Status.CONVERTED
        quotation.save(update_fields=["status", "updated_at"])
        return Response(InvoiceSerializer(invoice).data, status=status.HTTP_201_CREATED)


class DiscountApprovalViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = DiscountApproval.objects.select_related("quotation", "requested_by", "reviewed_by").all()
    serializer_class = DiscountApprovalSerializer

    @action(detail=True, methods=["post"])
    def decide(self, request, pk=None):
        approval = self.get_object()
        decision = request.data.get("decision")
        if approval.status != DiscountApproval.Status.PENDING:
            return Response({"detail": "This request has already been decided."}, status=status.HTTP_400_BAD_REQUEST)
        if decision not in {DiscountApproval.Status.APPROVED, DiscountApproval.Status.REJECTED}:
            return Response({"decision": "Use 'approved' or 'rejected'."}, status=status.HTTP_400_BAD_REQUEST)

        approval.status = decision
        approval.reviewed_by = request.user
        approval.review_note = request.data.get("review_note", "")
        approval.decided_at = timezone.now()
        approval.save()

        quotation = approval.quotation
        if decision == DiscountApproval.Status.APPROVED:
            quotation.discount_percent = approval.requested_percent
            quotation.status = Quotation.Status.APPROVED
            quotation.save(update_fields=["discount_percent", "status", "updated_at"])
            quotation.recalculate()
        else:
            quotation.status = Quotation.Status.REJECTED
            quotation.save(update_fields=["status", "updated_at"])
        return Response(self.get_serializer(approval).data)


class InvoiceViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Invoice.objects.select_related("client", "created_by", "quotation").prefetch_related("items", "payments").all()
    serializer_class = InvoiceSerializer
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["number", "client__name", "client__whatsapp_mobile"]
    ordering_fields = ["invoice_date", "due_date", "total", "created_at"]


class PaymentViewSet(SearchableModelViewSet):
    queryset = Payment.objects.select_related("invoice", "collected_by", "verified_by").all()
    serializer_class = PaymentSerializer
    search_fields = ["receipt_number", "invoice__number", "transaction_reference"]
    ordering_fields = ["created_at", "amount"]

    def perform_create(self, serializer):
        serializer.save(collected_by=self.request.user)

    @action(detail=False, methods=["get"])
    def summary(self, request):
        queryset = self.get_queryset().filter(status=Payment.Status.VERIFIED)
        range_name = request.query_params.get("range", "today")
        today = timezone.localdate()
        if range_name == "today": queryset = queryset.filter(verified_at__date=today)
        elif range_name == "yesterday": queryset = queryset.filter(verified_at__date=today - timedelta(days=1))
        elif range_name == "week": queryset = queryset.filter(verified_at__date__gte=today - timedelta(days=6))
        elif range_name == "month": queryset = queryset.filter(verified_at__date__gte=today.replace(day=1))
        rows = list(queryset.values("method").annotate(total=Sum("amount"), count=Count("id")).order_by("method"))
        return Response({"total_sales": queryset.aggregate(total=Sum("amount"))["total"] or Decimal("0.00"), "total_transactions": queryset.count(), "payment_breakdown": rows})

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def verify(self, request, pk=None):
        payment = Payment.objects.select_for_update().select_related("invoice").get(pk=pk)
        if payment.status == Payment.Status.VERIFIED:
            return Response(self.get_serializer(payment).data)
        if payment.status == Payment.Status.REJECTED:
            return Response({"detail": "A rejected payment cannot be verified."}, status=status.HTTP_400_BAD_REQUEST)

        invoice = payment.invoice
        already_processed = invoice.payments.filter(status=Payment.Status.VERIFIED, stock_processed=True).exists()
        if not already_processed:
            material_lines = []
            for line in invoice.items.select_related("item"):
                item = Item.objects.select_for_update().get(pk=line.item_id)
                if item.item_type != Item.ItemType.MATERIAL:
                    continue
                if item.stock_quantity < line.quantity:
                    return Response(
                        {"detail": f"Not enough stock for {item.name}. Available: {item.stock_quantity}."},
                        status=status.HTTP_400_BAD_REQUEST,
                    )
                material_lines.append((line, item))

            for line, item in material_lines:
                previous = item.stock_quantity
                item.stock_quantity -= line.quantity
                item.save(update_fields=["stock_quantity", "updated_at"])
                InventoryTransaction.objects.create(
                    item=item,
                    transaction_type=InventoryTransaction.TransactionType.SALE,
                    quantity=-line.quantity,
                    previous_stock=previous,
                    new_stock=item.stock_quantity,
                    reference=invoice.number,
                    notes=f"Automatic deduction for {payment.receipt_number}",
                    performed_by=request.user,
                )
            payment.stock_processed = True

        payment.status = Payment.Status.VERIFIED
        payment.verified_by = request.user
        payment.verified_at = timezone.now()
        payment.save(update_fields=["status", "verified_by", "verified_at", "stock_processed", "updated_at"])

        verified_total = invoice.payments.filter(status=Payment.Status.VERIFIED).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")
        invoice.status = Invoice.Status.PAID if verified_total >= invoice.total else Invoice.Status.PARTIAL
        invoice.save(update_fields=["status", "updated_at"])
        return Response(self.get_serializer(payment).data)

    @action(detail=True, methods=["post"])
    def reject(self, request, pk=None):
        payment = self.get_object()
        if payment.status != Payment.Status.PENDING:
            return Response({"detail": "Only pending payments can be rejected."}, status=status.HTTP_400_BAD_REQUEST)
        payment.status = Payment.Status.REJECTED
        payment.verified_by = request.user
        payment.verified_at = timezone.now()
        payment.notes = request.data.get("notes", payment.notes)
        payment.save()
        return Response(self.get_serializer(payment).data)


class WhatsAppMessageViewSet(SearchableModelViewSet):
    queryset = WhatsAppMessage.objects.select_related("invoice", "sent_by").all()
    serializer_class = WhatsAppMessageSerializer
    search_fields = ["invoice__number", "recipient", "message"]
    ordering_fields = ["created_at", "sent_at"]

    def perform_create(self, serializer):
        message = serializer.save(sent_by=self.request.user)
        record_audit(self.request, "Invoice message queued", "WhatsApp", message)


class RolePermissionViewSet(SearchableModelViewSet):
    queryset = RolePermission.objects.all()
    serializer_class = RolePermissionSerializer
    permission_classes = [permissions.IsAdminUser]
    search_fields = ["role"]

    def perform_update(self, serializer):
        permission = serializer.save()
        record_audit(self.request, "Permissions updated", "Roles", permission)


class PurchaseOrderViewSet(SearchableModelViewSet):
    queryset = PurchaseOrder.objects.select_related("supplier", "created_by", "reviewed_by").prefetch_related("items__item")
    serializer_class = PurchaseOrderSerializer
    search_fields = ["number", "supplier__name"]
    ordering_fields = ["order_date", "total", "created_at"]

    def perform_create(self, serializer):
        order = serializer.save(created_by=self.request.user)
        record_audit(self.request, "Purchase order created", "Purchase", order)

    @action(detail=True, methods=["post"])
    def decide(self, request, pk=None):
        order = self.get_object()
        decision = request.data.get("decision")
        if order.status != PurchaseOrder.Status.PENDING:
            return Response({"detail": "Only pending orders can be decided."}, status=status.HTTP_400_BAD_REQUEST)
        if decision not in {PurchaseOrder.Status.APPROVED, PurchaseOrder.Status.REJECTED}:
            return Response({"decision": "Use 'approved' or 'rejected'."}, status=status.HTTP_400_BAD_REQUEST)
        order.status = decision
        order.reviewed_by = request.user
        order.reviewed_at = timezone.now()
        order.save(update_fields=["status", "reviewed_by", "reviewed_at", "updated_at"])
        record_audit(request, f"Purchase order {decision}", "Purchase", order)
        return Response(self.get_serializer(order).data)

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def receive(self, request, pk=None):
        order = PurchaseOrder.objects.select_for_update().get(pk=pk)
        if order.status != PurchaseOrder.Status.APPROVED:
            return Response({"detail": "Only approved orders can be received."}, status=status.HTTP_400_BAD_REQUEST)
        for line in order.items.select_related("item"):
            item = Item.objects.select_for_update().get(pk=line.item_id)
            previous = item.stock_quantity
            item.stock_quantity += line.quantity
            item.save(update_fields=["stock_quantity", "updated_at"])
            InventoryTransaction.objects.create(item=item, transaction_type=InventoryTransaction.TransactionType.STOCK_IN, quantity=line.quantity, previous_stock=previous, new_stock=item.stock_quantity, reference=order.number, performed_by=request.user)
        order.status = PurchaseOrder.Status.RECEIVED
        order.save(update_fields=["status", "updated_at"])
        record_audit(request, "Purchase order received", "Inventory", order)
        return Response(self.get_serializer(order).data)


class ReturnRequestViewSet(SearchableModelViewSet):
    queryset = ReturnRequest.objects.select_related("invoice", "requested_by", "reviewed_by").prefetch_related("items__invoice_item__item")
    serializer_class = ReturnRequestSerializer
    search_fields = ["number", "invoice__number", "reason"]

    def perform_create(self, serializer):
        returned = serializer.save(requested_by=self.request.user)
        record_audit(self.request, "Return requested", "Returns", returned)

    @action(detail=True, methods=["post"])
    @transaction.atomic
    def decide(self, request, pk=None):
        returned = ReturnRequest.objects.select_for_update().get(pk=pk)
        decision = request.data.get("decision")
        if returned.status != ReturnRequest.Status.PENDING:
            return Response({"detail": "This return has already been decided."}, status=status.HTTP_400_BAD_REQUEST)
        if decision not in {ReturnRequest.Status.APPROVED, ReturnRequest.Status.REJECTED}:
            return Response({"decision": "Use 'approved' or 'rejected'."}, status=status.HTTP_400_BAD_REQUEST)
        if decision == ReturnRequest.Status.APPROVED:
            for line in returned.items.select_related("invoice_item__item"):
                item = Item.objects.select_for_update().get(pk=line.invoice_item.item_id)
                if item.item_type == Item.ItemType.SERVICE:
                    continue
                previous = item.stock_quantity
                item.stock_quantity += line.quantity
                item.save(update_fields=["stock_quantity", "updated_at"])
                InventoryTransaction.objects.create(item=item, transaction_type=InventoryTransaction.TransactionType.STOCK_IN, quantity=line.quantity, previous_stock=previous, new_stock=item.stock_quantity, reference=returned.number, notes="Approved customer return", performed_by=request.user)
        returned.status = decision
        returned.reviewed_by = request.user
        returned.reviewed_at = timezone.now()
        returned.save(update_fields=["status", "reviewed_by", "reviewed_at", "updated_at"])
        record_audit(request, f"Return {decision}", "Returns", returned)
        return Response(self.get_serializer(returned).data)


class StoreSettingsViewSet(SearchableModelViewSet):
    queryset = StoreSettings.objects.all().order_by("pk")
    serializer_class = StoreSettingsSerializer
    permission_classes = [permissions.IsAdminUser]

    def perform_update(self, serializer):
        settings = serializer.save()
        record_audit(self.request, "Store settings updated", "Settings", settings)


class AuditLogViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = AuditLog.objects.select_related("user").all()
    serializer_class = AuditLogSerializer
    permission_classes = [permissions.IsAdminUser]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ["user__username", "user__first_name", "action", "module", "ip_address"]
    ordering_fields = ["created_at", "module"]


@api_view(["GET"])
@permission_classes([permissions.IsAuthenticated])
def dashboard(request):
    today = timezone.localdate()
    yesterday = today - timedelta(days=1)
    range_start = today - timedelta(days=6)
    paid_today = Payment.objects.filter(
        status=Payment.Status.VERIFIED, verified_at__date=today
    ).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")
    paid_yesterday = Payment.objects.filter(
        status=Payment.Status.VERIFIED, verified_at__date=yesterday
    ).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")
    overdue = Invoice.objects.filter(status=Invoice.Status.OVERDUE)
    low_stock = Item.objects.filter(
        item_type=Item.ItemType.MATERIAL,
        stock_quantity__gt=0,
        stock_quantity__lte=models.F("reorder_level"),
    ).count()
    pending_orders = PurchaseOrder.objects.filter(status=PurchaseOrder.Status.PENDING).count()
    pending_discounts = DiscountApproval.objects.filter(status=DiscountApproval.Status.PENDING).count()
    bills_today = Invoice.objects.filter(invoice_date=today).count()
    bills_yesterday = Invoice.objects.filter(invoice_date=yesterday).count()
    average_bill = (
        Invoice.objects.filter(invoice_date=today).aggregate(total=Sum("total"))["total"]
        or Decimal("0.00")
    ) / max(bills_today, 1)
    approved_returns = ReturnRequest.objects.filter(status=ReturnRequest.Status.APPROVED)
    returns_total = approved_returns.aggregate(total=Sum("refund_amount"))["total"] or Decimal("0.00")
    sales_rows = {
        row["day"]: row["total"]
        for row in Payment.objects.filter(
            status=Payment.Status.VERIFIED,
            verified_at__date__range=(range_start, today),
        )
        .annotate(day=TruncDate("verified_at"))
        .values("day")
        .annotate(total=Sum("amount"))
    }
    sales_trend = [
        {
            "date": (range_start + timedelta(days=offset)).isoformat(),
            "total": sales_rows.get(range_start + timedelta(days=offset), Decimal("0.00")),
        }
        for offset in range(7)
    ]
    payment_rows = Payment.objects.filter(status=Payment.Status.VERIFIED).values("method").annotate(
        total=Sum("amount"), count=Count("id")
    )
    payment_breakdown = list(payment_rows)
    payment_totals = {row["method"]: row["total"] for row in Payment.objects.filter(status=Payment.Status.VERIFIED, verified_at__date=today).values("method").annotate(total=Sum("amount"))}
    out_of_stock = Item.objects.filter(item_type=Item.ItemType.MATERIAL, stock_quantity=0).count()
    expiring_soon = ProductBatch.objects.filter(expiry_date__range=(today, today + timedelta(days=30)), status="active").count()
    review_due = Item.objects.filter(Q(last_stock_review_date__isnull=True) | Q(last_stock_review_date__lte=today - timedelta(days=14))).count()
    old_shelf_stock = Item.objects.filter(shelf_stock__gt=0, shelf_added_date__lte=today - timedelta(days=90)).count()
    low_stock_products = list(
        Item.objects.filter(
            item_type=Item.ItemType.MATERIAL,
            stock_quantity__lte=models.F("reorder_level"),
        )
        .select_related("category")
        .values("id", "name", "sku", "stock_quantity", "reorder_level", "category__name")[:3]
    )
    top_products = list(
        InvoiceItem.objects.filter(
            invoice__invoice_date__range=(range_start, today),
            invoice__status__in=[Invoice.Status.PAID, Invoice.Status.PARTIAL],
        )
        .values("item_id", "name")
        .annotate(quantity=Sum("quantity"), revenue=Sum("amount"))
        .order_by("-quantity")[:5]
    )
    def profit_for(day):
        return sum(
            (
                (line.unit_price - line.item.purchase_price) * line.quantity
                for line in InvoiceItem.objects.select_related("item").filter(
                    invoice__invoice_date=day,
                    invoice__status__in=[Invoice.Status.PAID, Invoice.Status.PARTIAL],
                )
            ),
            Decimal("0.00"),
        )

    profit_today = profit_for(today)
    profit_yesterday = profit_for(yesterday)

    def growth(current, previous):
        if previous == 0:
            return Decimal("0.00") if current == 0 else Decimal("100.00")
        return (Decimal(current) - Decimal(previous)) * Decimal("100") / Decimal(previous)

    return Response({
        "today_sales": paid_today,
        "paid_today": paid_today,
        "total_bills": bills_today,
        "profit": profit_today,
        "average_bill_value": average_bill,
        "returns_total": returns_total,
        "sales_growth": growth(paid_today, paid_yesterday),
        "bills_growth": growth(bills_today, bills_yesterday),
        "profit_growth": growth(profit_today, profit_yesterday),
        "pending_purchase_orders": pending_orders,
        "pending_discount_approvals": pending_discounts,
        "outstanding_total": sum((invoice.balance_due for invoice in Invoice.objects.exclude(status=Invoice.Status.CANCELLED)), Decimal("0.00")),
        "overdue_invoice_count": overdue.count(),
        "low_stock_count": low_stock,
        "out_of_stock_count": out_of_stock,
        "expiring_soon_count": expiring_soon,
        "upi_collection": payment_totals.get(Payment.Method.UPI, Decimal("0.00")),
        "cash_collection": payment_totals.get(Payment.Method.CASH, Decimal("0.00")),
        "card_collection": payment_totals.get(Payment.Method.CARD, Decimal("0.00")),
        "total_collection": paid_today,
        "quantity_review_due_count": review_due,
        "shelf_stock_3_month_count": old_shelf_stock,
        "customer_count": Client.objects.filter(is_active=True).count(),
        "products_sold": InvoiceItem.objects.filter(
            invoice__invoice_date=today,
            invoice__status__in=[Invoice.Status.PAID, Invoice.Status.PARTIAL],
        ).aggregate(total=Sum("quantity"))["total"] or 0,
        "low_stock_products": low_stock_products,
        "top_products": top_products,
        "recent_invoices": InvoiceSerializer(Invoice.objects.select_related("client").order_by("-created_at")[:5], many=True).data,
        "sales_trend": sales_trend,
        "payment_breakdown": payment_breakdown,
        "range_start": range_start,
        "range_end": today,
    })
