from django.urls import reverse
from django.core.management import call_command
from rest_framework import status
from rest_framework.test import APITestCase

from .models import DiscountApproval, PurchaseOrder, StoreSettings, User


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


class AdminFlowTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_superuser(
            username="aarthi",
            email="aarthi@gmail.com",
            password="Aarthi@123",
        )
        call_command("seed_admin_flow", verbosity=0)
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
