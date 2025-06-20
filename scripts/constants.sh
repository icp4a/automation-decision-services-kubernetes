#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version="v24.0,v24.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.13"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.13"
ads_channel=v25.0
common_services_version=4.12.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 25.0.0 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 25.0.0

cs_minimal_version_for_ifix="4.12.0" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:17980ccacb1aeae19729e7d5129ad0b69e0f18a2c30f9f1a0db1daf9ae7c2e92" # IBM License Manager 4.2.13 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.13
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:21866a45719eef50764c421c349a539262147d215ef87c8cc2174fdf2c269346" # IBM Certificate Manager 4.2.13 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.13

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:d4dff1a8968c18d984e16c4c9f1517c3a10e23a11bf166c64d734773324d4c9d" # IBM Cloud Foundational Services 4.12.0 from hhttps://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.12.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:f289ac0d44803ff12d41c3659e6fdf04c404e0b3b233b6bc44eec671abb1b47e" # IBM CS IM Operator Catalog 4.11.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.11.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:209ea4b77b3b0863c591bcdec6f53c4c39dafcb10ff13e27ae4e1cb986a59727" # IBM Zen Operator Catalog 6.1.3+20250416.164817.22 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.1.3%2B20250416.164817.22/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:69c934a86cdc17067d291bc6114fc6a1dc0dc72615e173536f4a13184ae5f708" # 25.0.0
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:7dbff355db7739152961cb6a97887d2e43bc960ac58837c126e03ed1a4480a3a" # Cloud Native PostgresSQL Version 1.25.1 (CASE 5.15.0+20250416.103820.2490)
