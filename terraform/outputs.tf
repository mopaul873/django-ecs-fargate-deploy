output "app_url" {
  description = "Public URL of the application"
  value       = var.certificate_arn != "" && var.domain_name != "" ? "https://${var.domain_name}" : "http://${aws_lb.main.dns_name}"
}

output "alb_dns_name" {
  description = "Point your domain's CNAME/alias record here"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "ecr_repository_name" {
  value = aws_ecr_repository.app.name
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "ecs_task_family" {
  value = aws_ecs_task_definition.app.family
}

output "container_name" {
  value = local.container_name
}

output "github_actions_role_arn" {
  description = "Put this in the GitHub repo variable AWS_ROLE_ARN"
  value       = aws_iam_role.github_actions.arn
}

output "rds_endpoint" {
  value = aws_db_instance.main.address
}

output "log_group" {
  value = aws_cloudwatch_log_group.app.name
}
