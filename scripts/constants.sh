#!/usr/bin/env bash

olm_minimal_version=v0.23.1
olm_version=v0.26.0

ads_channel_previous_version=v23.1

licensing_service_channel=v4.2
licensing_service_target_version="4.2.2"
cert_manager_channel=v4.2
cert_manager_target_version="4.2.2"
ads_channel=v23.2
common_services_channel=v4.4

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:dfdd38cac150cd354853ac88d02396a9457d22964f898d10126b4a880b4d0916" # IBM License Manager 4.2.2 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.2
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:955732299dd174524612ec8e8076237a491cedee1264e4e4be39c2a92f48bc39" # IBM Certificate Manager 4.2.2 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.2



cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:e639ec5b8bfc542ef13f8d615fecb8f70ace9231ef8210ad0eb68826e8cecdf3" # IBM Cloud Foundational Services 4.4 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-common-services/4.4.0
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:0cc1146b01abaa79bb1a09ffab747d84d110c360dd7c2437ffd5c31fe374681c" # 23.0.2-IF003
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:c96aa2e6bce92f2e5e4874116cf1cc1cdd60676499cd04ab1631462b8b883357" # Cloud Native PostgresSQL 4.18.0 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.18.0