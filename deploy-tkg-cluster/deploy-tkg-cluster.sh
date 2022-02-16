#!/bin/bash

SUPERVISOR_CLUSTER_ADDRESS=
VSPHERE_USERNAME=
VSPHERE_PASSWORD=

NAMESPACE=
TKG_CLUSTER_NAME=
NON_GPU_WORKER_STORAGECLASS_NAME=
GPU_WORKER_STORAGECLASS_NAME=
GPU_WORKER_REPLICAS=
GPU_WORKER_VMCLASS_NAME=
NON_GPU_WORKER_VMCLASS_NAME=best-effort-2xlarge
CONTROLPLANE_VMCLASS_NAME=best-effort-medium


export KUBECTL_VSPHERE_PASSWORD=$VSPHERE_PASSWORD
echo "Login into Supervisor Cluster"
	kubectl vsphere login --server=https://${SUPERVISOR_CLUSTER_ADDRESS} --vsphere-username ${VSPHERE_USERNAME} --insecure-skip-tls-verify 

echo "Verify variables"
	echo "Checking namespace"
	kubectl config get-contexts --no-headers -o name | grep $NAMESPACE && echo SUCCESS || (echo FAIL && exit 1)
	kubectl config use-context $NAMESPACE

	echo "Checking NON_GPU_WORKER_STORAGECLASS_NAME"
	kubectl describe namespace $NAMESPACE | grep "$NON_GPU_WORKER_STORAGECLASS_NAME\..*/requests.storage" && echo SUCCESS || (echo FAIL && exit 1)

	echo "Checking GPU_WORKER_STORAGECLASS_NAME"
	kubectl describe namespace $NAMESPACE | grep "$GPU_WORKER_STORAGECLASS_NAME\..*/requests.storage" && echo SUCCESS || (echo FAIL && exit 1)

	echo "Checking GPU_WORKER_VMCLASS_NAME"
	kubectl get vmclass -o name | grep "\/$GPU_WORKER_VMCLASS_NAME" && echo SUCCESS || (echo FAIL && exit 1)

	echo "Checking NON_GPU_WORKER_VMCLASS_NAME"
	kubectl get vmclass -o name | grep "\/$NON_GPU_WORKER_VMCLASS_NAME" && echo SUCCESS || (echo FAIL && exit 1)

	echo "Checking CONTROLPLANE_VMCLASS_NAME"
	kubectl get vmclass -o name | grep "\/$CONTROLPLANE_VMCLASS_NAME" && echo SUCCESS || (echo FAIL && exit 1)


echo "Prepare TKG cluster yaml"
	rm -f tkg-cluster.yaml
	cp -f tkg-cluster.yaml.template tkg-cluster.yaml
	vars=`grep -o "<.*>" tkg-cluster.yaml | sort | uniq`
	for var in $vars
	do
	  rep1=${var^^}
	  rep2=${rep1//-/_}
	  rep3=${rep2//<}
	  rep=${rep3//>}
	  if [ -z "${!rep}" ]
	  then
	    echo "$var is not defined"
	    #exit 1
	   fi
	  sed -i "s/${var}/${!rep}/g" tkg-cluster.yaml
	done

echo "Provision TKG Cluster"
	kubectl apply -f tkg-cluster.yaml

echo "Waiting for TKG Cluster to be available"
 while true; 
 do
 sleep 10
 case `kubectl get tanzukubernetescluster.run.tanzu.vmware.com/$TKG_CLUSTER_NAME -o custom-columns=":status.phase"` in
 	*"creating"*)
 	date; echo "creating...";
 	;;

 	*"running"*)
 	echo "TKG Cluster $TKG_CLUSTER_NAME Created!"
 	read -p "Press enter to continue..."
 	break
 	;;

 	*)
 	echo "ERROR, please run the following command to debug:\n kubectl describe tanzukubernetescluster.run.tanzu.vmware.com/$TKG_CLUSTER_NAME"
 	exit 1
 	;;
 esac
 done


echo "Login into TKG Cluster"
	kubectl vsphere login --server=https://${SUPERVISOR_CLUSTER_ADDRESS} --vsphere-username ${VSPHERE_USERNAME} --insecure-skip-tls-verify --tanzu-kubernetes-cluster-namespace ${NAMESPACE} --tanzu-kubernetes-cluster-name $TKG_CLUSTER_NAME
