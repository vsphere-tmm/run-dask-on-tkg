Prepare the value for the following parameters, fill into deploy-tkg-cluster.sh and run this script to deploy tkg cluster.

SUPERVISOR_CLUSTER_ADDRESS=

#the vSphere user needs to have EDIT or OWNER permission of the namespace created

VSPHERE_USERNAME=
VSPHERE_PASSWORD=

#Namespace created in vSphere

NAMESPACE=

#TKG cluster name to be created

TKG_CLUSTER_NAME=

#the name of storage policy assigned to namespace

NON_GPU_WORKER_STORAGECLASS_NAME=
GPU_WORKER_STORAGECLASS_NAME=

#how many GPU worker nodes to create

GPU_WORKER_REPLICAS=

#the VM Class with vGPU created in vSphere

GPU_WORKER_VMCLASS_NAME=

#the value below can be changed to other VM Classes assigned to the namespace

NON_GPU_WORKER_VMCLASS_NAME=best-effort-2xlarge
CONTROLPLANE_VMCLASS_NAME=best-effort-medium
