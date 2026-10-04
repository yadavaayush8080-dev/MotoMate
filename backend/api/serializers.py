from rest_framework import serializers
from .models import Vehicle
from .models import Vehicle, EmergencyRequest, Mechanic, ServiceRequest, Notification


class VehicleSerializer(serializers.ModelSerializer):

    class Meta:
        model = Vehicle
        fields = [
            'id',
            'user',
            'brand',
            'model',
            'registration_number',
            'fuel_type',
            'vehicle_year',
            'current_kilometers',
            'insurance_expiry',
            'puc_expiry',
            'last_service_date',
            'created_at',
        ]

        read_only_fields = [
            'id',
            'created_at',
        ]
        
class ServiceRequestSerializer(serializers.ModelSerializer):
    class Meta:
        model = ServiceRequest
        fields = [
            'id',
            'user',
            'vehicle',
            'service_type',
            'preferred_date',
            'preferred_time',
            'address',
            'status',
            'notes',
            'created_at',
        ]
        read_only_fields = ['id', 'status', 'created_at']


class NotificationSerializer(serializers.ModelSerializer):
    class Meta:
        model = Notification
        fields = [
            'id',
            'user',
            'vehicle',
            'title',
            'message',
            'notification_type',
            'is_read',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at']