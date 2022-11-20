from server.wsgi import registry
from apps.endpoints.models import MLAlgorithm
from celery import shared_task


@shared_task()
def predict_task(file, endpoint_name):
    #algorithm_version = self.request.query_params.get("version")
    algs = MLAlgorithm.objects.filter(parent_endpoint__name = endpoint_name, status__active=True)
 
    algorithm_object = registry.endpoints[6]
    #print(request.FILES["file"].read())
    prediction = algorithm_object.predict(source = file)