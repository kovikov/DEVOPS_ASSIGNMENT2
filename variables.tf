variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Availability zone for both subnets"
  type        = string
  default     = "us-east-1a"
}

variable "my_ip_cidr" {
  description = "Your public IP in CIDR format for SSH access (example: 203.0.113.10/32)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for web and db servers"
  type        = string
  default     = "t2.micro"
}

variable "mysql_database" {
  description = "MySQL database name for the application"
  type        = string
  default     = "lampdb"
}

variable "mysql_app_user" {
  description = "MySQL username for the application"
  type        = string
  default     = "lampuser"
}

variable "mysql_app_host" {
  description = "Host pattern allowed for MySQL app user (web subnet range)"
  type        = string
  default     = "10.0.1.%"
}

variable "mysql_app_password" {
  description = "Strong password for MySQL application user"
  type        = string
  sensitive   = true
}

variable "docker_image" {
  description = "Docker image to run on web server (example: yourdockerhubusername/lamp-demo:latest)"
  type        = string
}

variable "app_container_name" {
  description = "Container name for the Flask app"
  type        = string
  default     = "lamp-app"
}

variable "app_host_port" {
  description = "Host port exposed for the Flask app container"
  type        = number
  default     = 5000
}

variable "app_container_port" {
  description = "Container port used by the Flask app"
  type        = number
  default     = 5000
}

variable "flask_env" {
  description = "FLASK_ENV value passed to the container"
  type        = string
  default     = "production"
}
