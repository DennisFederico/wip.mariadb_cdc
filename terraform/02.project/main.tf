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

data "confluent_kafka_cluster" "kafka-cluster" {
  display_name = var.kafka_cluster_name

  environment {
    id = data.confluent_environment.environment.id
  }
}

resource "confluent_kafka_topic" "topics" {
  count = length(var.topics)
  
  kafka_cluster {
    id = data.confluent_kafka_cluster.kafka-cluster.id
  }
  rest_endpoint = data.confluent_kafka_cluster.kafka-cluster.rest_endpoint

  topic_name         = var.topics[count.index]
  partitions_count   = var.topics_partition

  # Optional topic configuration - This cannot be updated later
  # config = {
  #   "retention.hours"      = "72"
  # }

  depends_on = [
    data.confluent_kafka_cluster.kafka-cluster
  ]

  credentials {
    key    = var.cluster_owner_api_key
    secret = var.cluster_owner_api_secret
  }
}

# CREACION DEL USUARIO DE SERVICIO DE LA APLICACION CON PERMISO LECTURA/ESCRITURA
resource "confluent_service_account" "application-sa" {
  display_name = "${var.application_name}-sa"
  description  = "Service account for the application '${var.application_name}'"
}

# ASSIGN ROLES TO THE APPLICATION SA (PER TOPIC)
resource "confluent_role_binding" "application-sa-read" {
  count = length(var.topics)
  principal   = "User:${confluent_service_account.application-sa.id}"
  role_name   = "DeveloperRead"
  crn_pattern = "${data.confluent_kafka_cluster.kafka-cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.kafka-cluster.id}/topic=${var.topics[count.index]}"
}

resource "confluent_role_binding" "application-sa-write" {
  count = length(var.topics)
  principal   = "User:${confluent_service_account.application-sa.id}"
  role_name   = "DeveloperWrite"
  crn_pattern = "${data.confluent_kafka_cluster.kafka-cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.kafka-cluster.id}/topic=${var.topics[count.index]}"
}

## PERMISO PARA CONSUMER GROUP
resource "confluent_role_binding" "application-sa-consumer" {
  principal   = "User:${confluent_service_account.application-sa.id}"
  role_name   = "DeveloperRead"
  # EN ESTE CRN SE UTILIZA EL PREFIJO DEL CONSUMER_GROUP, LAS APLICACIONES SE DEBEN AJUSTAR ACORDE
  crn_pattern = "${data.confluent_kafka_cluster.kafka-cluster.rbac_crn}/kafka=${data.confluent_kafka_cluster.kafka-cluster.id}/group=${var.application_name}-cg_*"
}

## API-KEY USUARIO APLICACION
resource "confluent_api_key" "application-sa-kafka-api-key" {
  display_name = "${var.application_name}-sa kafka-api-key"
  description  = "Kafka API Key that is owned by '${var.application_name}-sa' service account"
  owner {
    id          = confluent_service_account.application-sa.id
    api_version = confluent_service_account.application-sa.api_version
    kind        = confluent_service_account.application-sa.kind
  }

  managed_resource {
    id          = data.confluent_kafka_cluster.kafka-cluster.id
    api_version = data.confluent_kafka_cluster.kafka-cluster.api_version
    kind        = data.confluent_kafka_cluster.kafka-cluster.kind

    environment {
      id = data.confluent_environment.environment.id
    }
  }

  # meta that helps set a creation/destroy order
  depends_on = [
    confluent_service_account.application-sa,
    confluent_role_binding.application-sa-read,
    confluent_role_binding.application-sa-write,
    confluent_role_binding.application-sa-consumer
  ]
}

# resource "confluent_connector" "datagen" {
#   environment {
#     id = data.confluent_environment.environment.id
#   }
#   kafka_cluster {
#     id = data.confluent_kafka_cluster.kafka-cluster.id
#   }

#   config_sensitive = {}

#   config_nonsensitive = {
#     "connector.class"          = "DatagenSource"
#     "name"                     = "DatagenSourceConnector_0"
#     "kafka.auth.mode"          = "SERVICE_ACCOUNT"
#     "kafka.service.account.id" = confluent_service_account.app-connector.id
#     "kafka.topic"              = confluent_kafka_topic.orders.topic_name
#     "output.data.format"       = "JSON"
#     "quickstart"               = "ORDERS"
#     "tasks.max"                = "1"
#   }

#   depends_on = [
#     confluent_kafka_acl.app-connector-describe-on-cluster,
#     confluent_kafka_acl.app-connector-write-on-target-topic,
#     confluent_kafka_acl.app-connector-create-on-data-preview-topics,
#     confluent_kafka_acl.app-connector-write-on-data-preview-topics,
#   ]

#   lifecycle {
#     prevent_destroy = true
#   }
# }

