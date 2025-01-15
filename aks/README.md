# AKS specific resources

This directory contains resources specific to Azure Kubernetes Service (AKS).  

## Storage class

When you use the embedded MongoDB instance of Automation Decision Services and/or use the file system storage for decision service archives, you must use an [Azure files storage class](https://learn.microsoft.com/en-us/azure/aks/azure-files-csi#create-a-custom-storage-class). It allows access from multiple pods and nodes.  

A dedicated storage class must be configured to set permissions compatible with Automation Decision Services requirements.  The `uid` parameter must be set to `50001` and `gid` set to `0`.

For example:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: afs-for-ads
allowVolumeExpansion: true
mountOptions:
- dir_mode=0770
- file_mode=0770
- uid=50001
- gid=0
- mfsymlinks
- cache=strict
- nosharesock
parameters:
  skuName: Standard_LRS
provisioner: file.csi.azure.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

Then, set the following Automation Decision Services parameters in the Automation Decision Services CR to use this storage class like it's done int the example minimal [CR](../descriptors/ADS-minimal-AKS-CR.yaml):

```
spec:
  mongo:
    run_as_user: 50001
    persistence:
      storage_class_name: afs-for-ads

  decision_runtime:
    decision_runtime_service:
          persistence:
             storage_class_name: afs-for-ads
```

## Ingress with nginx controller

Use [nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) to serve ADS ingresses to handle url rewriting.  
You can use basic installation [instructions](https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/load-bal-ingress-c/create-unmanaged-ingress-controller?tabs=azure-cli#basic-configuration)

Then you'll use [ads-generate-ingresses.sh](../scripts/ads-generate-ingresses.sh) script with `-t` option to obtain the ingresses definition you'll have to apply to your cluster.  
This will generate ingresses with TLS termination done into nginx pods. 
By default certificates presented while accessing to https://cp-console.subdomain.my-company.com and https://ads-cpd.subdomain.my-company.com will be self signed and  generated by the certificate manager from the `zen-tls-issuer` Issuer.  
This behaviour is controlled by `cert-manager.io/issuer: zen-tls-issuer` annotation in ingress descriptor as described in https://cert-manager.io/docs/usage/ingress/. 

```
$> ./ads-generate-ingresses.sh -n ads -t
# Checking prereqs ...
[✔] kubectl command available
[INFO] Writing kubernetes manifests to /tmp/tmp.5ztkofcnIU
$> kubectl apply -f /tmp/tmp.5ztkofcnIU
```
Create an _alias_ A record for `*.subdomain.my-company.com` to the load balancer plublic IP adress.
It can be obtained with
```
kubectl get service -n ingress-basic ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
```
Then, https://ads-cpd.subdomain.my-company.com will be accessible.