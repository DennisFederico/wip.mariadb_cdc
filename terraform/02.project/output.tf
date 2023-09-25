output "topics" {
  value       = confluent_kafka_topic.topics[*].topic_name
  description = "Created Topics"
}

output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${data.confluent_environment.environment.display_name} (${data.confluent_environment.environment.id})
  Kafka Cluster ID: ${data.confluent_kafka_cluster.kafka-cluster.display_name} (${data.confluent_kafka_cluster.kafka-cluster.id})
  Kafka Bootstrap: '${data.confluent_kafka_cluster.kafka-cluster.bootstrap_endpoint}'
  Application: ${var.application_name}
  Service Account: ${confluent_service_account.application-sa.display_name} (${confluent_service_account.application-sa.id})
  ${confluent_service_account.application-sa.display_name}'s Kafka API Key:     "${confluent_api_key.application-sa-kafka-api-key.id}"
  ${confluent_service_account.application-sa.display_name}'s Kafka API Secret:  "${nonsensitive(confluent_api_key.application-sa-kafka-api-key.secret)}"
  ---
  In order to use the Confluent CLI v2 to produce and consume messages from topic '${var.topics[0]}' using Kafka API Keys of ${confluent_service_account.application-sa.display_name} service account
  run the following commands:
  # 1. Log in to Confluent Cloud
  $ confluent login
  
  # 2. Produce key-value records to topic '${var.topics[0]}':
  $ confluent kafka topic produce ${var.topics[0]} --environment ${data.confluent_environment.environment.id} --cluster ${data.confluent_kafka_cluster.kafka-cluster.id} \
    --api-key "${confluent_api_key.application-sa-kafka-api-key.id}" --api-secret "${nonsensitive(confluent_api_key.application-sa-kafka-api-key.secret)}"
  # Enter a few records and then press 'Ctrl-C' when you're done.  
  # Sample records:
  # {"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","cost":15.00}
  # {"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","cost":5.00}
  # {"number":3,"date":18502,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","cost":10.00}
    
  # 3. Consume records from topic '${var.topics[0]}':
  $ confluent kafka topic consume ${var.topics[0]} --from-beginning --environment ${data.confluent_environment.environment.id} --cluster ${data.confluent_kafka_cluster.kafka-cluster.id} \
    --api-key "${confluent_api_key.application-sa-kafka-api-key.id}" --api-secret "${nonsensitive(confluent_api_key.application-sa-kafka-api-key.secret)}"
  # When you are done, press 'Ctrl-C'.
  EOT

  sensitive = false
}
