from django.urls import reverse
from decimal import Decimal
from rest_framework import status
from rest_framework.test import APITestCase

from .models import (
    Category,
    Client,
    DiscountApproval,
    Item,
    PurchaseOrder,
    PurchaseOrderItem,
    Quotation,
    RolePermission,
    StoreSettings,
    Supplier,
    User,
)


class AdminLoginTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_superuser(
            username="aarthi",
            email="aarthi@gmail.com",
            password="Aarthi@123",
        )

    def test_admin_can_login_with_email(self):
        response = self.client.post(
            reverse("token_obtain_pair"),
            {"username": "aarthi@gmail.com", "password": "Aarthi@123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn("access", response.data)
        self.assertEqual(response.data["user"]["email"], "aarthi@gmail.com")

    def test_admin_can_login_with_username(self):
        response = self.client.post(
            reverse("token_obtain_pair"),
            {"username": "aarthi", "password": "Aarthi@123"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

    def test_admin_can_change_password_with_current_password(self):
        response = self.client.post(
            reverse("change-password"),
            {
                "identifier": "aarthi@gmail.com",
                "current_password": "Aarthi@123",
                "new_password": "NewAarthi@456",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("NewAarthi@456"))

    def test_change_password_rejects_wrong_current_password(self):
        response = self.client.post(
            reverse("change-password"),
            {
                "identifier": "aarthi",
                "current_password": "wrong-password",
                "new_password": "NewAarthi@456",
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password("Aarthi@123"))


class AdminFlowTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_superuser(
            username="aarthi",
            email="aarthi@gmail.com",
            password="Aarthi@123",
        )
        category = Category.objects.create(name="Test Category")
        supplier = Supplier.objects.create(name="Test Supplier")
        item = Item.objects.create(
            item_type=Item.ItemType.MATERIAL,
            name="Test Item",
            sku="TEST-ITEM",
            category=category,
            supplier=supplier,
            purchase_price=Decimal("10.00"),
            selling_price=Decimal("15.00"),
            stock_quantity=2,
            reorder_level=5,
        )
        customer = Client.objects.create(
            name="Test Customer",
            contact_person="Customer",
            whatsapp_mobile="9999999999",
            billing_address="Test address",
        )
        quotation = Quotation.objects.create(client=customer, created_by=self.user)
        DiscountApproval.objects.create(
            quotation=quotation,
            requested_percent=Decimal("5.00"),
            requested_by=self.user,
        )
        order = PurchaseOrder.objects.create(
            supplier=supplier,
            created_by=self.user,
        )
        PurchaseOrderItem.objects.create(
            purchase_order=order,
            item=item,
            quantity=3,
            unit_cost=Decimal("10.00"),
        )
        order.recalculate()
        StoreSettings.objects.create()
        RolePermission.objects.create(role="admin", settings=True)
        self.client.force_authenticate(self.user)

    def test_all_admin_screen_collections_are_available(self):
        endpoints = [
            "/api/dashboard/",
            "/api/users/",
            "/api/items/",
            "/api/categories/",
            "/api/suppliers/",
            "/api/purchase-orders/",
            "/api/discount-approvals/",
            "/api/invoices/",
            "/api/audit-logs/",
            "/api/role-permissions/",
            "/api/store-settings/",
        ]
        for endpoint in endpoints:
            with self.subTest(endpoint=endpoint):
                response = self.client.get(endpoint)
                self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)

    def test_admin_can_complete_connected_actions(self):
        order = PurchaseOrder.objects.get(status=PurchaseOrder.Status.PENDING)
        response = self.client.post(
            f"/api/purchase-orders/{order.pk}/decide/",
            {"decision": "approved"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)

        approval = DiscountApproval.objects.get(status=DiscountApproval.Status.PENDING)
        response = self.client.post(
            f"/api/discount-approvals/{approval.pk}/decide/",
            {"decision": "approved"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)

        settings = StoreSettings.objects.get(pk=1)
        response = self.client.patch(
            f"/api/store-settings/{settings.pk}/",
            {"invoice_prefix": "BILL-"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
