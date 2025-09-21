variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of your existing AWS key pair"
  default     = "your_key"  # <-- replace with your real key pair name
}

variable "allowed_cidr" {
  description = "Your IP/CIDR allowed for SSH"
  default     = "0.0.0.0/0" # ⚠️ replace with e.g. "203.0.113.25/32" for security
}
