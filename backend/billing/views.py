from rest_framework_simplejwt.views import TokenObtainPairView

from .serializers import EmailTokenObtainPairSerializer


class AdminTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailTokenObtainPairSerializer
