from decimal import Decimal

from django.contrib.auth import get_user_model
from django.utils import timezone
from rest_framework import serializers
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import (
    AuditLog,
    Brand,
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
    PurchaseOrderItem,
    Quotation,
    QuotationItem,
    Supplier,
    ReturnItem,
    ReturnRequest,
    RolePermission,
    StoreSettings,
    StockAdjustment,
    StockReview,
    WhatsAppMessage,
)


User = get_user_model()


class EmailTokenObtainPairSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        login = attrs.get(self.username_field, "")
        if "@" in login:
            user = User.objects.filter(email__iexact=login).first()
            if user:
                attrs[self.username_field] = user.username
        data = super().validate(attrs)
        user_data = UserSerializer(self.user).data
        data["user"] = user_data
        data["access_token"] = data["access"]
        data["refresh_token"] = data["refresh"]
        data.update({
            "user_id": self.user.pk,
            "employee_id": self.user.employee_id or self.user.username,
            "name": self.user.get_full_name() or self.user.username,
            "email": self.user.email,
            "role": self.user.role,
            "branch": self.user.branch,
        })
        return data


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = ["id", "username", "employee_id", "email", "first_name", "last_name", "role", "phone", "branch", "password", "is_active", "last_login", "last_logout"]
        read_only_fields = ["last_login", "last_logout"]

    def create(self, validated_data):
        password = validated_data.pop("password", None)
        user = User(**validated_data)
        if password:
            user.set_password(password)
        else:
            user.set_unusable_password()
        user.save()
        return user

    def update(self, instance, validated_data):
        password = validated_data.pop("password", None)
        instance = super().update(instance, validated_data)
        if password:
            instance.set_password(password)
            instance.save(update_fields=["password"])
        return instance


class ClientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Client
        fields = "__all__"


class CategorySerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(source="items.count", read_only=True)

    class Meta:
        model = Category
        fields = "__all__"
        extra_kwargs = {"name": {"validators": []}}

    def validate_name(self, value):
        name = value.strip()
        queryset = Category.objects.filter(name__iexact=name)
        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError("Category with this name already exists.")
        return name


class BrandSerializer(serializers.ModelSerializer):
    product_count = serializers.IntegerField(source="items.count", read_only=True)

    class Meta:
        model = Brand
        fields = "__all__"
        extra_kwargs = {"name": {"validators": []}}

    def validate_name(self, value):
        name = value.strip()
        queryset = Brand.objects.filter(name__iexact=name)
        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError("Brand with this name already exists.")
        return name


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = "__all__"


class ItemSerializer(serializers.ModelSerializer):
    stock_status = serializers.CharField(read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)
    supplier_name = serializers.CharField(source="supplier.name", read_only=True)
    brand_name = serializers.CharField(source="brand.name", read_only=True)
    total_stock = serializers.IntegerField(read_only=True)

    class Meta:
        model = Item
        fields = "__all__"
        extra_kwargs = {"sku": {"validators": []}}

    def validate_name(self, value):
        return value.strip()

    def validate_sku(self, value):
        sku = value.strip()
        queryset = Item.objects.filter(sku__iexact=sku)
        if self.instance:
            queryset = queryset.exclude(pk=self.instance.pk)
        if queryset.exists():
            raise serializers.ValidationError("A product with this SKU already exists.")
        return sku

    def validate(self, attrs):
        purchase_price = attrs.get(
            "purchase_price", getattr(self.instance, "purchase_price", 0)
        )
        selling_price = attrs.get(
            "selling_price", getattr(self.instance, "selling_price", 0)
        )
        stock = attrs.get(
            "stock_quantity", getattr(self.instance, "stock_quantity", 0)
        )
        reorder = attrs.get(
            "reorder_level", getattr(self.instance, "reorder_level", 0)
        )
        expiry = attrs.get(
            "expiry_date", getattr(self.instance, "expiry_date", None)
        )
        errors = {}
        if purchase_price < 0:
            errors["purchase_price"] = "Purchase price cannot be negative."
        if selling_price <= 0:
            errors["selling_price"] = "Selling price must be greater than zero."
        if stock < 0:
            errors["stock_quantity"] = "Opening stock cannot be negative."
        if reorder < 0:
            errors["reorder_level"] = "Minimum stock cannot be negative."
        if expiry and not self.instance and expiry < timezone.localdate():
            errors["expiry_date"] = "Expiry date cannot be in the past."
        if errors:
            raise serializers.ValidationError(errors)
        return attrs


class InventoryTransactionSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source="item.name", read_only=True)
    performed_by_name = serializers.CharField(source="performed_by.get_full_name", read_only=True)

    class Meta:
        model = InventoryTransaction
        fields = "__all__"
        read_only_fields = ["previous_stock", "new_stock", "performed_by"]


class ProductBatchSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="item.name", read_only=True)
    sku = serializers.CharField(source="item.sku", read_only=True)
    days_remaining = serializers.SerializerMethodField()

    class Meta:
        model = ProductBatch
        fields = "__all__"

    def get_days_remaining(self, obj):
        return (obj.expiry_date - timezone.localdate()).days


class StockReviewSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="item.name", read_only=True)
    sku = serializers.CharField(source="item.sku", read_only=True)
    reviewed_by_name = serializers.CharField(source="reviewed_by.get_full_name", read_only=True)

    class Meta:
        model = StockReview
        fields = "__all__"
        read_only_fields = ["system_quantity", "difference", "status", "reviewed_by", "reviewed_at", "next_review_date"]


class StockAdjustmentSerializer(serializers.ModelSerializer):
    product_name = serializers.CharField(source="item.name", read_only=True)
    adjusted_by_name = serializers.CharField(source="adjusted_by.get_full_name", read_only=True)

    class Meta:
        model = StockAdjustment
        fields = "__all__"
        read_only_fields = ["previous_quantity", "new_quantity", "difference", "adjusted_by"]


class QuotationItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = QuotationItem
        fields = ["id", "item", "name", "sku", "quantity", "unit_price", "amount"]
        read_only_fields = ["name", "sku", "amount"]


class QuotationSerializer(serializers.ModelSerializer):
    items = QuotationItemSerializer(many=True)
    client_name = serializers.CharField(source="client.name", read_only=True)
    created_by_name = serializers.CharField(source="created_by.get_full_name", read_only=True)

    class Meta:
        model = Quotation
        fields = "__all__"
        read_only_fields = [
            "number", "created_by", "subtotal", "discount_amount", "taxable_amount",
            "cgst_amount", "sgst_amount", "total", "status"
        ]

    def create(self, validated_data):
        lines = validated_data.pop("items")
        quotation = Quotation.objects.create(**validated_data)
        for line in lines:
            QuotationItem.objects.create(quotation=quotation, **line)
        quotation.recalculate()
        return quotation

    def update(self, instance, validated_data):
        lines = validated_data.pop("items", None)
        instance = super().update(instance, validated_data)
        if lines is not None:
            instance.items.all().delete()
            for line in lines:
                QuotationItem.objects.create(quotation=instance, **line)
        instance.recalculate()
        return instance


class DiscountApprovalSerializer(serializers.ModelSerializer):
    requested_by_name = serializers.CharField(source="requested_by.get_full_name", read_only=True)
    reviewed_by_name = serializers.CharField(source="reviewed_by.get_full_name", read_only=True)
    quotation_number = serializers.CharField(source="quotation.number", read_only=True)
    customer_name = serializers.CharField(source="quotation.client.name", read_only=True)
    bill_amount = serializers.DecimalField(source="quotation.total", max_digits=14, decimal_places=2, read_only=True)
    discount_amount = serializers.SerializerMethodField()

    class Meta:
        model = DiscountApproval
        fields = "__all__"
        read_only_fields = ["requested_by", "reviewed_by", "status", "decided_at"]

    def validate_requested_percent(self, value):
        if value <= 0 or value > Decimal("100"):
            raise serializers.ValidationError("Discount must be between 0 and 100 percent.")
        return value

    def get_discount_amount(self, obj):
        return obj.quotation.subtotal * obj.requested_percent / Decimal("100")


class InvoiceItemSerializer(serializers.ModelSerializer):
    item_type = serializers.CharField(source="item.item_type", read_only=True)

    class Meta:
        model = InvoiceItem
        fields = ["id", "item", "item_type", "name", "sku", "quantity", "unit_price", "amount"]
        read_only_fields = ["name", "sku", "amount"]


class InvoiceSerializer(serializers.ModelSerializer):
    items = InvoiceItemSerializer(many=True, read_only=True)
    client_name = serializers.CharField(source="client.name", read_only=True)
    client_mobile = serializers.CharField(source="client.whatsapp_mobile", read_only=True)
    paid_amount = serializers.DecimalField(max_digits=14, decimal_places=2, read_only=True)
    balance_due = serializers.DecimalField(max_digits=14, decimal_places=2, read_only=True)

    class Meta:
        model = Invoice
        fields = "__all__"
        read_only_fields = ["number", "created_by"]


class PaymentSerializer(serializers.ModelSerializer):
    invoice_number = serializers.CharField(source="invoice.number", read_only=True)
    collected_by_name = serializers.CharField(source="collected_by.get_full_name", read_only=True)

    class Meta:
        model = Payment
        fields = "__all__"
        read_only_fields = [
            "receipt_number", "status", "collected_by", "verified_by", "verified_at", "stock_processed"
        ]

    def validate(self, attrs):
        invoice = attrs.get("invoice")
        amount = attrs.get("amount")
        if invoice and amount and amount > invoice.balance_due:
            raise serializers.ValidationError({"amount": "Amount cannot exceed the invoice balance."})
        return attrs


class WhatsAppMessageSerializer(serializers.ModelSerializer):
    invoice_number = serializers.CharField(source="invoice.number", read_only=True)

    class Meta:
        model = WhatsAppMessage
        fields = "__all__"
        read_only_fields = ["sent_by", "status", "provider_message_id", "sent_at"]


class RolePermissionSerializer(serializers.ModelSerializer):
    class Meta:
        model = RolePermission
        fields = "__all__"


class PurchaseOrderItemSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source="item.name", read_only=True)

    class Meta:
        model = PurchaseOrderItem
        fields = "__all__"
        read_only_fields = ["purchase_order", "amount", "tax_amount"]


class PurchaseOrderSerializer(serializers.ModelSerializer):
    items = PurchaseOrderItemSerializer(many=True)
    supplier_name = serializers.CharField(source="supplier.name", read_only=True)
    created_by_name = serializers.CharField(source="created_by.get_full_name", read_only=True)
    reviewed_by_name = serializers.CharField(source="reviewed_by.get_full_name", read_only=True)

    class Meta:
        model = PurchaseOrder
        fields = "__all__"
        read_only_fields = ["number", "created_by", "reviewed_by", "reviewed_at", "subtotal", "tax_amount", "total"]

    def create(self, validated_data):
        items = validated_data.pop("items")
        order = PurchaseOrder.objects.create(**validated_data)
        for item in items:
            PurchaseOrderItem.objects.create(purchase_order=order, **item)
        order.recalculate()
        return order


class ReturnItemSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source="invoice_item.name", read_only=True)

    class Meta:
        model = ReturnItem
        fields = "__all__"
        read_only_fields = ["return_request", "amount"]


class ReturnRequestSerializer(serializers.ModelSerializer):
    items = ReturnItemSerializer(many=True)
    invoice_number = serializers.CharField(source="invoice.number", read_only=True)

    class Meta:
        model = ReturnRequest
        fields = "__all__"
        read_only_fields = ["number", "refund_amount", "status", "requested_by", "reviewed_by", "reviewed_at"]

    def create(self, validated_data):
        items = validated_data.pop("items")
        request = ReturnRequest.objects.create(refund_amount=Decimal("0.00"), **validated_data)
        total = Decimal("0.00")
        for item in items:
            invoice_item = item["invoice_item"]
            quantity = item["quantity"]
            if invoice_item.invoice_id != request.invoice_id:
                raise serializers.ValidationError({"items": "All items must belong to the selected invoice."})
            if quantity > invoice_item.quantity:
                raise serializers.ValidationError({"items": f"Return quantity exceeds {invoice_item.name} quantity."})
            amount = invoice_item.unit_price * quantity
            ReturnItem.objects.create(return_request=request, amount=amount, **item)
            total += amount
        request.refund_amount = total
        request.save(update_fields=["refund_amount", "updated_at"])
        return request


class StoreSettingsSerializer(serializers.ModelSerializer):
    class Meta:
        model = StoreSettings
        fields = "__all__"


class AuditLogSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source="user.get_full_name", read_only=True)
    employee_id = serializers.CharField(source="user.employee_id", read_only=True)

    class Meta:
        model = AuditLog
        fields = "__all__"
