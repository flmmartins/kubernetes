variable "chart_version" {
  description = "CSI Driver NFS Chart Version"
  default     = "4.12.1"
}

variable "labels" {
  description = "Labels to apply to all resources created by the CSI Driver NFS module"
  type        = map(string)
  default     = {}
}

variable "server" {
  description = "NFS Server IP or hostname"
  type        = string
}

variable "folder" {
  description = "NFS Folder"
  type        = string
}