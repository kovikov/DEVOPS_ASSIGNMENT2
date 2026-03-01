output "vpc_id" {
  description = "ID of lamp-vpc"
  value       = aws_vpc.lamp_vpc.id
}

output "public_subnet_id" {
  description = "ID of lamp-public-subnet"
  value       = aws_subnet.lamp_public_subnet.id
}

output "private_subnet_id" {
  description = "ID of lamp-private-subnet"
  value       = aws_subnet.lamp_private_subnet.id
}

output "internet_gateway_id" {
  description = "ID of lamp-igw"
  value       = aws_internet_gateway.lamp_igw.id
}

output "public_route_table_id" {
  description = "ID of lamp-public-rt"
  value       = aws_route_table.lamp_public_rt.id
}

output "private_route_table_id" {
  description = "ID of lamp-private-rt"
  value       = aws_route_table.lamp_private_rt.id
}

output "web_security_group_id" {
  description = "ID of lamp-web-sg"
  value       = aws_security_group.lamp_web_sg.id
}

output "db_security_group_id" {
  description = "ID of lamp-db-sg"
  value       = aws_security_group.lamp_db_sg.id
}

output "key_pair_name" {
  description = "Name of created EC2 key pair"
  value       = aws_key_pair.lamp_key.key_name
}

output "web_server_instance_id" {
  description = "Instance ID of lamp-web-server"
  value       = aws_instance.lamp_web_server.id
}

output "web_server_public_ip" {
  description = "Public IP of lamp-web-server"
  value       = aws_instance.lamp_web_server.public_ip
}

output "db_server_instance_id" {
  description = "Instance ID of lamp-db-server"
  value       = aws_instance.lamp_db_server.id
}

output "db_server_private_ip" {
  description = "Private IP of lamp-db-server"
  value       = aws_instance.lamp_db_server.private_ip
}

output "app_container_name" {
  description = "Container name running on web server"
  value       = var.app_container_name
}

output "web_server_healthcheck_hint" {
  description = "Run this on the web server to verify app health"
  value       = "curl http://localhost:${var.app_host_port}/health"
}

output "public_app_url" {
  description = "Public URL served by NGINX reverse proxy"
  value       = "http://${aws_instance.lamp_web_server.public_ip}"
}

output "public_health_url" {
  description = "Public health endpoint via NGINX"
  value       = "http://${aws_instance.lamp_web_server.public_ip}/health"
}
