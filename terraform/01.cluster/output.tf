output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${data.confluent_environment.environment.id}  
  Kafka Cluster ID: ${confluent_kafka_cluster.kafka-cluster.id}
  Kafka Cluster Bootstrap Servers: ${confluent_kafka_cluster.kafka-cluster.bootstrap_endpoint}

  Cluster Service Accounts and their Kafka API Keys:
  ${confluent_service_account.kafka-cluster-sa.display_name}:                     ${confluent_service_account.kafka-cluster-sa.id}
  ${confluent_service_account.kafka-cluster-sa.display_name}'s Kafka API Key:     "${confluent_api_key.kafka-cluster-sa-api-key.id}"
  ${confluent_service_account.kafka-cluster-sa.display_name}'s Kafka API Secret:  "${nonsensitive(confluent_api_key.kafka-cluster-sa-api-key.secret)}"
  EOT
  sensitive = false
}

