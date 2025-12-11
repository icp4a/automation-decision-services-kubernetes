#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.32.0

ads_channel_previous_version="v24.0,v24.1" 

licensing_service_channel=v4.2
licensing_service_target_version="4.2.15"
ibm_cert_manager_channel_on_cncf=v4.2
redhat_cert_manager_channel_on_ocp=stable-v1
ads_channel=v25.1
common_services_version=4.15.0 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.6.2" # Minimal supported Common Service version before upgrading from 25.0.1 (version from 24.0.0)
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 25.0.1

cs_minimal_version_for_ifix="4.12.0" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:5c5fda8dc9958f1420ccccb4872c58fd6639d5f2c70694c06eb14f59816a4be8" # IBM License Manager 4.2.15 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.15
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:85690858394aa8104e4452bead01b5648495c9930a237f9ee953064ddd1151fb" # IBM Certificate Manager 4.2.15 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.15

cs_catalog_image="icr.io/cpopen/ibm-cs-install-catalog@sha256:5cc26a852fcb17f407e922175437494538934c7615001b49bec69a723a164c52" # IBM Cloud Foundational Services 4.15.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-install/4.15.0/OLM/catalog-sources.yaml
cs_im_catalog_image="icr.io/cpopen/ibm-iam-operator-catalog@sha256:f4a0ab61ec7266ada01c52956988872ac32b54984ce39625b2c02f9d246cb596" # IBM CS IM Operator Catalog 4.14.0 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-cs-iam/4.14.0/OLM/catalog-sources.yaml
zen_catalog_image="icr.io/cpopen/ibm-zen-operator-catalog@sha256:3649e630c48377b19606e28dbfe7955d87e652a4a3927bf258746b16cfea1297" # IBM Zen Operator Catalog 6.2.2+20251021.102826.45 from https://github.com/IBM/cloud-pak/blob/master/repo/case/ibm-zen/6.2.2%2B20251021.102826.45/OLM/catalog-sources.yaml
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:2219a07d273b498fe54c8e384fbfb10700e0fa89adac5ef2877b39408252cf92" # 25.0.1
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:4b7cf401006cd4d4060a664c8313b3690916746d0df40bd96c9e592f6aba541f" # Cloud Native PostgresSQL Version 1.25.2 (CASE 5.16.0+20250722.134758.2626)
