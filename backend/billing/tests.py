from datetime import timedelta
from decimal import Decimal
from io import StringIO
from tempfile import TemporaryDirectory

from django.core.management import call_command
from django.test import override_settings
from django.urls import reverse
from django.utils import timezone
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework.test import APIClient

from .models import (
    AuditLog,
    Category,
    Client,
    DiscountApproval,
    InventoryTransaction,
    Invoice,
    Item,
    Payment,
    PurchaseOrder,
    PurchaseOrderItem,
    ProductBatch,
    Quotation,
    RolePermission,
    StoreSettings,
    StockAdjustment,
    StockReview,
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

    def test_authenticated_logout_is_audited(self):
        self.client.force_authenticate(self.user)
        response = self.client.post(reverse("logout"), format="json")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertTrue(
            AuditLog.objects.filter(
                user=self.user,
                action="Logout",
                module="Auth",
            ).exists()
        )


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

    def test_weight_product_seed_creates_ten_products_and_is_idempotent(self):
        output = StringIO()
        with TemporaryDirectory() as media_root, override_settings(MEDIA_ROOT=media_root):
            call_command("seed_weight_products", stdout=output)
            call_command("seed_weight_products", stdout=output)

            products = Item.objects.filter(sku__startswith="WT-")
            self.assertEqual(products.count(), 10)
            self.assertTrue(all(product.unit in {"Gram", "Kg"} for product in products))
            self.assertTrue(all(product.manual_details.get("size") for product in products))
            self.assertTrue(all(bool(product.image) for product in products))

    def test_dashboard_values_are_calculated_from_database(self):
        response = self.client.get("/api/dashboard/")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertEqual(response.data["low_stock_count"], 1)
        self.assertEqual(response.data["pending_purchase_orders"], 1)
        self.assertEqual(response.data["pending_discount_approvals"], 1)
        self.assertIn("sales_growth", response.data)
        self.assertIn("bills_growth", response.data)
        self.assertIn("profit_growth", response.data)
        self.assertIn("sales_trend", response.data)
        self.assertIn("low_stock_products", response.data)
        self.assertIn("top_products", response.data)
        self.assertIn("payment_breakdown", response.data)
        self.assertIn("out_of_stock_count", response.data)
        self.assertIn("expiring_soon_count", response.data)
        self.assertIn("quantity_review_due_count", response.data)
        self.assertIn("shelf_stock_3_month_count", response.data)

    def test_physical_review_creates_auditable_stock_adjustment(self):
        product = Item.objects.get(sku="TEST-ITEM")
        product.store_stock = 2
        product.save(update_fields=["store_stock"])
        response = self.client.post(
            "/api/inventory/quantity-reviews/",
            {"item": product.pk, "physical_quantity": 5, "reason": "Cycle count"},
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        product.refresh_from_db()
        self.assertEqual(product.stock_quantity, 5)
        adjustment = StockAdjustment.objects.get(item=product)
        self.assertEqual(adjustment.previous_quantity, 2)
        self.assertEqual(adjustment.difference, 3)
        self.assertEqual(StockReview.objects.filter(item=product).count(), 1)

    def test_expiry_filter_returns_matching_batches(self):
        product = Item.objects.get(sku="TEST-ITEM")
        ProductBatch.objects.create(
            item=product,
            batch_number="EXP-7",
            quantity=2,
            expiry_date=timezone.localdate() + timedelta(days=5),
        )
        response = self.client.get("/api/inventory/batches/?range=7")
        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        self.assertEqual(len(response.data["results"]), 1)

    def test_product_creation_records_opening_inventory(self):
        category = Category.objects.get(name="Test Category")
        response = self.client.post(
            "/api/items/",
            {
                "item_type": "material",
                "name": "Turmeric Powder",
                "sku": "TURMERIC-001",
                "category": category.pk,
                "manual_details": {
                    "brand": "Sample Brand",
                    "net_weight": "250 g",
                },
                "unit": "Pack",
                "purchase_price": "40.00",
                "selling_price": "55.00",
                "tax_percent": "5.00",
                "stock_quantity": 20,
                "reorder_level": 5,
                "is_active": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        product = Item.objects.get(sku="TURMERIC-001")
        self.assertEqual(product.manual_details["net_weight"], "250 g")
        opening = InventoryTransaction.objects.get(item=product)
        self.assertEqual(opening.quantity, 20)
        self.assertEqual(opening.previous_stock, 0)
        self.assertEqual(opening.new_stock, 20)


class StaffAdminIntegrationTests(APITestCase):
    """Critical shared-database flow exercised without production test data."""

    def setUp(self):
        # Preserve the shared fixture used by the remaining Admin flow tests.
        AdminFlowTests.setUp(self)
        self.admin = self.user
        self.admin.role = User.Role.ADMIN
        self.admin.save(update_fields=["role"])
        self.category = Category.objects.create(name="Integration Beverages")
        self.admin_client = APIClient()
        self.admin_client.force_authenticate(self.admin)

    def test_complete_staff_to_admin_and_admin_to_staff_flow(self):
        create_user = self.admin_client.post(
            "/api/admin/users/",
            {
                "username": "emp200",
                "employee_id": "EMP200",
                "email": "emp200@example.com",
                "first_name": "Integration",
                "last_name": "Staff",
                "role": User.Role.INVENTORY,
                "branch": "Main Branch",
                "password": "StaffTest@123",
                "is_active": True,
            },
            format="json",
        )
        self.assertEqual(create_user.status_code, status.HTTP_201_CREATED, create_user.data)
        staff_id = create_user.data["id"]

        staff_client = APIClient()
        login = staff_client.post(
            "/api/auth/login/",
            {"username": "EMP200", "password": "StaffTest@123"},
            format="json",
        )
        self.assertEqual(login.status_code, status.HTTP_200_OK, login.data)
        staff_client.credentials(HTTP_AUTHORIZATION=f"Bearer {login.data['access']}")

        created = staff_client.post(
            "/api/products/",
            {
                "item_type": "material",
                "name": "Integration Test Juice",
                "sku": "INT-JUICE-001",
                "barcode": "990000000001",
                "category": self.category.pk,
                "unit": "Bottle",
                "purchase_price": "70.00",
                "selling_price": "100.00",
                "tax_percent": "5.00",
                "store_stock": 50,
                "shelf_stock": 10,
                "stock_quantity": 60,
                "reorder_level": 10,
                "batch_number": "TESTB001",
                "expiry_date": (timezone.localdate() + timedelta(days=60)).isoformat(),
                "is_active": True,
            },
            format="json",
        )
        self.assertEqual(created.status_code, status.HTTP_201_CREATED, created.data)
        product_id = created.data["id"]
        self.assertTrue(ProductBatch.objects.filter(item_id=product_id, batch_number="TESTB001").exists())
        self.assertTrue(InventoryTransaction.objects.filter(item_id=product_id, new_stock=60).exists())

        admin_products = self.admin_client.get("/api/products/?search=INT-JUICE-001")
        self.assertEqual(admin_products.status_code, status.HTTP_200_OK)
        self.assertEqual(admin_products.data["results"][0]["total_stock"], 60)

        moved = staff_client.post(
            f"/api/items/{product_id}/move-to-shelf/",
            {"quantity": 5},
            format="json",
        )
        self.assertEqual(moved.status_code, status.HTTP_200_OK, moved.data)
        product = Item.objects.get(pk=product_id)
        self.assertEqual((product.store_stock, product.shelf_stock, product.total_stock), (45, 15, 60))

        reviewed = staff_client.post(
            "/api/inventory/quantity-reviews/",
            {"item": product_id, "physical_quantity": 58, "reason": "Integration count"},
            format="json",
        )
        self.assertEqual(reviewed.status_code, status.HTTP_201_CREATED, reviewed.data)
        product.refresh_from_db()
        self.assertEqual(product.total_stock, 58)

        price_update = self.admin_client.patch(
            f"/api/products/{product_id}/",
            {"selling_price": "110.00"},
            format="json",
        )
        self.assertEqual(price_update.status_code, status.HTTP_200_OK, price_update.data)
        staff_product = staff_client.get(f"/api/products/{product_id}/")
        self.assertEqual(staff_product.data["selling_price"], "110.00")

        checkout_response = staff_client.post(
            "/api/billing/checkout/",
            {
                "items": [{"item": product_id, "quantity": 2}],
                "payments": [{"method": "upi", "amount": "231.00"}],
            },
            format="json",
        )
        self.assertEqual(checkout_response.status_code, status.HTTP_201_CREATED, checkout_response.data)
        product.refresh_from_db()
        self.assertEqual(product.total_stock, 56)
        invoice_id = checkout_response.data["id"]
        self.assertTrue(Payment.objects.filter(invoice_id=invoice_id, method=Payment.Method.UPI, status=Payment.Status.VERIFIED).exists())

        dashboard_response = self.admin_client.get("/api/dashboard/")
        self.assertEqual(dashboard_response.data["total_bills"], 1)
        self.assertEqual(Decimal(dashboard_response.data["today_sales"]), Decimal("231.00"))
        summary = self.admin_client.get(f"/api/users/{staff_id}/summary/")
        self.assertEqual(summary.data["today_bills"], 1)
        self.assertEqual(Decimal(summary.data["upi_collection"]), Decimal("231.00"))
        self.assertTrue(AuditLog.objects.filter(user_id=staff_id, action="New Bill Created").exists())
        self.assertTrue(AuditLog.objects.filter(user_id=staff_id, action="Payment Received").exists())

        logout = staff_client.post("/api/auth/logout/", {}, format="json")
        self.assertEqual(logout.status_code, status.HTTP_200_OK)
        self.assertTrue(AuditLog.objects.filter(user_id=staff_id, action="Logout").exists())

        deactivated = self.admin_client.patch(
            f"/api/admin/users/{staff_id}/",
            {"is_active": False},
            format="json",
        )
        self.assertEqual(deactivated.status_code, status.HTTP_200_OK)
        blocked_login = APIClient().post(
            "/api/auth/login/",
            {"username": "EMP200", "password": "StaffTest@123"},
            format="json",
        )
        self.assertEqual(blocked_login.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_product_creation_rejects_duplicate_sku_ignoring_case(self):
        existing = Item.objects.get(sku="TEST-ITEM")
        response = self.client.post(
            "/api/items/",
            {
                "item_type": "material",
                "name": "Duplicate",
                "sku": existing.sku.lower(),
                "category": existing.category_id,
                "unit": "Pack",
                "purchase_price": "10.00",
                "selling_price": "15.00",
                "tax_percent": "5.00",
                "stock_quantity": 1,
                "reorder_level": 1,
                "is_active": True,
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("sku", response.data)

    def test_products_can_be_filtered_by_category(self):
        category = Category.objects.get(name="Test Category")
        response = self.client.get(f"/api/items/?category={category.pk}")

        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        products = response.data["results"]
        self.assertEqual(len(products), 1)
        self.assertEqual(products[0]["category_name"], "Test Category")

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

    def test_checkout_recalculates_totals_and_deducts_stock_atomically(self):
        product = Item.objects.get(sku="TEST-ITEM")
        product.store_stock = 2
        product.save(update_fields=["store_stock"])

        response = self.client.post(
            "/api/billing/checkout/",
            {
                "items": [{"product": product.pk, "quantity": 2, "price": "0.01"}],
                "discount_percent": "0",
                "payments": [{"method": "cash", "amount": "35.40", "cash_received": "40.00"}],
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        invoice = Invoice.objects.get(pk=response.data["id"])
        self.assertEqual(invoice.subtotal, Decimal("30.00"))
        self.assertEqual(invoice.total, Decimal("35.40"))
        product.refresh_from_db()
        self.assertEqual(product.stock_quantity, 0)
        self.assertTrue(Payment.objects.filter(invoice=invoice, status="verified").exists())
        movement = InventoryTransaction.objects.filter(item=product, transaction_type="sale").get()
        self.assertEqual(movement.quantity, -2)

    def test_checkout_rejects_payment_mismatch_without_writes(self):
        product = Item.objects.get(sku="TEST-ITEM")
        before = product.stock_quantity
        response = self.client.post(
            "/api/billing/checkout/",
            {
                "items": [{"product": product.pk, "quantity": 1}],
                "payments": [{"method": "upi", "amount": "1.00"}],
            },
            format="json",
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST, response.data)
        product.refresh_from_db()
        self.assertEqual(product.stock_quantity, before)
        self.assertEqual(Invoice.objects.count(), 0)
