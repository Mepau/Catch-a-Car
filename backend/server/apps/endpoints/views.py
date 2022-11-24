from curses.ascii import HT
import datetime
import os
from ssl import PEM_cert_to_DER_cert
from django.shortcuts import render

# please add imports
import json
from numpy.random import rand
from rest_framework import views, status
from rest_framework.response import Response
from server.wsgi import registry
from apps.endpoints.models import MLAlgorithm, MLRequest, Endpoint, MLAlgorithmStatus
from apps.endpoints.models import MLRequest
from rest_framework.permissions import AllowAny
from rest_framework.decorators import api_view, permission_classes

# backend/server/apps/endpoints/views.py file
from rest_framework import viewsets, mixins
from django.db import transaction
from rest_framework.exceptions import APIException

from server.tasks import predict_task

from celery.result import AsyncResult

STATUS_DIR = "./runs/track/" + datetime.date.today().strftime("%d-%m-%Y") + "/status/"
RESULTS_DIR = "./runs/track/" + datetime.date.today().strftime("%d-%m-%Y") + "/tracks/"


class EndpointViewSet(
    mixins.RetrieveModelMixin, mixins.ListModelMixin, viewsets.GenericViewSet
):
    queryset = Endpoint.objects.all()


class MLAlgorithmViewSet(
    mixins.RetrieveModelMixin, mixins.ListModelMixin, viewsets.GenericViewSet
):
    queryset = MLAlgorithm.objects.all()


def deactivate_other_statuses(instance):
    old_statuses = MLAlgorithmStatus.objects.filter(parent_mlalgorithm = instance.parent_mlalgorithm,
                                                        created_at__lt=instance.created_at,
                                                        active=True)
    for i in range(len(old_statuses)):
        old_statuses[i].active = False
    MLAlgorithmStatus.objects.bulk_update(old_statuses, ["active"])

class MLAlgorithmStatusViewSet(
    mixins.RetrieveModelMixin, mixins.ListModelMixin, viewsets.GenericViewSet,
    mixins.CreateModelMixin
):
    queryset = MLAlgorithmStatus.objects.all()
    def perform_create(self, serializer):
        try:
            with transaction.atomic():
                instance = serializer.save(active=True)
                # set active=False for other statuses
                deactivate_other_statuses(instance)

        except Exception as e:
            raise APIException(str(e))

class MLRequestViewSet(
    mixins.RetrieveModelMixin, mixins.ListModelMixin, viewsets.GenericViewSet,
    mixins.UpdateModelMixin
):
    queryset = MLRequest.objects.all()



@permission_classes([AllowAny],)
class PredictView(views.APIView):
    def post(self, request, endpoint_name, format=None):

        #print(request.FILES["file"].name)
        with open("./videos/"+request.FILES["file"].name, 'wb+') as wfile:
            fileBytes = request.FILES["file"].read()
            wfile.write(fileBytes)
            wfile.close()
        
        time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%SZ")
        res = predict_task.delay(endpoint_name=endpoint_name, file= "./videos/" +request.FILES["file"].name, time = time)

        with open(STATUS_DIR +  res.task_id + ".json", "w+") as f:
            f.write(json.dumps({
                    "id":res.task_id, 
                    "status": "RECEIVED", 
                    "received_time": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%SZ")
                    }))

        return Response({"id": f"{res.task_id}", "status": "RECEIVED", "received_time": time}, status= 200)

@api_view(['GET'],)
@permission_classes([AllowAny],)
def hello_django(request):
    return Response({'message: Hello Django'}, status = 200)

@api_view(['GET'],)
@permission_classes([AllowAny],)
def get_results(request):


    file_id = request.GET.get("id", "")
    with open(STATUS_DIR + file_id + ".json") as f:
        data = json.load(f)
    

    return Response(data, status = 200)

@api_view(['GET'],)
@permission_classes([AllowAny],)
def get_filtered_results(request):


    file_id = request.GET.get("id", "")
    with open(STATUS_DIR + file_id + ".json") as f:
        data = json.load(f)
    

    return Response(data, status = 200)

@api_view(['GET'],)
@permission_classes([AllowAny],)
def get_status(request):

    file_id = request.GET.get("id", "")
    with open(STATUS_DIR + file_id + ".json") as f:
        data = json.load(f)

    return Response(data, status = 200)

