variable "vpc" {
  description = "VPC ID to use"
  type        = string
  default     = "vpc-012814271f30b4442"
}

variable "public_subnet" {
  description = "Public Subnet ID to use"
  type        = string
  default     = "subnet-079049edc56a73fc3"
}

variable "private_subnet" {
  description = "Private Subnet ID to use"
  type        = string
  default     = "subnet-034d8630d129a1fb4"
}

variable "private_subnet2" {
  description = "Private Subnet ID to use"
  type        = string
  default     = "subnet-08075f7fa3627e3ad"
}

variable "instance_type" {
  description = "Instance type to use"
  type = string
  default = "t2.micro"
}

variable "keypair" {
  description = "Keypair name to use"
  type        = string
  default     = "ky_keypair"
}

variable "username" {
  description = "username for secret key"
  type = string
  default = "admin"
}

variable "password" {
  description = "password for secret key"
  type = string
  default = "password123"
}