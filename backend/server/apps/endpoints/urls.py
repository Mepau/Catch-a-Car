from django.urls import path
from . import views

urlpatterns = [
    path("hellodjango", views.hello_django, name="hellodjango"),
    path("Status", views.get_status, name="get_status"),
    path("Results", views.get_results, name="get_results"),
    path("Results/filter", views.get_filtered_results, name="get_filtered_results")
]