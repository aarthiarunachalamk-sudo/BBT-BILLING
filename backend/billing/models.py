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
        ADMIN = "admin", "Admin"

    email = models.EmailField(unique=True)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.SALES)
    phone = models.CharField(max_length=20, blank=True)

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


class Item(TimeStampedModel):
    class ItemType(models.TextChoices):
        SERVICE = "service", "Service"
        MATERIAL = "material", "Material"

    item_type = models.CharField(max_length=10, choices=ItemType.choices)
    name = models.CharField(max_length=200)
    sku = models.CharField(max_length=50, unique=True)
    description = models.TextField(blank=True)
    category = models.ForeignKey(Category, on_delete=models.PROTECT, related_name="items")
    supplier = models.ForeignKey(
        Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name="items"
    )
    unit = models.CharField(max_length=30, default="unit")
    selling_price = models.DecimalField(**MONEY)
    purchase_price = models.DecimalField(**MONEY)
    tax_percent = models.DecimalField(
        max_digits=5, decimal_places=2, default=Decimal("18.00")
    )
    stock_quantity = models.IntegerField(default=0)
    reorder_level = models.PositiveIntegerField(default=5)
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

    def __str__(self):
        return f"{self.name} ({self.sku})"


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
