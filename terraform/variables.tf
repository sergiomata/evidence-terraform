variable "serviceName"{
        type ="string"
        default ="evidences"
}
variable"environment"{
        type = "string"
        default = "production"
}
variable "input_sg_port"{
  description = "Port exposed to redirect inbound traffic to"
  default     = 4000
}

variable "output_sg_port"{
  description = "Port exposed to redirect inbound traffic to"
  default     = 4000
}

variable "subnets_cidr" {
	type = "list"
	default = ["10.0.0.0/26"]
}

variable "availability_zones" {
	type = "list"
	default = ["us-east-1a", "us-east-1b"]
}

variable "subnet_public_number"{
  description = "number of public subnets"
  default     = 2
}