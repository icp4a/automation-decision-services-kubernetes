#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.27.0

ads_channel_previous_version=v23.2

licensing_service_channel=v4.2
licensing_service_target_version="4.2.8"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.8"
ads_channel=v24.0
common_services_version=4.6.6 # Common Service version to install

licensing_service_minimal_version_for_upgrade="4.2.0"
cert_manager_minimal_version_for_upgrade="4.2.0"

cs_minimal_version_for_upgrade="4.2.0" # Minimal supported Common Service version before upgrading from 23.0.2
cs_maximal_version_for_upgrade="5.0.0" # Maximal supported Common Service version before upgrading from 23.0.2

cs_minimal_version_for_ifix="4.6.2" # Minimal supported Common Service version before upgrading for ifix
cs_maximal_version_for_ifix="5.0.0" # Maximal supported Common Service version before upgrading for ifix

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:a4c1121894a0fadd0f62415fdfe381bd92ac8afb9314539c8770c88c006ebd42" # IBM License Manager 4.2.8 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.8
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:6268cedf6759cf544560d9f652974c14f293858c53bf747b145b4522d39701bb" # IBM Certificate Manager 4.2.8 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.8

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:e54ec8842dc8b694703c57b4d0254f75ed574d7116f34d358803d6b5a771c310" # IBM Cloud Foundational Services 4.6.6 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-common-services/4.6.6
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:3840248cd6a00254f633c96979f80d748ab233e4741240a110009552e840046a" # 24.0.0-IF004
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:0b46a3ec66622dd4a96d96243602a21d7a29cd854f67a876ad745ec524337a1f" # Cloud Native PostgresSQL 1.18.12 (4.25.0) from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.25.0

