# EKS specific resources

This directory contains resources specific to Amazon Elastic Kubernetes Service (EKS), such as sample [ingresses](ingress.yaml) with AWS Application Load Balancer (ALB) templates.   

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

## Ingress and Application Load Balancer

You must deploy the AWS Load Balancer Controller in your cluster to use Ingress.  
Check the AWS Load Balancer Controller [documentation](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) before you proceed.  

Then, use a x509 certificate with a distinguished name that matches your `.subdomain.my-company.com` name, which is presented by your Ingresses.  
You can generate an untrusted certificate for testing purpose by using the following command:

```shell
openssl req -x509 -nodes -days 1000 -newkey rsa:2048 -keyout subdomain.key -out subdomain.crt -subj "/CN=*.subdomain.my-company.com/OU=it/O=<your-org>/L=<your-location>/C=<your-country>>"
```

and then, upload it to AWS Certificate Manager by using the following command:

```shell
aws acm import-certificate --certificate fileb:///tmp/subdomain.crt --private-key fileb:///tmp/subdomain.key
```

This command returns the Amazon Resource Name (ARN) of the registered certificate that you can reference in the `alb.ingress.kubernetes.io/certificate-arn` annotation on your Ingress descriptor.

Then, create a wildcard DNS entry in your domain that corresponds to the domain declared
in the `ibm-cpp-config` ConfigMap and your Ingresses.  

If the DNS zone is managed by AWS, create an _alias_ A record to the ALB.  (ALB IP addresses change over time. Therefore, a static A record is not applicable and becomes invalid soon).  For DNS zones that are not managed by AWS, a CNAME entry to the ALB automatic hostname is probably usable.
