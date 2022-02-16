#!/bin/bash

FILE_SERVER_ADDR=
FILE_SHARE_PATH=
DATA_PVC_SIZE_GB=500
PIP_PVC_SIZE_GB=200
MOUNT_CMD=mount.nfs4
MOUNT_POINT=/ml-share

kubectl create namespace rapidsai
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
helm repo update

rm -f pv*.yaml
cp pv-values.yaml.template pv-values.yaml
sed "s#<FILE_SERVER_ADDR>#${FILE_SERVER_ADDR}#g" -i pv-values.yaml
sed "s#<FILE_SHARE_PATH>#${FILE_SHARE_PATH}#g" -i pv-values.yaml

cp pvc-worker-pip.yaml.template pvc-worker-pip.yaml
sed "s#<PIP_PVC_SIZE_GB>#${PIP_PVC_SIZE_GB}#g" -i pvc-worker-pip.yaml

cp pvc-mlshare.yaml.template pvc-mlshare.yaml
sed "s#<DATA_PVC_SIZE_GB>#${DATA_PVC_SIZE_GB}#g" -i pvc-mlshare.yaml

helm install nfs-subdir-external-provisioner --namespace rapidsai nfs-subdir-external-provisioner/nfs-subdir-external-provisioner -f pv-values.yaml
kubectl apply -f pvc-mlshare.yaml
kubectl apply -f pvc-worker-pip.yaml

kubectl get pv,pvc -n rapidsai

mkdir -p ${MOUNT_POINT}

echo "mount nfs to client..."
${MOUNT_CMD} ${FILE_SERVER_ADDR}:${FILE_SHARE_PATH} ${MOUNT_POINT}
mkdir /ml-share/dogs -p
cd /ml-share/dogs

echo "getting stanford dogs data-set"
wget http://vision.stanford.edu/aditya86/ImageNetDogs/images.tar
wget https://gist.githubusercontent.com/yrevar/942d3a0ac09ec9e5eb3a/raw/238f720ff059c1f82f368259d1ca4ffa5dd8f9f5/imagenet1000_clsidx_to_labels.txt
tar -xf images.tar


echo "getting yellow cab trip data"
mkdir /ml-share/taxi-csv -p
cd /ml-share/taxi-csv
for yr in `seq 2017 2019`; do for mth in 01 02 03 04 05 06 07 08 09 10 11 12; do nohup wget https://s3.amazonaws.com/nyc-tlc/trip+data/yellow_tripdata_$yr-$mth.csv > ${yr}_${mth} 2>&1 & done; done

