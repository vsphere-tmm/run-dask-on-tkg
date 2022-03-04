fill the following params value in script configure-pvc.sh and then run the script to create 2 persistent volume claims, 
one for sharing the data to load, another for caching the pip wheel

#NFS file share info

FILE_SERVER_ADDR=

FILE_SHARE_PATH=

#the size of shared data and pip cache in GiB

DATA_PVC_SIZE_GB=500

PIP_PVC_SIZE_GB=200

the client should have nfs mount cmd installed, here we use mount.nfs4, might be differenet in your environment
the script will also mount the file share to the client where you run the script.

MOUNT_CMD=mount.nfs4

MOUNT_POINT=/ml-share
