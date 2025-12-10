# Returns the public IP of the first (or only) EC2 instance
output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.example[0].public_ip
}

# All instance public IPs (if you ever scale)
output "instance_public_ips" {
  description = "List of public IPs of all EC2 instances"
  value       = aws_instance.example[*].public_ip
}

output "instance_ids" {
  description = "IDs of the created EC2 instances"
  value       = aws_instance.example[*].id
}

output "instance_private_ips" {
  description = "Private IPs of the created EC2 instances"
  value       = aws_instance.example[*].private_ip
}

output "security_group_id" {
  description = "Security group created for SSH access"
  value       = aws_security_group.ssh.id
}

output "grafana_url" {
  description = "URL to access Grafana (admin/admin)"
  value       = "http://${aws_instance.example[0].public_ip}:3000"
}

output "prometheus_url" {
  description = "URL to access Prometheus"
  value       = "http://${aws_instance.example[0].public_ip}:9090"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i /path/to/master-key.pem ubuntu@${aws_instance.example[0].public_ip}"
}
