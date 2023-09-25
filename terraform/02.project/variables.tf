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

variable "cluster_owner_api_key" {
  description = "CloudClusterOwner API Key"
  type        = string
  sensitive   = true
}

variable "cluster_owner_api_secret" {
  description = "CloudClusterOwner API Secret"
  type        = string
  sensitive   = true
}

variable "application_name" {
  description = "Application Name"
  type        = string
  sensitive   = false
}

variable "topics" {
  description = "List of topics to create"
  type        = list(string)
  sensitive   = false  
}

variable "topics_partition" {
  description = "Topics Partition"
  default = 6
}