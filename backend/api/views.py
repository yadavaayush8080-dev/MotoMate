from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from datetime import date
from openai import OpenAI
from django.contrib.auth.hashers import check_password
from math import radians, sin, cos, sqrt, atan2
from .models import Vehicle, EmergencyRequest, Mechanic, ServiceRequest, Notification,MechanicNotification

from users.models import User

from .models import Vehicle, EmergencyRequest, Mechanic
from .serializers import VehicleSerializer,NotificationSerializer
from django.db.models import Q

def calculate_distance(lat1, lon1, lat2, lon2):
    R = 6371  # Earth radius in kilometers

    lat1 = radians(float(lat1))
    lon1 = radians(float(lon1)) 
    lat2 = radians(float(lat2))
    lon2 = radians(float(lon2))

    dlat = lat2 - lat1
    dlon = lon2 - lon1

    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ** 2
    c = 2 * atan2(sqrt(a), sqrt(1 - a))

    return R * c


# ============================================================
# GET USER VEHICLE API
# ============================================================

@api_view(['GET'])
def get_user_vehicle(request, user_id):

    try:
        user = User.objects.get(id=user_id)

    except User.DoesNotExist:
        return Response(
            {
                "message": "User not found!"
            },
            status=status.HTTP_404_NOT_FOUND
        )

    vehicles = Vehicle.objects.filter(user=user)

    serializer = VehicleSerializer(
        vehicles,
        many=True
    )

    return Response(
        {
            "message": "Vehicles fetched successfully!",
            "vehicles": serializer.data
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# LOGIN API
# ============================================================

@api_view(['POST'])
def login_api(request):

    email = request.data.get('email')
    password = request.data.get('password')

    # Check if email and password are provided

    if not email or not password:
        return Response(
            {
                "message": "Email and password are required!"
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    # Find user by email

    try:
        user = User.objects.get(email=email)

    except User.DoesNotExist:
        return Response(
            {
                "message": "Invalid email or password!"
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Check hashed password

    if not check_password(password, user.password):
        return Response(
            {
                "message": "Invalid email or password!"
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Login successful

    return Response(
        {
            "message": "Login successful!",
            "user": {
                "id": user.id,
                "name": user.name,
                "email": user.email,
                "phone": user.phone,
                "role": user.role
            }
        },
        status=status.HTTP_200_OK
    )


# ============================================================
# VEHICLE API
# ============================================================

@api_view(['POST'])
def add_vehicle(request):

    user_id = request.data.get('user_id')

    # Check if user ID is provided
    if not user_id:
        return Response(
            {
                "message": "User ID is required!"
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    # Check if user exists
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {
                "message": "User not found!"
            },
            status=status.HTTP_404_NOT_FOUND
        )

    # Create vehicle data
    vehicle_data = request.data.copy()
    vehicle_data['user'] = user.id

    serializer = VehicleSerializer(
        data=vehicle_data
    )

    if serializer.is_valid():
        vehicle = serializer.save()

        return Response(
            {
                "message": "Vehicle saved successfully!",
                "vehicle": VehicleSerializer(vehicle).data
            },
            status=status.HTTP_201_CREATED
        )

    return Response(
        serializer.errors,
        status=status.HTTP_400_BAD_REQUEST
    )

@api_view(['PUT'])
def update_vehicle(request, vehicle_id):

    # Find vehicle

    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)

    except Vehicle.DoesNotExist:
        return Response(
            {
                "message": "Vehicle not found!"
            },
            status=status.HTTP_404_NOT_FOUND
        )

    # Update vehicle

    serializer = VehicleSerializer(
        vehicle,
        data=request.data,
        partial=True
    )

    if serializer.is_valid():

        vehicle = serializer.save()

        return Response(
            {
                "message": "Vehicle updated successfully!",
                "vehicle": VehicleSerializer(vehicle).data
            },
            status=status.HTTP_200_OK
        )

    return Response(
        serializer.errors,
        status=status.HTTP_400_BAD_REQUEST
    )


# ============================================================
# EMERGENCY REPAIR API
# ============================================================

@api_view(['POST'])
def create_emergency_request(request):

    user_id = request.data.get('user_id')
    vehicle_id = request.data.get('vehicle_id')
    latitude = request.data.get('latitude')
    longitude = request.data.get('longitude')
    problem_description = request.data.get('problem_description')

    if not user_id:
        return Response({"message": "User ID is required!"}, status=400)

    if not vehicle_id:
        return Response({"message": "Vehicle ID is required!"}, status=400)

    if latitude is None:
        return Response({"message": "Latitude is required!"}, status=400)

    if longitude is None:
        return Response({"message": "Longitude is required!"}, status=400)

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response({"message": "User not found!"}, status=404)

    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)
    except Vehicle.DoesNotExist:
        return Response({"message": "Vehicle not found!"}, status=404)

    # Get available mechanics
    mechanics = Mechanic.objects.filter(is_available=True)

    if not mechanics.exists():
        return Response(
            {"message": "No mechanics are currently available!"},
            status=404
        )

    # Find nearest mechanic
    nearest_mechanic = None
    shortest_distance = None

    for mechanic in mechanics:

        if mechanic.latitude is None or mechanic.longitude is None:
            continue

        distance = calculate_distance(
            latitude,
            longitude,
            mechanic.latitude,
            mechanic.longitude
        )

        if shortest_distance is None or distance < shortest_distance:
            shortest_distance = distance
            nearest_mechanic = mechanic

    if nearest_mechanic is None:
        return Response(
            {"message": "No mechanic with valid location found!"},
            status=404
        )

    # Create emergency request with assigned mechanic
    emergency_request = EmergencyRequest.objects.create(
        user=user,
        vehicle=vehicle,
        mechanic=nearest_mechanic,
        latitude=latitude,
        longitude=longitude,
        problem_description=problem_description,
        status='assigned'
        
    
    )
    
    print("DEBUG: Creating mechanic notification...")

    mechanic_notification = MechanicNotification.objects.create(
    mechanic=nearest_mechanic,
    request_id=emergency_request.id,
    title='New Emergency Repair Request',
    message=f'New emergency repair request from {user.name}.',
    notification_type='emergency_request',
    is_read=False
    )

    print("DEBUG: Mechanic notification created:", mechanic_notification.id)

    return Response({
        "message": "Emergency request created and mechanic assigned successfully!",
        "emergency_request": {
            "id": emergency_request.id,
            "user_id": emergency_request.user_id,
            "vehicle_id": emergency_request.vehicle_id,
            "mechanic_id": emergency_request.mechanic_id,
            "latitude": str(emergency_request.latitude),
            "longitude": str(emergency_request.longitude),
            "problem_description": emergency_request.problem_description,
            "status": emergency_request.status,
            "mechanic": {
                "id": nearest_mechanic.id,
                "name": nearest_mechanic.name,
                "shop_name": nearest_mechanic.shop_name,
                "phone": nearest_mechanic.phone,
                "address": nearest_mechanic.address,
                "rating": str(nearest_mechanic.rating),
                "distance_km": round(shortest_distance, 2)
            },
            "created_at": emergency_request.created_at
        }
    }, status=201)
    
@api_view(['GET'])
def get_emergency_request(request, request_id):

    try:
        emergency_request = EmergencyRequest.objects.select_related(
            'mechanic',
            'vehicle',
            'user'
        ).get(id=request_id)

    except EmergencyRequest.DoesNotExist:
        return Response(
            {"message": "Emergency request not found!"},
            status=404
        )

    mechanic = emergency_request.mechanic

    return Response({
        "message": "Emergency request fetched successfully!",
        "emergency_request": {
            "id": emergency_request.id,
            "user_id": emergency_request.user_id,
            "vehicle_id": emergency_request.vehicle_id,
            "mechanic_id": emergency_request.mechanic_id,
            "latitude": str(emergency_request.latitude),
            "longitude": str(emergency_request.longitude),
            "problem_description": emergency_request.problem_description,
            "status": emergency_request.status,

            "mechanic": {
                "id": mechanic.id,
                "name": mechanic.name,
                "shop_name": mechanic.shop_name,
                "phone": mechanic.phone,
                "address": mechanic.address,
                "rating": str(mechanic.rating)
            } if mechanic else None,

            "created_at": emergency_request.created_at
        }
    }, status=200)
    
@api_view(['POST'])
def create_service_request(request):

    user_id = request.data.get('user_id')
    vehicle_id = request.data.get('vehicle_id')
    service_type = request.data.get('service_type')
    preferred_date = request.data.get('preferred_date')
    preferred_time = request.data.get('preferred_time')
    address = request.data.get('address')
    notes = request.data.get('notes')

    # Validate required fields
    if not user_id:
        return Response(
            {"message": "User ID is required!"},
            status=400
        )

    if not vehicle_id:
        return Response(
            {"message": "Vehicle ID is required!"},
            status=400
        )

    if not service_type:
        return Response(
            {"message": "Service type is required!"},
            status=400
        )

    # Check user
    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {"message": "User not found!"},
            status=404
        )

    # Check vehicle
    try:
        vehicle = Vehicle.objects.get(id=vehicle_id)
    except Vehicle.DoesNotExist:
        return Response(
            {"message": "Vehicle not found!"},
            status=404
        )

    # Create service request
    service_request = ServiceRequest.objects.create(
        user=user,
        vehicle=vehicle,
        service_type=service_type,
        preferred_date=preferred_date,
        preferred_time=preferred_time,
        address=address,
        status='booked',
        notes=notes
    )

    # Create notification automatically
    notification = Notification.objects.create(
        user=user,
        vehicle=vehicle,
        title='Home Service Booked',
        message=f'Your {service_type} has been successfully booked.',
        notification_type='service_booking',
        is_read=False
    )

    return Response({
        "message": "Home service booked successfully!",
        "service_request": {
            "id": service_request.id,
            "user_id": service_request.user_id,
            "vehicle_id": service_request.vehicle_id,
            "service_type": service_request.service_type,
            "preferred_date": str(service_request.preferred_date)
                if service_request.preferred_date else None,
            "preferred_time": str(service_request.preferred_time)
                if service_request.preferred_time else None,
            "address": service_request.address,
            "status": service_request.status,
            "notes": service_request.notes,
            "created_at": service_request.created_at
        },
        "notification": {
            "id": notification.id,
            "title": notification.title,
            "message": notification.message,
            "notification_type": notification.notification_type,
            "is_read": notification.is_read,
            "created_at": notification.created_at
        }
    }, status=201)
    
@api_view(['GET'])
def get_user_notifications(request, user_id):

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {"message": "User not found!"},
            status=404
        )

    notifications = Notification.objects.filter(
        user=user
    ).order_by('-created_at')

    serializer = NotificationSerializer(
        notifications,
        many=True
    )

    return Response({
        "message": "Notifications fetched successfully!",
        "notifications": serializer.data
    }, status=200)    
    
# ==============================
# VEHICLE HEALTH API
# ==============================

@api_view(['GET'])
def get_vehicle_health(request, user_id):

    try:
        user = User.objects.get(id=user_id)
    except User.DoesNotExist:
        return Response(
            {"message": "User not found!"},
            status=404
        )

    vehicle = Vehicle.objects.filter(
        user=user
    ).order_by('-created_at').first()

    if vehicle is None:
        return Response(
            {"message": "Vehicle not found!"},
            status=404
        )

    today = date.today()

    # --------------------------------
    # 1. Insurance Score - 20 points
    # --------------------------------
    insurance_score = 20

    if vehicle.insurance_expiry:
        if vehicle.insurance_expiry < today:
            insurance_score = 0
        elif (vehicle.insurance_expiry - today).days <= 30:
            insurance_score = 10

    # --------------------------------
    # 2. PUC Score - 20 points
    # --------------------------------
    puc_score = 20

    if vehicle.puc_expiry:
        if vehicle.puc_expiry < today:
            puc_score = 0
        elif (vehicle.puc_expiry - today).days <= 30:
            puc_score = 10

    # --------------------------------
    # 3. Service Score - 30 points
    # --------------------------------
    service_score = 30

    if vehicle.last_service_date:
        days_since_service = (
            today - vehicle.last_service_date
        ).days

        if days_since_service > 180:
            service_score = 0
        elif days_since_service > 120:
            service_score = 10
        elif days_since_service > 90:
            service_score = 20

    # --------------------------------
    # 4. Kilometres Score - 10 points
    # --------------------------------
    kilometer_score = 10

    if vehicle.current_kilometers:
        if vehicle.current_kilometers >= 200000:
            kilometer_score = 4
        elif vehicle.current_kilometers >= 150000:
            kilometer_score = 6
        elif vehicle.current_kilometers >= 100000:
            kilometer_score = 8

    # --------------------------------
    # Overall Health Score
    # --------------------------------
    health_score = (
        insurance_score
        + puc_score
        + service_score
        + kilometer_score
    )

    # --------------------------------
    # Health Status
    # --------------------------------
    if health_score >= 80:
        health_status = "Good"
        health_message = "Your vehicle is in good condition."
    elif health_score >= 60:
        health_status = "Fair"
        health_message = "Your vehicle needs some attention."
    else:
        health_status = "Needs Attention"
        health_message = (
            "Your vehicle requires maintenance attention."
        )

    # --------------------------------
    # Component Scores
    # --------------------------------
    engine_score = service_score + kilometer_score

    if engine_score > 100:
        engine_score = 100

    battery_score = service_score

    if battery_score > 100:
        battery_score = 100

    brakes_score = service_score

    if brakes_score > 100:
        brakes_score = 100

    tyres_score = kilometer_score * 10

    if tyres_score > 100:
        tyres_score = 100

    engine_oil_score = service_score

    if engine_oil_score > 100:
        engine_oil_score = 100

    return Response({
        "message": "Vehicle health calculated successfully!",

        "vehicle": {
            "id": vehicle.id,
            "brand": vehicle.brand,
            "model": vehicle.model,
            "registration_number": vehicle.registration_number,
        },

        "health": {
            "score": health_score,
            "status": health_status,
            "message": health_message,
        },

        "components": {
            "engine": {
                "score": engine_score,
                "status": (
                    "Good"
                    if engine_score >= 70
                    else "Needs Attention"
                ),
            },

            "battery": {
                "score": battery_score,
                "status": (
                    "Good"
                    if battery_score >= 70
                    else "Needs Attention"
                ),
            },

            "brakes": {
                "score": brakes_score,
                "status": (
                    "Good"
                    if brakes_score >= 70
                    else "Needs Attention"
                ),
            },

            "tyres": {
                "score": tyres_score,
                "status": (
                    "Good"
                    if tyres_score >= 70
                    else "Needs Attention"
                ),
            },

            "engine_oil": {
                "score": engine_oil_score,
                "status": (
                    "Good"
                    if engine_oil_score >= 70
                    else "Needs Attention"
                ),
            },
        },

        "factors": {
            "insurance_score": insurance_score,
            "puc_score": puc_score,
            "service_score": service_score,
            "kilometer_score": kilometer_score,
        }

    }, status=200)

@api_view(['POST'])
def ai_assistant(request):

    user_id = request.data.get('user_id')
    message = request.data.get('message')

    # -----------------------------
    # Validate input
    # -----------------------------
    if not user_id:
        return Response(
            {"message": "User ID is required."},
            status=400
        )

    if not message or not str(message).strip():
        return Response(
            {"message": "Message is required."},
            status=400
        )

    # -----------------------------
    # Get user
    # -----------------------------
    try:
        user = User.objects.get(id=user_id)

    except User.DoesNotExist:
        return Response(
            {"message": "User not found."},
            status=404
        )

    # -----------------------------
    # Get latest vehicle
    # -----------------------------
    vehicle = Vehicle.objects.filter(
        user=user
    ).order_by('-created_at').first()

    # -----------------------------
    # Vehicle information
    # -----------------------------
    vehicle_data = None

    if vehicle:
        vehicle_data = {
            "id": vehicle.id,
            "brand": vehicle.brand,
            "model": vehicle.model,
            "registration_number": vehicle.registration_number,
            "fuel_type": vehicle.fuel_type,
            "vehicle_year": vehicle.vehicle_year,
            "current_kilometers": vehicle.current_kilometers,
            "last_service_date": str(vehicle.last_service_date)
            if vehicle.last_service_date else None,
        }

    # -----------------------------
    # Prepare question
    # -----------------------------
    question = str(message).strip()
    q = question.lower()

    # -----------------------------
    # Rule-based MotoMate AI
    # -----------------------------

    # OVERHEATING
    if any(word in q for word in [
        "overheat", "overheating", "engine hot",
        "temperature high", "engine temperature"
    ]):
        ai_response = (
            "Your vehicle may be overheating due to low coolant, "
            "a cooling system leak, radiator problems, a faulty "
            "thermostat, or a cooling fan issue.\n\n"
            "What you should do:\n"
            "1. Stop in a safe place if the temperature is high.\n"
            "2. Switch off the engine and allow it to cool.\n"
            "3. Never open the radiator cap while the engine is hot.\n"
            "4. Once cool, check for visible coolant leaks.\n\n"
            "If the temperature warning remains or steam appears, "
            "do not continue driving. Contact a qualified mechanic."
        )

    # BATTERY PROBLEMS
    elif any(word in q for word in [
        "battery", "dead battery", "battery issue",
        "battery problem", "battery not"
    ]):
        ai_response = (
            "A weak or faulty battery, loose battery terminals, "
            "corrosion, or an alternator issue may cause battery "
            "problems.\n\n"
            "Check whether the battery terminals are secure and "
            "free from visible corrosion. If the vehicle struggles "
            "to start or the battery warning light stays on, "
            "get the battery and charging system tested."
        )

    # VEHICLE NOT STARTING
    elif any(word in q for word in [
        "not starting", "won't start", "wont start",
        "doesn't start", "doesnt start",
        "cannot start", "can't start", "cant start"
    ]):
        ai_response = (
            "A vehicle that won't start may have a weak battery, "
            "starter motor problem, fuel delivery issue, or "
            "ignition system fault.\n\n"
            "Notice what happens when you turn the key or press "
            "the start button. Clicking sounds may indicate a "
            "battery or starter issue. If the engine cranks but "
            "does not start, the cause may be different.\n\n"
            "Avoid repeated attempts if the problem continues. "
            "Contact a qualified mechanic for diagnosis."
        )

    # BRAKE PROBLEMS
    elif any(word in q for word in [
        "brake", "brakes", "braking",
        "brake noise", "brake sound"
    ]):
        ai_response = (
            "Brake noise, vibration, or reduced braking can be "
            "caused by worn brake pads, damaged discs, or other "
            "braking system problems.\n\n"
            "If braking feels weak, the pedal feels unusual, "
            "or you hear severe grinding, stop driving safely "
            "and arrange a professional inspection.\n\n"
            "Do not ignore brake-related warning signs."
        )

    # ENGINE OIL
    elif any(word in q for word in [
        "engine oil", "oil change", "oil level",
        "oil leak", "lubricant"
    ]):
        ai_response = (
            "Engine oil lubricates moving engine parts and helps "
            "reduce friction and heat.\n\n"
            "Check the oil level using the method recommended "
            "in your vehicle's owner's manual. Follow the "
            "manufacturer's recommended oil grade and service "
            "interval.\n\n"
            "If you notice a major oil leak or an oil pressure "
            "warning, stop the engine safely and seek mechanic "
            "assistance."
        )

    # TYRE PROBLEMS
    elif any(word in q for word in [
        "tyre", "tyres", "tire", "tires",
        "puncture", "flat tyre", "flat tire",
        "tyre pressure", "tire pressure"
    ]):
        ai_response = (
            "Tyre problems can result from incorrect air pressure, "
            "punctures, uneven wear, or damaged tyres.\n\n"
            "Check tyre pressure when the tyres are cold and "
            "follow the pressure recommended by your vehicle "
            "manufacturer.\n\n"
            "If a tyre is flat or visibly damaged, avoid driving "
            "on it. Arrange a safe tyre replacement or repair."
        )

    # ENGINE PROBLEMS
    elif any(word in q for word in [
        "engine problem", "engine noise",
        "engine vibration", "engine issue",
        "engine warning", "check engine",
        "engine light"
    ]):
        ai_response = (
            "Engine problems can have several causes, including "
            "ignition issues, sensor faults, low fluids, or "
            "mechanical wear.\n\n"
            "Notice any unusual sounds, vibrations, warning "
            "lights, or loss of power. A check-engine light "
            "may require diagnostic scanning.\n\n"
            "If the engine is shaking severely, losing power "
            "suddenly, or showing a critical warning, stop "
            "safely and contact a mechanic."
        )

    # FUEL ECONOMY / MILEAGE
    elif any(word in q for word in [
        "mileage", "fuel economy", "fuel consumption",
        "low average", "less mileage", "poor mileage"
    ]):
        ai_response = (
            "Poor fuel economy can be caused by low tyre pressure, "
            "traffic, aggressive acceleration, dirty filters, "
            "or maintenance issues.\n\n"
            "Maintain correct tyre pressure, avoid unnecessary "
            "idling, drive smoothly, and follow your vehicle's "
            "service schedule.\n\n"
            "If mileage drops suddenly, have the vehicle checked "
            "by a qualified mechanic."
        )

    # GENERAL SERVICING
    elif any(word in q for word in [
        "service", "servicing", "maintenance",
        "maintain my vehicle", "vehicle maintenance"
    ]):
        ai_response = (
            "Regular vehicle servicing helps maintain safety "
            "and performance.\n\n"
            "Follow your manufacturer's service schedule. "
            "Routine checks generally include engine oil, "
            "filters, brakes, tyres, battery, coolant, lights, "
            "and other essential components.\n\n"
            "Your vehicle's exact service interval depends on "
            "its model, age, usage, and manufacturer guidance."
        )

    # COOLANT
    elif any(word in q for word in [
        "coolant", "radiator", "cooling system"
    ]):
        ai_response = (
            "Coolant helps regulate engine temperature. Low "
            "coolant may result from leaks or other cooling "
            "system problems.\n\n"
            "When the engine is completely cool, check the "
            "coolant reservoir level and look for visible leaks. "
            "Never open a hot radiator cap.\n\n"
            "If coolant is repeatedly low or the engine "
            "overheats, get the cooling system inspected."
        )

    # GENERAL VEHICLE HEALTH
    elif any(word in q for word in [
        "vehicle health", "car health",
        "vehicle condition", "car condition",
        "check my vehicle"
    ]):
        ai_response = (
            "You can maintain your vehicle's health by regularly "
            "checking engine oil, coolant, tyres, brakes, battery, "
            "and warning lights.\n\n"
            "Keep up with scheduled servicing and address "
            "unusual sounds, vibrations, leaks, or warning "
            "lights promptly.\n\n"
            "MotoMate can provide general guidance, but a "
            "physical inspection is needed to confirm a fault."
        )

    # UNRELATED OR UNKNOWN QUESTIONS
    else:
        ai_response = (
            "I'm MotoMate AI, your vehicle health and "
            "maintenance assistant.\n\n"
            "I can help with common questions about engine "
            "problems, overheating, batteries, brakes, tyres, "
            "engine oil, servicing, and vehicle maintenance.\n\n"
            "Could you please ask a vehicle-related question "
            "or provide more details about your vehicle problem?"
        )

    # -----------------------------
    # Add vehicle context
    # -----------------------------
    if vehicle:
        vehicle_info = (
            f"\n\nVehicle context: {vehicle.brand} "
            f"{vehicle.model}, {vehicle.fuel_type}."
        )
        ai_response += vehicle_info

    # -----------------------------
    # Response
    # -----------------------------
    return Response(
        {
            "message": "AI response generated successfully!",
            "user_id": user.id,
            "vehicle": vehicle_data,
            "question": question,
            "response": ai_response,
        },
        status=200
    )

@api_view(['POST'])
def mechanic_login(request):

    email = request.data.get('email', '').strip().lower()
    password = request.data.get('password', '')

    # Validate input
    if not email or not password:
        return Response(
            {
                "message": "Email and password are required."
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    # Find mechanic by email
    try:
        mechanic = Mechanic.objects.get(email__iexact=email)
    except Mechanic.DoesNotExist:
        return Response(
            {
                "message": "Invalid email or password."
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Check whether a password has been configured
    if not mechanic.password_hash:
        return Response(
            {
                "message": "Mechanic account is not activated yet."
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Verify hashed password
    if not check_password(password, mechanic.password_hash):
        return Response(
            {
                "message": "Invalid email or password."
            },
            status=status.HTTP_401_UNAUTHORIZED
        )

    # Login successful
    return Response(
        {
            "message": "Mechanic login successful!",
            "mechanic": {
                "id": mechanic.id,
                "name": mechanic.name,
                "email": mechanic.email,
                "phone": mechanic.phone,
                "shop_name": mechanic.shop_name,
                "address": mechanic.address,
                "rating": mechanic.rating,
                "is_available": mechanic.is_available
            }
        },
        status=status.HTTP_200_OK
    )
    
# ============================================================
# GET EMERGENCY REQUESTS FOR A MECHANIC
# ============================================================

@api_view(['GET'])
def get_mechanic_emergency_requests(request, mechanic_id):

    try:
        mechanic = Mechanic.objects.get(id=mechanic_id)

    except Mechanic.DoesNotExist:
        return Response(
            {"message": "Mechanic not found!"},
            status=404
        )

    emergency_requests = EmergencyRequest.objects.filter(
        mechanic_id=mechanic.id
    ).select_related(
        'user',
        'vehicle',
        'mechanic'
    ).order_by('-created_at')

    requests_data = []

    for emergency in emergency_requests:

        requests_data.append({
            "id": emergency.id,

            "user_id": emergency.user_id,
            "customer_name": emergency.user.name,
            "customer_phone": emergency.user.phone,

            "vehicle_id": emergency.vehicle_id,
            "vehicle_brand": emergency.vehicle.brand,
            "vehicle_model": emergency.vehicle.model,
            "registration_number": emergency.vehicle.registration_number,

            "mechanic_id": emergency.mechanic_id,

            "latitude": str(emergency.latitude),
            "longitude": str(emergency.longitude),

            "problem_description": emergency.problem_description,
            "status": emergency.status,

            "created_at": emergency.created_at.isoformat()
        })

    return Response({
        "message": "Mechanic emergency requests fetched successfully!",
        "mechanic_id": mechanic.id,
        "total_requests": len(requests_data),
        "requests": requests_data
    }, status=200)

# ============================================================
# ACCEPT / REJECT EMERGENCY REQUEST
# ============================================================

@api_view(['POST'])
def update_emergency_request_status(request, request_id):

    mechanic_id = request.data.get('mechanic_id')
    new_status = request.data.get('status')

    if not mechanic_id:
        return Response(
            {"message": "Mechanic ID is required!"},
            status=400
        )

    if new_status not in ['accepted', 'rejected']:
        return Response(
            {"message": "Status must be accepted or rejected!"},
            status=400
        )

    try:
        emergency = EmergencyRequest.objects.get(
            id=request_id,
            mechanic_id=mechanic_id
        )

    except EmergencyRequest.DoesNotExist:
        return Response(
            {"message": "Emergency request not found for this mechanic!"},
            status=404
        )

    if emergency.status not in ['assigned', 'pending']:
        return Response(
            {
                "message": (
                    f"Request cannot be updated. "
                    f"Current status: {emergency.status}"
                )
            },
            status=400
        )

    emergency.status = new_status
    emergency.save(update_fields=['status'])

    return Response({
        "message": f"Emergency request {new_status} successfully!",
        "request_id": emergency.id,
        "mechanic_id": emergency.mechanic_id,
        "status": emergency.status
    }, status=200)
    
# ============================================================
# GET MECHANIC HOME SERVICE REQUESTS
# ============================================================

@api_view(['GET'])
def get_mechanic_service_requests(request, mechanic_id):

    # Check mechanic
    try:
        mechanic = Mechanic.objects.get(id=mechanic_id)
    except Mechanic.DoesNotExist:
        return Response(
            {"message": "Mechanic not found!"},
            status=404
        )

    # Fetch unassigned bookings and bookings assigned to this mechanic
    service_requests = (
        ServiceRequest.objects
        .filter(
            Q(mechanic=mechanic) |
            Q(
                mechanic__isnull=True,
                status__in=['booked', 'pending']
            )
        )
        .select_related('user', 'vehicle', 'mechanic')
        .order_by('-created_at')
    )

    requests_data = []

    for service in service_requests:

        requests_data.append({
            "id": service.id,

            "user_id": service.user_id,
            "customer_name": service.user.name,
            "customer_phone": service.user.phone,
            "customer_email": service.user.email,

            "vehicle_id": service.vehicle_id,
            "vehicle_brand": service.vehicle.brand,
            "vehicle_model": service.vehicle.model,
            "registration_number":
                service.vehicle.registration_number,

            "service_type": service.service_type,

            "preferred_date":
                str(service.preferred_date)
                if service.preferred_date else None,

            "preferred_time":
                str(service.preferred_time)
                if service.preferred_time else None,

            "address": service.address,
            "notes": service.notes,

            "mechanic_id": service.mechanic_id,
            "status": service.status,

            "created_at": str(service.created_at),
        })

    return Response({
        "total_requests": len(requests_data),
        "service_requests": requests_data
    }, status=200)


# ============================================================
# ACCEPT / REJECT HOME SERVICE REQUEST
# ============================================================

@api_view(['POST'])
def update_service_request_status(request, request_id):

    mechanic_id = request.data.get('mechanic_id')
    new_status = request.data.get('status')

    # Validate mechanic ID
    if not mechanic_id:
        return Response(
            {"message": "Mechanic ID is required!"},
            status=400
        )

    # Validate status
    if new_status not in ['accepted', 'rejected']:
        return Response(
            {"message": "Status must be accepted or rejected!"},
            status=400
        )

    # Check mechanic
    try:
        mechanic = Mechanic.objects.get(id=mechanic_id)
    except Mechanic.DoesNotExist:
        return Response(
            {"message": "Mechanic not found!"},
            status=404
        )

    # Check service request
    try:
        service = ServiceRequest.objects.get(id=request_id)
    except ServiceRequest.DoesNotExist:
        return Response(
            {"message": "Service request not found!"},
            status=404
        )

    # Only unassigned bookings or this mechanic's accepted
    # booking can be updated.
    if service.mechanic_id not in [None, mechanic.id]:
        return Response(
            {"message": "This request belongs to another mechanic!"},
            status=403
        )

    if service.status not in ['booked', 'pending', 'accepted']:
        return Response(
            {"message": "This request has already been processed!"},
            status=400
        )

    # ACCEPT REQUEST
    if new_status == 'accepted':

        # Claim only if it is still unassigned and available.
        updated = ServiceRequest.objects.filter(
            id=request_id,
            mechanic__isnull=True,
            status__in=['booked', 'pending']
        ).update(
            mechanic=mechanic,
            status='accepted'
        )

        if updated == 0:
            return Response(
                {
                    "message":
                        "This request has already been accepted "
                        "or is no longer available!"
                },
                status=409
            )

        return Response({
            "message": "Home service request accepted successfully!",
            "request_id": request_id,
            "mechanic_id": mechanic.id,
            "status": "accepted"
        }, status=200)

    # REJECT REQUEST
    if new_status == 'rejected':

        # Release this mechanic's assignment if it was assigned
        # to them, or reject an unassigned booking.
        updated = ServiceRequest.objects.filter(
            id=request_id,
            status__in=['booked', 'pending', 'accepted']
        ).filter(
            Q(mechanic__isnull=True) |
            Q(mechanic=mechanic)
        ).update(
            mechanic=mechanic,
            status='rejected'
        )

        if updated == 0:
            return Response(
                {"message": "Unable to reject this request!"},
                status=409
            )

        return Response({
            "message": "Home service request rejected successfully!",
            "request_id": request_id,
            "mechanic_id": mechanic.id,
            "status": "rejected"
        }, status=200)
        
@api_view(['GET'])
def get_mechanic_notifications(request, mechanic_id):

    try:
        mechanic = Mechanic.objects.get(id=mechanic_id)
    except Mechanic.DoesNotExist:
        return Response(
            {"message": "Mechanic not found!"},
            status=404
        )

    notifications = MechanicNotification.objects.filter(
        mechanic=mechanic
    ).order_by('-created_at')

    notifications_data = []

    for notification in notifications:
        notifications_data.append({
            "id": notification.id,
            "mechanic_id": notification.mechanic_id,
            "request_id": notification.request_id,
            "title": notification.title,
            "message": notification.message,
            "notification_type": notification.notification_type,
            "is_read": notification.is_read,
            "created_at": notification.created_at.isoformat()
        })

    return Response({
        "message": "Mechanic notifications fetched successfully!",
        "mechanic_id": mechanic.id,
        "total_notifications": len(notifications_data),
        "notifications": notifications_data
    }, status=200)