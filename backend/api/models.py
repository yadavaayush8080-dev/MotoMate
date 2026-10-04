from django.db import models
from users.models import User


class Vehicle(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='user_id',
        related_name='vehicles'
    )

    brand = models.CharField(max_length=50)
    model = models.CharField(max_length=50)
    registration_number = models.CharField(
        max_length=20,
        unique=True
    )
    fuel_type = models.CharField(max_length=20)

    vehicle_year = models.IntegerField(
        null=True,
        blank=True
    )

    current_kilometers = models.IntegerField(
        null=True,
        blank=True
    )

    insurance_expiry = models.DateField(
        null=True,
        blank=True
    )

    puc_expiry = models.DateField(
        null=True,
        blank=True
    )

    last_service_date = models.DateField(
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = 'vehicles'
        managed = False

    def __str__(self):
        return f'{self.brand} {self.model} - {self.registration_number}'


class Mechanic(models.Model):

    id = models.IntegerField(primary_key=True)

    name = models.CharField(max_length=100)

    email = models.EmailField(
        max_length=100,
        null=True,
        blank=True,
        unique=True
    )

    password_hash = models.CharField(
        max_length=255,
        null=True,
        blank=True
    )

    phone = models.CharField(max_length=15)

    shop_name = models.CharField(
        max_length=100,
        null=True,
        blank=True
    )

    address = models.CharField(
        max_length=255,
        null=True,
        blank=True
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        null=True,
        blank=True
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7,
        null=True,
        blank=True
    )

    rating = models.DecimalField(
        max_digits=2,
        decimal_places=1,
        default=0.0,
        null=True,
        blank=True
    )

    is_available = models.BooleanField(
        default=True,
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = 'mechanics'
        managed = False

    def __str__(self):
        return self.name
    
class EmergencyRequest(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='user_id',
        related_name='emergency_requests'
    )

    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.CASCADE,
        db_column='vehicle_id',
        related_name='emergency_requests'
    )

    mechanic = models.ForeignKey(
        Mechanic,
        on_delete=models.SET_NULL,
        db_column='mechanic_id',
        null=True,
        blank=True,
        related_name='emergency_requests'
    )

    latitude = models.DecimalField(
        max_digits=10,
        decimal_places=7
    )

    longitude = models.DecimalField(
        max_digits=10,
        decimal_places=7
    )

    problem_description = models.CharField(
        max_length=255,
        null=True,
        blank=True
    )

    status = models.CharField(
        max_length=20,
        default='pending',
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = 'emergency_requests'
        managed = False

    def __str__(self):
        return f'Emergency Request {self.id}'
    
class ServiceRequest(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='user_id',
        related_name='service_requests'
    )
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.CASCADE,
        db_column='vehicle_id',
        related_name='service_requests'
        
    )
    
    mechanic = models.ForeignKey(
        Mechanic,
        on_delete=models.SET_NULL,
        db_column='mechanic_id',
        related_name='service_requests',
        null=True,
        blank=True
    )
    service_type = models.CharField(max_length=100)
    preferred_date = models.DateField(null=True, blank=True)
    preferred_time = models.TimeField(null=True, blank=True)
    address = models.CharField(max_length=255, null=True, blank=True)
    status = models.CharField(max_length=20, default='pending', null=True, blank=True)
    notes = models.CharField(max_length=255, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'service_requests'
        managed = False

    def __str__(self):
        return f'Service Request {self.id}'


class Notification(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        db_column='user_id',
        related_name='notifications'
    )
    vehicle = models.ForeignKey(
        Vehicle,
        on_delete=models.SET_NULL,
        db_column='vehicle_id',
        null=True,
        blank=True,
        related_name='notifications'
    )
    title = models.CharField(max_length=100)
    message = models.CharField(max_length=255)
    notification_type = models.CharField(max_length=50, null=True, blank=True)
    is_read = models.BooleanField(default=False, null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'notifications'
        managed = False

    def __str__(self):
        return self.title

class MechanicNotification(models.Model):

    mechanic = models.ForeignKey(
        Mechanic,
        on_delete=models.CASCADE,
        db_column='mechanic_id',
        related_name='notifications',
        to_field='id'
    )
    
    request_id = models.IntegerField(null=True, blank=True)

    title = models.CharField(max_length=100)

    message = models.CharField(max_length=255)

    notification_type = models.CharField(
        max_length=50,
        null=True,
        blank=True
    )

    is_read = models.BooleanField(
        default=False,
        null=True,
        blank=True
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )

    class Meta:
        db_table = 'mechanic_notifications'

    def __str__(self):
        return self.title