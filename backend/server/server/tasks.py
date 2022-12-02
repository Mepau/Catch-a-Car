from datetime import date
import json
from server.wsgi import registry
from apps.endpoints.models import MLAlgorithm
from celery import shared_task
import os

STATUS_DIR = "./runs/track/" + date.today().strftime("%d-%m-%Y") + "/status/"

@shared_task(bind= True)
def predict_task(self, file, endpoint_name, time):
    #algorithm_version = self.request.query_params.get("version")
    with open(STATUS_DIR +  self.request.id + ".json", "w+") as f:
        f.write(json.dumps({
                "id": self.request.id.__str__(), 
                "status": "PROCESSING", 
                "received_time": time
                }))
    algs = MLAlgorithm.objects.filter(parent_endpoint__name = endpoint_name, status__active=True).order_by('-id')[0]
    
    algorithm_object = registry.endpoints[algs.id]


    #print(request.FILES["file"].read())
    prediction = algorithm_object.predict(task_id = self.request.id.__str__() ,source = file, save_vid=False, time= time, tracking_method = "ocsort", show_vid=True)
