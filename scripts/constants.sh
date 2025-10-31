#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version="v24.0,v24.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.15"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.15"
ads_channel=v25.0
common_services_version=4.14.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 25.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 25.0.0

cs_minimal_version_for_ifix="4.12.0" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:5c5fda8dc9958f1420ccccb4872c58fd6639d5f2c70694c06eb14f59816a4be8" # IBM License Manager 4.2.15 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.15
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:85690858394aa8104e4452bead01b5648495c9930a237f9ee953064ddd1151fb" # IBM Certificate Manager 4.2.15 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.15

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:05e8a09eb13ae69563db7b41eff543ebcd618f540dc90f5ed13b69d75846086a" # IBM Cloud Foundational Services 4.14.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.14.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:64d8300c54590926e09f663de2af68de393cc7c86266d9e7be9af6e62acecdb9" # IBM CS IM Operator Catalog 4.13.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.13.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:0b92ad1b0d12f06d89e34f9e0b6e5b4359614ef173501decc74758213cd5f11d" # IBM Zen Operator Catalog 6.2.1+20250818.110231.113 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.2.1%2B20250818.110231.113/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:d0cbb45b37a5aa91524f4b35c143b7f6b892081ba1f194012a21f5475cc5cbb1" # 25.0.0-IF002
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:4b7cf401006cd4d4060a664c8313b3690916746d0df40bd96c9e592f6aba541f" # Cloud Native PostgresSQL Version 1.25.2 (CASE 5.16.0+20250722.134758.2626)
