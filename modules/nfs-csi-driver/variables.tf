

variable "labels" {
  description = "Labels for components"
  default     = {}
}

variable "ca_cert_file" {
  description = "NFS Share for CSI NFS"
  type = object({
    ip           = string
    share_folder = string
    group_uid    = number
  })
}

variable "ip" {
  description = "IP of NFS Share"
  type        = string
}

variable "share_folder" {
  description = "IP of NFS Share"
  type        = string
}