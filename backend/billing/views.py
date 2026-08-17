from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import models, transaction
from django.db.models import Sum
from django.utils import timezone
from rest_framework import filters, permissions, status, viewsets
from rest_framework.decorators import action, api_view, permission_classes
from rest_framework.response import Response

from .models import (
    Category,
    Client,
    DiscountApproval,
    InventoryTransaction,
    Invoice,
    InvoiceItem,
    Item,
    Payment,
    Quotation,
    Supplier,
    WhatsAppMessage,
)
from .serializers import (
    CategorySerializer,
    ClientSerializer,
    DiscountApprovalSerializer,
    InventoryTransactionSerializer,
    InvoiceSerializer,
    ItemSerializer,
    PaymentSerializer,
    QuotationSerializer,
    SupplierSerializer,
    UserSerializer,
    WhatsAppMessageSerializer,
)


User = get_user_model()


class SearchableModelViewSet(viewsets.ModelViewSet):
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]


class UserViewSet(SearchableModelViewSet):
    queryset = User.objects.all().order_by("first_name", "username")
    serializer_class = UserSerializer
    permission_classes = [permissions.IsAdminUser]
    search_fields = ["username", "email", "first_name", "last_name"]
    ordering_fields = ["username", "first_name", "date_joined"]


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

    def get_queryset(self):
        queryset = super().get_queryset()
        item_type = self.request.query_params.get("type")
        active = self.request.query_params.get("active")
        if item_type:
            queryset = queryset.filter(item_type=item_type)
        if active in {"true", "false"}:
            queryset = queryset.filter(is_active=active == "true")
        return queryset

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

        previous = item.stock_quantity
        item.stock_quantity += quantity
        item.save(update_fields=["stock_quantity", "updated_at"])
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
        serializer.save(sent_by=self.request.user)


@api_view(["GET"])
@permission_classes([permissions.IsAuthenticated])
def dashboard(request):
    today = timezone.localdate()
    paid_today = Payment.objects.filter(
        status=Payment.Status.VERIFIED, verified_at__date=today
    ).aggregate(total=Sum("amount"))["total"] or Decimal("0.00")
    overdue = Invoice.objects.filter(status=Invoice.Status.OVERDUE)
    low_stock = Item.objects.filter(
        item_type=Item.ItemType.MATERIAL,
        stock_quantity__gt=0,
        stock_quantity__lte=models.F("reorder_level"),
    ).count()
    return Response({
        "paid_today": paid_today,
        "outstanding_total": sum((invoice.balance_due for invoice in Invoice.objects.exclude(status=Invoice.Status.CANCELLED)), Decimal("0.00")),
        "overdue_invoice_count": overdue.count(),
        "low_stock_count": low_stock,
        "recent_invoices": InvoiceSerializer(Invoice.objects.select_related("client").order_by("-created_at")[:5], many=True).data,
    })
