#!/bin/bash

VOLUME_NAME=external-nfs-storage
CLAIM_NAME=external-nfs-pvc
MOUNT_PATH="/ml-share"
PIP_CACHE_CLAIM_NAME=external-nfs-pip-cache-pvc
PIP_CACHE_MOUNT_PATH="/root/.cache/pip"
PIP_CACHE_VOLUME_NAME=pip-cache-external-nfs-storage
RUN_TIME=21.10-cuda11.2-runtime-ubuntu20.04
REPO="nvcr.io/nvidia/rapidsai/rapidsai"
SERVICE_TYPE="LoadBalancer"
WORKER_REPLICAS=7
WORKER_CPU=6
WORKER_MEMORY=48G
SCHEDULER_CPU=3
SCHEDULER_MEMORY=8G
JUPYTER_CPU=3
JUPYTER_MEMORY=8G

kubectl create namespace rapidsai
wget https://github.com/rapidsai/helm-chart/archive/refs/heads/main.zip
unzip main.zip
kubectl apply -f rolebindings.yaml
kubectl apply -f post-rolebindings.yaml

SCHEDULER_NODE_NAME=`kubectl get nodes | grep scheduler | awk '{print $1}'`
JUPYTER_NODE_NAME=`kubectl get nodes | grep jupyter | awk '{print $1}'`

cd helm-chart-main
helm dep update rapidsai
cd ..

helm install --namespace rapidsai rapidsai helm-chart-main/rapidsai \
  --set dask.scheduler.image.tag=$RUN_TIME --set dask.scheduler.image.repository=$REPO \
  --set dask.scheduler.serviceType=${SERVICE_TYPE} --set dask.jupyter.serviceType=${SERVICE_TYPE} \
  --set dask.scheduler.resources.limits.cpu=$SCHEDULER_CPU --set dask.scheduler.resources.limits.memory=$SCHEDULER_MEMORY \
  --set dask.scheduler.resources.requests.cpu=$SCHEDULER_CPU --set dask.scheduler.resources.requests.memory=$SCHEDULER_MEMORY \
  --set dask.scheduler.nodeSelector."kubernetes\\.io/hostname"=$SCHEDULER_NODE_NAME \
  --set dask.worker.image.tag=$RUN_TIME --set dask.worker.image.repository=$REPO \
  --set dask.worker.replicas=$WORKER_REPLICAS \
  --set dask.worker.threads_per_worker=8 \
  --set dask.worker.env[0].name=EXTRA_PIP_PACKAGES --set dask.worker.env[0].value="--upgrade torch==1.10.1+cu113 torchvision==0.11.2+cu113 torchaudio==0.10.1+cu113 -f https://download.pytorch.org/whl/cu113/torch_stable.html --trusted-host download.pytorch.org" \
  --set dask.worker.resources.limits.cpu=$WORKER_CPU --set dask.worker.resources.limits.memory=$WORKER_MEMORY --set dask.worker.resources.limits."nvidia\\.com/gpu"=1 \
  --set dask.worker.resources.requests.cpu=$WORKER_CPU --set dask.worker.resources.requests.memory=$WORKER_MEMORY --set dask.worker.resources.requests."nvidia\\.com/gpu"=1 \
  --set dask.worker.mounts.volumes[0].name=$VOLUME_NAME --set dask.worker.mounts.volumes[0].persistentVolumeClaim.claimName=$CLAIM_NAME \
  --set dask.worker.mounts.volumeMounts[0].mountPath=$MOUNT_PATH --set dask.worker.mounts.volumeMounts[0].name=$VOLUME_NAME \
  --set dask.worker.mounts.volumes[1].name=${PIP_CACHE_VOLUME_NAME} --set dask.worker.mounts.volumes[1].persistentVolumeClaim.claimName=$PIP_CACHE_CLAIM_NAME \
  --set dask.worker.mounts.volumeMounts[1].mountPath=${PIP_CACHE_MOUNT_PATH} --set dask.worker.mounts.volumeMounts[1].name=$PIP_CACHE_VOLUME_NAME \
  --set dask.jupyter.image.tag=$RUN_TIME --set dask.jupyter.image.repository=$REPO \
  --set dask.jupyter.resources.limits.cpu=$JUPYTER_CPU --set dask.jupyter.resources.limits.memory=$JUPYTER_MEMORY \
  --set dask.jupyter.resources.requests.cpu=$JUPYTER_CPU --set dask.jupyter.resources.requests.memory=$JUPYTER_MEMORY \
  --set dask.jupyter.mounts.volumes[0].name=${VOLUME_NAME} --set dask.jupyter.mounts.volumes[0].persistentVolumeClaim.claimName=$CLAIM_NAME 

#  --set dask.jupyter.nodeSelector."kubernetes\\.io/hostname"=$JUPYTER_NODE_NAME \
#  --set dask.jupyter.resources.limits."nvidia\\.com/gpu"=1 --set dask.jupyter.resources.requests."nvidia\\.com/gpu"=1

kubectl get all -n rapidsai

JUPYTER_POD=`kubectl get pods -n rapidsai -o name | grep rapidsai-jupyter | cut -d "/" -f2`

echo "Waiting for Jupyter pod to be available"
 while true; 
 do
 sleep 10
 case `kubectl get pod/${JUPYTER_POD} -n rapidsai -o custom-columns=":status.phase"` in
 	*"Pending"*)
 	if [ `kubectl get pod/${JUPYTER_POD} -n rapidsai -o custom-columns=":status.containerStatuses[0].state.waiting.reason"` == "ContainerCreating" ]
 	then
 	  date; echo "creating...";
 	else
 	  echo "ERROR, please run the following command to debug:\n kubectl describe pod/${JUPYTER_POD} -n rapidsai"
 	  break
 	fi 	
 	;;

 	*"Running"*)
 	echo "Jupyter pod up and running"
 	break
 	;;

 	*)
 	echo "ERROR, please run the following command to debug: kubectl describe pod/${JUPYTER_POD} -n rapidsai"
 	exit 1
 	;;
 esac
 done




#when jupyter is up and running
SCHEDULER_IP=`kubectl get svc/rapidsai-scheduler -n rapidsai -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`
JUPYTER_IP=`kubectl get svc/rapidsai-jupyter -n rapidsai -o jsonpath="{.status.loadBalancer.ingress[0].ip}"`

cp jupyter-examples/* .
sed "s/<SCHEDULER_EXTERNAL_IP>/${SCHEDULER_IP}/g" -i *.ipynb

kubectl cp dog_classification_pytorch.ipynb  ${JUPYTER_POD}:/rapids/notebooks -n rapidsai
kubectl cp xgboost_with_rapids.ipynb ${JUPYTER_POD}:/rapids/notebooks -n rapidsai

rm *.ipynb

echo "Please visit http://${JUPYTER_IP}"
