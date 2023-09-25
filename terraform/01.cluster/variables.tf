variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID)"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "environment_name" {
  description = "Environment Name"
  type        = string
  sensitive   = false
}

variable "kafka_cluster_name" {
  description = "Cluster Name"
  type        = string
  sensitive   = false
}