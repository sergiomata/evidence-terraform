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