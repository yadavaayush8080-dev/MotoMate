from rest_framework.decorators import api_view
from rest_framework.response import Response

from .models import User
from .serializers import UserSerializer


@api_view(['GET'])
def users_test(request):
    return Response({
        "message": "Users API is working!",
        "status": "success"
    })


@api_view(['POST'])
def register_user(request):
    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():
        serializer.save()

        return Response({
            "message": "User registered successfully!",
            "user": serializer.data
        }, status=201)

    return Response(
        serializer.errors,
        status=400
    )


# ============================================================
# UPDATE USER PROFILE API
# ============================================================

@api_view(['PUT'])
def update_user_profile(request, user_id):

    # Check if user exists
    try:
        user = User.objects.get(id=user_id)

    except User.DoesNotExist:
        return Response({
            "message": "User not found!"
        }, status=404)

    # Get data from request
    name = request.data.get('name')
    email = request.data.get('email')
    phone = request.data.get('phone')

    # Check required fields
    if not name:
        return Response({
            "message": "Name is required!"
        }, status=400)

    if not email:
        return Response({
            "message": "Email is required!"
        }, status=400)

    if not phone:
        return Response({
            "message": "Phone is required!"
        }, status=400)

    # Check if another user already has this email
    if User.objects.filter(email=email).exclude(id=user_id).exists():
        return Response({
            "message": "Email is already registered!"
        }, status=400)

    # Check if another user already has this name
    if User.objects.filter(name=name).exclude(id=user_id).exists():
        return Response({
            "message": "Name is already taken!"
        }, status=400)

    # Update user
    user.name = name
    user.email = email
    user.phone = phone

    user.save()

    return Response({
        "message": "Profile updated successfully!",
        "user": {
            "id": user.id,
            "name": user.name,
            "email": user.email,
            "phone": user.phone,
            "role": user.role
        }
    }, status=200)