#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v24.0

licensing_service_channel=v4.2
licensing_service_target_version="4.2.8"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.8"
ads_channel=v24.1
common_services_version=4.9.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 24.0.0
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 24.0.0

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:a4c1121894a0fadd0f62415fdfe381bd92ac8afb9314539c8770c88c006ebd42" # IBM License Manager 4.2.8 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.8
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:6268cedf6759cf544560d9f652974c14f293858c53bf747b145b4522d39701bb" # IBM Certificate Manager 4.2.8 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.8

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:6dec61b65e1414fadce180ce9e9aeba82dd2e393085cb3cadc1a6e271cefe50a" # IBM Cloud Foundational Services 4.9.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.9.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:28685c8ebc72df046e883ca37c379ea11b4e6e14c9dd7c8da2c91b3cf1b57816" # IBM CS IM Operator Catalog 4.8.0
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:9ce549fe51c21f584ad1e37fb09f0931018b48e4081af43bdff85d8dedfa8d65" # IBM Zen Operator Catalog 6.0.4+20240916.202115.96
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:0656cc7ba5b6ccab1a82f3bfb989df73a04c2ce1849e232fcb5fa2f215e77b91" # 24.0.1
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:d6b5e43f3b5c4e4198ed6ddfd4577eebea644df9d2fe2bac33600764b5cda631" # Cloud Native PostgresSQL 1.22.5 (CASE 4.29.0+20240829.203322.1920) from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.29.0%2B20240829.203322.1920

