#!/usr/bin/env bash
ads_channel_previous_version=v23.1
common_services_previous_version=v4.0.0

ads_channel=v23.2
common_services_channel=v4.2

licensing_catalog_image="icr.io/cpopen/ibm-licensing-catalog@sha256:210a452d30aa6f996fee80fb35fea0ca7d709fe3c589fb6eaa79ceb0b24a6a4c" # IBM License Manager 4.2.0 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-licensing/4.2.0
cert_manager_catalog_image="icr.io/cpopen/ibm-cert-manager-operator-catalog@sha256:95da3736d298d2ac824afd8587b98728e48b0e7270b9304f4e3c76b65f9b8b98" # IBM Certificate Manager 4.2.0 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cert-manager/4.2.0

cs_catalog_image="icr.io/cpopen/ibm-common-service-catalog@sha256:ef9b76c30ff282d720f9d502a7001164a3f5c62f91843eb56d11da87abea6c1e" # IBM Cloud Foundational Services 4.2 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cp-common-services/4.2.0
ads_catalog_image="icr.io/cpopen/ibm-ads-operator-catalog@sha256:ad1fea86b83c3c3282d472d1ae16c5734a7191ad62e1ac2862344a1cac3e138b" # 23.0.2
edb_catalog_image="icr.io/cpopen/ibm-cpd-cloud-native-postgresql-operator-catalog@sha256:a06b9c054e58e089652f0e4400178c4a1b685255de9789b80fe5d5f526f9e732" # Cloud Native PostgresSQL 4.14.0+20230619 from https://github.com/IBM/cloud-pak/tree/master/repo/case/ibm-cloud-native-postgresql/4.14.0%2B20230616.111503
