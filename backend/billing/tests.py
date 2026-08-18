from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import User


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
