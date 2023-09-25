# Confluent Provider Configuration
terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.51.0"
    }
  }
}

# Option #1 when managing multiple clusters in the same Terraform workspace
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key    # optionally use CONFLUENT_CLOUD_API_KEY env var
  cloud_api_secret = var.confluent_cloud_api_secret # optionally use CONFLUENT_CLOUD_API_SECRET env var
}

data "confluent_environment" "environment" {
  display_name = var.environment_name
}

# resource "confluent_environment" "environment" {
#   display_name = var.environment_name

# ## PARA EVITAR BORRADO ACCIENTAL DEL RECURSO
#   lifecycle {
#     prevent_destroy = true
#   }
# }

resource "confluent_kafka_cluster" "kafka-cluster" {
  display_name = var.kafka_cluster_name
  availability = "SINGLE_ZONE"
  cloud        = "GCP"
  region       = "europe-west2"
  standard {}

  environment {
    # id = data.confluent_environment.environment.id
    id = "env-zg2ok3"
  }

## PARA EVITAR BORRADO ACCIENTAL DEL RECURSO
  # lifecycle {
  #   prevent_destroy = true
  # }
}

#######
# CREACION DE USUARIO "OWNER" DEL CLUSTER PARA GESTIONAR LAS APLICACIONES DEL CLUSTER Y NO UTILIZAR UN USUARIO CON OrganizationAdmin
resource "confluent_service_account" "kafka-cluster-sa" {
  display_name = "${confluent_kafka_cluster.kafka-cluster.display_name}-cluster-sa"
  description  = "${confluent_kafka_cluster.kafka-cluster.display_name} Cluster Owner Service account"
}

# ROLE-BINDING DEL EL TOPIC PARA EL USUARIO OWNER
# Ver. https://docs.confluent.io/cloud/current/access-management/access-control/cloud-rbac.html#ccloud-rbac-roles
# DeveloperRead / DeveloperWrite / DeveloperManage / ResourceOwner
resource "confluent_role_binding" "kafka-cluster-sa-admin-rbac" {
  principal   = "User:${confluent_service_account.kafka-cluster-sa.id}"
  role_name   = "CloudClusterAdmin"  
  crn_pattern = confluent_kafka_cluster.kafka-cluster.rbac_crn
}

# API-KEY DEL OWNER. SI YA EXISTE SE PUEDE AGREGAR COMO VARIABLE, LAS API-KEYS NO TIENEN DATASOURCE
resource "confluent_api_key" "kafka-cluster-sa-api-key" {
  display_name = "kafka-cluster-sa-api-key"
  description  = "Kafka API Key that is owned by '${confluent_service_account.kafka-cluster-sa.display_name}' service account"
  owner {
    id          = confluent_service_account.kafka-cluster-sa.id
    api_version = confluent_service_account.kafka-cluster-sa.api_version
    kind        = confluent_service_account.kafka-cluster-sa.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.kafka-cluster.id
    api_version = confluent_kafka_cluster.kafka-cluster.api_version
    kind        = confluent_kafka_cluster.kafka-cluster.kind

    environment {
      id = data.confluent_environment.environment.id
    }
  }
}