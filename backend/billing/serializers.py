from decimal import Decimal

from django.contrib.auth import get_user_model
from rest_framework import serializers

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
    QuotationItem,
    Supplier,
    WhatsAppMessage,
)


User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=False)

    class Meta:
        model = User
        fields = ["id", "username", "email", "first_name", "last_name", "role", "phone", "password", "is_active"]

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
    class Meta:
        model = Category
        fields = "__all__"


class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = "__all__"


class ItemSerializer(serializers.ModelSerializer):
    stock_status = serializers.CharField(read_only=True)
    category_name = serializers.CharField(source="category.name", read_only=True)
    supplier_name = serializers.CharField(source="supplier.name", read_only=True)

    class Meta:
        model = Item
        fields = "__all__"


class InventoryTransactionSerializer(serializers.ModelSerializer):
    item_name = serializers.CharField(source="item.name", read_only=True)
    performed_by_name = serializers.CharField(source="performed_by.get_full_name", read_only=True)

    class Meta:
        model = InventoryTransaction
        fields = "__all__"
        read_only_fields = ["previous_stock", "new_stock", "performed_by"]


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

    class Meta:
        model = DiscountApproval
        fields = "__all__"
        read_only_fields = ["requested_by", "reviewed_by", "status", "decided_at"]

    def validate_requested_percent(self, value):
        if value <= 0 or value > Decimal("100"):
            raise serializers.ValidationError("Discount must be between 0 and 100 percent.")
        return value


class InvoiceItemSerializer(serializers.ModelSerializer):
    item_type = serializers.CharField(source="item.item_type", read_only=True)

    class Meta:
        model = InvoiceItem
        fields = ["id", "item", "item_type", "name", "sku", "quantity", "unit_price", "amount"]
        read_only_fields = ["name", "sku", "amount"]


class InvoiceSerializer(serializers.ModelSerializer):
    items = InvoiceItemSerializer(many=True, read_only=True)
    client_name = serializers.CharField(source="client.name", read_only=True)
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
