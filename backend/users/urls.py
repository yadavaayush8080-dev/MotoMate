from django.urls import path

from .views import (
    users_test,
    register_user,
    update_user_profile,
)


urlpatterns = [

    path('test/', users_test),

    path('register/', register_user),

    path(
        'update/<int:user_id>/',
        update_user_profile,
    ),

]