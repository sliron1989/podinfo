variable "name" {
  description = "Application name, used for all resource naming and routing"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace to deploy into"
  type        = string
  default     = "default"
}

variable "image" {
  description = "Container image to deploy"
  type        = string
  default     = "nginxdemos/hello:plain-text"
}

variable "replicas" {
  description = "Number of pod replicas"
  type        = number
  default     = 2
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 80
}

variable "hostname" {
  description = "Hostname for ingress routing (e.g., app1.local)"
  type        = string
}

variable "ingress_class" {
  description = "Ingress class name to use"
  type        = string
  default     = "nginx"
}
