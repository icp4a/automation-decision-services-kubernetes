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

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:5a67decdd3513fefd99e165cc6cb2798937d42031230819f6d5b4fa54a5f28c1" # IBM License Manager 4.2.11 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.11
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:1c9e4a2a2abddfcdcb95898f14aecd3ab9e59bd388fb38de335118d1c36651e3" # IBM Certificate Manager 4.2.11 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.11

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:470042a694cbf29be89107acb702f84ade88c0bbdeb900b8e0833602fb7eda69" # IBM Cloud Foundational Services 4.10.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.10.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:250b994930c96151d1688017c3622f33278b1f8d636323fa7660b3927f2cf47c" # IBM CS IM Operator Catalog 4.9.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.9.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:6fe8ccd964fc6a008d3479b81876ea7d57b58e0ea3c4e9a7d62e3c18b3793ce6" # IBM Zen Operator Catalog 6.1.0+20241120.004836.207 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.1.0%2B20241120.004836.207/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:297c3650de87783b2ea291c49b1dfb8780e5a6785f161d366de5e7f21a18bcc7" # 24.0.1-IF004
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:3b867e7e0879ec24b5058e5db01c0a9be8d9d8d5ef2b7bb1bb7e247babb8b96d" # Cloud Native PostgresSQL 1.22.7 (CASE 4.30.0+20241023.165233.2074) from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cloud-native-postgresql/4.30.0%2B20241023.165233.2074/OLM/catalog-sources.yaml

