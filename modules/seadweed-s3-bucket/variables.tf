variable "provider_api" {
  description = "S3 Provider url"
  default     = "seaweed.seaweedfs.com/v1"
}

variable "seaweedfs" {
  description = "Name of seaweedfs cluster and namespace"
  type = object({
    cluster_name = string
    namespace    = string
  })
}

variable "application" {
  description = "Name and namespace of the application allowed to interact with bucket"
  type = object({
    name      = string
    namespace = string
  })
}
