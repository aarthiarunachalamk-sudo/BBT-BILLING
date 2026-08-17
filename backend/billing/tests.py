from datetime import timedelta
from decimal import Decimal

from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Category, Client, InventoryTransaction, Invoice, Item, Payment, User


class BillingWorkflowTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username="sales",
            email="sales@example.com",
            password="StrongPass123!",
            role=User.Role.ADMIN,
        )
        self.client.force_authenticate(self.user)
        self.category = Category.objects.create(name="Networking")
        self.material = Item.objects.create(
            item_type=Item.ItemType.MATERIAL,
            name="Router",
            sku="RTR-001",
            category=self.category,
            selling_price=Decimal("100.00"),
            purchase_price=Decimal("70.00"),
            stock_quantity=10,
        )
        self.customer = Client.objects.create(
            name="Test Customer",
            contact_person="Test Person",
            whatsapp_mobile="+919999999999",
            billing_address="Test address",
        )

    def test_complete_quote_invoice_payment_and_stock_flow(self):
        quote_response = self.client.post(
            reverse("quotation-list"),
            {
                "client": self.customer.pk,
                "discount_percent": "10.00",
                "items": [{"item": self.material.pk, "quantity": 2, "unit_price": "100.00"}],
            },
            format="json",
        )
        self.assertEqual(quote_response.status_code, status.HTTP_201_CREATED, quote_response.data)
        self.assertEqual(Decimal(quote_response.data["total"]), Decimal("212.40"))

        invoice_response = self.client.post(
            reverse("quotation-convert-to-invoice", args=[quote_response.data["id"]]),
            {"due_date": (timezone.localdate() + timedelta(days=15)).isoformat()},
            format="json",
        )
        self.assertEqual(invoice_response.status_code, status.HTTP_201_CREATED, invoice_response.data)

        payment_response = self.client.post(
            reverse("payment-list"),
            {
                "invoice": invoice_response.data["id"],
                "payment_type": Payment.PaymentType.FULL,
                "method": Payment.Method.UPI,
                "amount": "212.40",
                "transaction_reference": "TEST-UTR-1",
            },
            format="json",
        )
        self.assertEqual(payment_response.status_code, status.HTTP_201_CREATED, payment_response.data)

        verify_response = self.client.post(
            reverse("payment-verify", args=[payment_response.data["id"]]), {}, format="json"
        )
        self.assertEqual(verify_response.status_code, status.HTTP_200_OK, verify_response.data)

        self.material.refresh_from_db()
        invoice = Invoice.objects.get(pk=invoice_response.data["id"])
        self.assertEqual(self.material.stock_quantity, 8)
        self.assertEqual(invoice.status, Invoice.Status.PAID)
        self.assertEqual(InventoryTransaction.objects.count(), 1)

    def test_login_returns_jwt_tokens(self):
        self.client.force_authenticate(user=None)
        response = self.client.post(
            reverse("token_obtain_pair"),
            {"username": "sales", "password": "StrongPass123!"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertIn("refresh", response.data)
