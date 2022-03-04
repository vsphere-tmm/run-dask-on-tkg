fill the following params value

the following values are using the PVC created earlier

VOLUME_NAME=external-nfs-storage

CLAIM_NAME=external-nfs-pvc

MOUNT_PATH="/ml-share"

PIP_CACHE_CLAIM_NAME=external-nfs-pip-cache-pvc

PIP_CACHE_MOUNT_PATH="/root/.cache/pip"

PIP_CACHE_VOLUME_NAME=pip-cache-external-nfs-storage

keep the values of the following params

RUN_TIME=21.10-cuda11.2-runtime-ubuntu20.04

REPO="nvcr.io/nvidia/rapidsai/rapidsai"

SERVICE_TYPE="LoadBalancer"

specify the resource info 

WORKER_REPLICAS=7

WORKER_CPU=6

WORKER_MEMORY=48G

SCHEDULER_CPU=3

SCHEDULER_MEMORY=8G

JUPYTER_CPU=3

JUPYTER_MEMORY=8G

if jupyter needs to configure with vGPU, uncomment the following code lines
'#  --set dask.jupyter.nodeSelector."kubernetes\\.io/hostname"=$JUPYTER_NODE_NAME \'
'#  --set dask.jupyter.resources.limits."nvidia\\.com/gpu"=1 --set dask.jupyter.resources.requests."nvidia\\.com/gpu"=1'
