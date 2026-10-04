from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_api),

    path('vehicle/', views.add_vehicle),
    path('vehicle/<int:user_id>/', views.get_user_vehicle),
    path('vehicle/update/<int:vehicle_id>/', views.update_vehicle),

    path('emergency/', views.create_emergency_request),
    path('emergency/<int:request_id>/', views.get_emergency_request),
    
    path(
    'mechanic/<int:mechanic_id>/emergency-requests/',
    views.get_mechanic_emergency_requests,
),

path(
    'emergency/<int:request_id>/update-status/',
    views.update_emergency_request_status,
),

    path('service/', views.create_service_request),
    path('notifications/<int:user_id>/', views.get_user_notifications),
    path('vehicle-health/<int:user_id>/', views.get_vehicle_health),
    path('vehicle-health/<int:user_id>/', views.get_vehicle_health),
    path('ai-assistant/', views.ai_assistant),
    path('mechanic-login/', views.mechanic_login, name='mechanic_login'),
        # Mechanic Home Service Requests
    path(
        'mechanic/<int:mechanic_id>/service-requests/',
        views.get_mechanic_service_requests,
    ),

    path(
        'service/<int:request_id>/update-status/',
        views.update_service_request_status,
    ),
    
    path(
    'mechanic/<int:mechanic_id>/notifications/',
    views.get_mechanic_notifications,
),
    
]