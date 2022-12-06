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

import numpy as np
import math

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
    colorPieChartData = {}
    typePieChartData = {}
    colorPieChartList = []
    typePieChartList = []
    jsonResponse = {}
    vehicleTimeChartData = {}
    vehicleTimeChartData2 = {}
    vehicleTimeChartList = []
    timeInterval = 0.5
    timeInterval2 = timeInterval
    with open(RESULTS_DIR + file_id + ".json") as f:
        data = json.load(f)

    for registry in data:
        veh_type, veh_color = registry["type_of_vehicle"].split("_")
        if veh_color in colorPieChartData:
            colorPieChartData[veh_color] += 1
        else:
            colorPieChartData[veh_color] = 1
        if veh_type in typePieChartData:
            typePieChartData[veh_type] += 1
        else:
            typePieChartData[veh_type] = 1
        for i in np.arange(round(registry["inital_time_of_capture"], 1), round(registry["final_time_of_capture"], 1), timeInterval):
            if i in vehicleTimeChartData:
                vehicleTimeChartData[i] += 1
            else:
                vehicleTimeChartData[i] = 1

    for key in colorPieChartData:
        colorPieChartList.append({"id": key, "amount": colorPieChartData[key]})

    for key in typePieChartData:
        typePieChartList.append({"id": key, "amount": typePieChartData[key]})
    
    for key, value in sorted(vehicleTimeChartData.items()):

        if key > timeInterval2:
            while key > timeInterval2:
                timeInterval2 += timeInterval
        if timeInterval2 in vehicleTimeChartData2:
            if vehicleTimeChartData2[timeInterval2] < value:
                vehicleTimeChartData2[timeInterval2] = value
        else:
            vehicleTimeChartData2[timeInterval2] = value

  
    for key in vehicleTimeChartData2:
       vehicleTimeChartList.append({"id": str(key), "amount": vehicleTimeChartData2[key]})
    
        
    jsonResponse = {"data": data, "colorPieChart": colorPieChartList, "typePieChart": typePieChartList, "timeChart": vehicleTimeChartList}

    return Response(json.dumps(jsonResponse), status = 200)

@api_view(['GET'],)
@permission_classes([AllowAny],)
def get_filtered_results(request):


    file_id = request.GET.get("id", "")
    colors = request.GET.getlist("colorOptions[]", [])
    types = request.GET.getlist("typeOptions[]", [])
    jsonResponse = []
    colorPieChartData = {}
    typePieChartData = {}
    colorPieChartList = []
    typePieChartList = []
    vehicleTimeChartData = {}
    vehicleTimeChartData2 = {}
    vehicleTimeChartList = []
    timeInterval = 0.5
    timeInterval2 = timeInterval

    with open(RESULTS_DIR + file_id + ".json") as f:
       data = json.load(f)

    if len(types) > 0 and len(colors) > 0:
        for registry in data:
            veh_type, veh_color = registry["type_of_vehicle"].split("_")
            if veh_type in types and veh_color in colors:
                jsonResponse.append(registry)

                if veh_color in colorPieChartData:
                    colorPieChartData[veh_color] += 1
                else:
                    colorPieChartData[veh_color] = 1

                if veh_type in typePieChartData:
                    typePieChartData[veh_type] += 1
                else:
                    typePieChartData[veh_type] = 1
                for i in np.arange(round(registry["inital_time_of_capture"], 1), round(registry["final_time_of_capture"], 1), timeInterval):
                    if i in vehicleTimeChartData:
                        vehicleTimeChartData[i] += 1
                    else:
                        vehicleTimeChartData[i] = 1

    elif len(types) == 0 and len(colors) > 0:
        for registry in data:
            veh_type, veh_color = registry["type_of_vehicle"].split("_")
            if veh_color in colors:
                jsonResponse.append(registry)

                if veh_color in colorPieChartData:
                    colorPieChartData[veh_color] += 1
                else:
                    colorPieChartData[veh_color] = 1

                if veh_type in typePieChartData:
                    typePieChartData[veh_type] += 1
                else:
                    typePieChartData[veh_type] = 1

                for i in np.arange(round(registry["inital_time_of_capture"], 1), round(registry["final_time_of_capture"], 1), timeInterval):
                    if i in vehicleTimeChartData:
                        vehicleTimeChartData[i] += 1
                    else:
                        vehicleTimeChartData[i] = 1

    elif len(types) > 0 and len(colors) == 0:
        for registry in data:
            veh_type, veh_color = registry["type_of_vehicle"].split("_")
            if veh_type in types:
                jsonResponse.append(registry)

                if veh_color in colorPieChartData:
                    colorPieChartData[veh_color] += 1
                else:
                    colorPieChartData[veh_color] = 1

                if veh_type in typePieChartData:
                    typePieChartData[veh_type] += 1
                else:
                    typePieChartData[veh_type] = 1

                for i in np.arange(round(registry["inital_time_of_capture"], 1), round(registry["final_time_of_capture"], 1), timeInterval):
                    if i in vehicleTimeChartData:
                        vehicleTimeChartData[i] += 1
                    else:
                        vehicleTimeChartData[i] = 1
    else:
        for registry in data:
            veh_type, veh_color = registry["type_of_vehicle"].split("_")
            if veh_color in colorPieChartData:
                colorPieChartData[veh_color] += 1
            else:
                colorPieChartData[veh_color] = 1
            if veh_type in typePieChartData:
                typePieChartData[veh_type] += 1
            else:
                typePieChartData[veh_type] = 1
            for i in np.arange(round(registry["inital_time_of_capture"], 1), round(registry["final_time_of_capture"], 1), timeInterval):
                if i in vehicleTimeChartData:
                    vehicleTimeChartData[i] += 1
                else:
                    vehicleTimeChartData[i] = 1

        jsonResponse = data
    
    for key in colorPieChartData:
        colorPieChartList.append({"id": key, "amount": colorPieChartData[key]})

    for key in typePieChartData:
        typePieChartList.append({"id": key, "amount": typePieChartData[key]})

    for key, value in sorted(vehicleTimeChartData.items()):

        if key > timeInterval2:
            while key > timeInterval2:
                timeInterval2 += timeInterval
        if timeInterval2 in vehicleTimeChartData2:
            if vehicleTimeChartData2[timeInterval2] < value:
                vehicleTimeChartData2[timeInterval2] = value
        else:
            vehicleTimeChartData2[timeInterval2] = value

  
    for key in vehicleTimeChartData2:
       vehicleTimeChartList.append({"id": str(key), "amount": vehicleTimeChartData2[key]})
    

    jsonResponse = {"data": jsonResponse, "colorPieChart": colorPieChartList, "typePieChart": typePieChartList, "timeChart": vehicleTimeChartList}
    
    return Response(json.dumps(jsonResponse),status = 200)

@api_view(['GET'],)
@permission_classes([AllowAny],)
def get_status(request):

    file_id = request.GET.get("id", "")
    res_data = []
    multiple = False
    if file_id != "":
        with open(STATUS_DIR + file_id + ".json") as f:
            res_data = json.load(f)
    else:
        multiple = True
        with os.scandir(STATUS_DIR) as entries:
            for entry in entries:
                with open(STATUS_DIR + entry.name, "r") as f:
                    file_data = json.load(f)
                    res_data.append(file_data)
                    
    if multiple:
        return Response(json.dumps(res_data), status = 200)
    else:
        return Response(res_data, status = 200)
    

