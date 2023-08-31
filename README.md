 # Automation Decision Services installation scripts and samples

You can use scripts and samples that are provided in this repository to install Automation Decision Services.

This repository has several branches. Refer to the one that corresponds to your version. The master branch contains the content for the latest version.
        
There are four main directories:

- **Scripts**: Scripts for installing Automation Decision Services.
- **Descriptors**: Sample YAML files for minimum custom resources (CR) and fully customized CR.
- **EKS**: Resources that are specific to Amazon Elastic Kubernetes Service (EKS).
- **Airgap**: Resources that are used for an air gapped (offline) deployment.
- **Must-gather**: Instructions and scripts to gather information to diagnose issues.

### MustGather
        
The [must-gather](must-gather) folder contains instructions and scripts to gather information for diagnosing and analyzing issues.

In particular, the `gather.sh` script assembles a `tar.gz` archive from your cluster setup and from pod logs.  This archive can be sent to the IBM Support team for analysis.
