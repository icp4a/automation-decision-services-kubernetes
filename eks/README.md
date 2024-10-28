# EKS specific resources

This directory contains resources specific to Amazon Elastic Kubernetes Service (EKS).  

## Storage class

When you use the embedded MongoDB instance of Automation Decision Services and/or use the file system storage for decision service archives, you must use an [EFS storage class](https://docs.aws.amazon.com/eks/latest/userguide/efs-csi.html). It allows access from multiple pods and nodes.  

A dedicated storage class must be configured to set permissions compatible with Automation Decision Services requirements.  The `uid` parameter must be set to `50001`, and the `directoryPerms` parameter must be set to allow full access to the uid.

For example:

```
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: efs-for-ads
parameters:
  fileSystemId: <your EFS file-system id>
  basePath: /dynamic_provisioning_for_ads
  directoryPerms: "770"
  uid: "50001"
  gid: "0"
  provisioningMode: efs-ap
provisioner: efs.csi.aws.com
reclaimPolicy: Delete
volumeBindingMode: Immediate
```

Then, set the following Automation Decision Services parameters in the Automation Decision Services CR to use this storage class:

```
spec:
  mongo:
    run_as_user: 50001
    persistence:
      storage_class_name: efs-for-ads

  decision_runtime:
    decision_runtime_service:
          persistence:
             storage_class_name: efs-for-ads
```

## Certificate management

You have to use a x509 certificate with a distinguished name that matches your `.subdomain.my-company.com` name, which is presented by your Network Load Balancer.  
You can generate an untrusted certificate for testing purpose by using the following command:

```shell
openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -keyout subdomain.key -out subdomain.crt -subj "/CN=*.subdomain.my-company.com/OU=it/O=<your-org>/L=<your-location>/C=<your-country>>"
```

and then, upload it to AWS Certificate Manager by using the following command:

```shell
aws acm import-certificate --certificate fileb:///tmp/subdomain.crt --private-key fileb:///tmp/subdomain.key
```
This command returns the Amazon Resource Name (ARN) of the registered certificate that you can reference in the `service.beta.kubernetes.io/aws-load-balancer-ssl-cert` annotation in following section.

Then, create a wildcard DNS entry in your domain that corresponds to the domain declared
in the `ibm-cpp-config` ConfigMap and your Ingresses.

If the DNS zone is managed by AWS, create an _alias_ A record to the NLB.  (NLB IP addresses change over time. Therefore, a static A record is not applicable and becomes invalid soon).  For DNS zones that are not managed by AWS, a CNAME entry to the NLB automatic hostname is probably usable.

## Ingress and Network Load Balancer

You must use [nginx Ingress Controller](https://kubernetes.github.io/ingress-nginx/) to serve ADS ingresses as url rewriting is needed which is not supported by AWS Ingress Controller.   
You should review this AWS [blog](https://aws.amazon.com/blogs/containers/exposing-kubernetes-applications-part-3-nginx-ingress-controller/) that will guide you through nginx Ingress Controller installation used in conjunction with AWS NLB.
For information, you should use nginx Ingress Controller Helm chart with a `values.yaml` file like:
```yaml
controller:
  service:
    type: LoadBalancer
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-name: nginx-ingress
      service.beta.kubernetes.io/aws-load-balancer-type: external
      service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
      service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: ip
      service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:<region>:XXXXXXXX:certificate/XXXXXX-XXXXXXX-XXXXXXX-XXXXXXXX
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: https
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: ssl
```

Then you'll use [ads-generate-ingresses.sh](../scripts/ads-generate-ingresses.sh) script to obtain the ingresses definition you'll have to apply to your cluster.

## Special network configuration
Depending on how the network was configured, the communication between the kube-api server and worker nodes can be restricted, causing errors during webhook invocations as shown in the following example:
```
I0624 14:19:58.368935       1 waitToCreateCsCR.go:36] Webhook Server not ready, waiting for it to be ready : could not Create resource: Internal error occurred: failed calling webhook \"vcommonservice.kb.io\": failed to call webhook: Post \"https://ibm-common-service-operator-service.ads.svc:443/validate-operator-ibm-com-v3-commonservice?timeout=10s\": context deadline exceeded
```
To explicitly allow communications, customize and apply additional custom network [policies](./extended-netpols.yaml) into your cluster to unblock.
