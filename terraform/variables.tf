variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for all resources"
  type        = string
  default     = "media-analytics"
}

variable "environment" {
  description = "Environment name (prod, staging, dev)"
  type        = string
  default     = "prod"
}

# ---------- Networking ----------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnets (ALB, NAT gateway) - one per AZ"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnets (ECS tasks, RDS) - one per AZ"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

# ---------- Application / ECS ----------
variable "container_port" {
  description = "Port gunicorn listens on inside the container"
  type        = number
  default     = 8000
}

variable "image_tag" {
  description = "Image tag used for the FIRST deployment only. After that GitHub Actions deploys new tags."
  type        = string
  default     = "initial"
}

variable "task_cpu" {
  description = "Fargate task CPU units (256, 512, 1024, ...)"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "desired_count" {
  description = "Number of tasks to start with (autoscaling adjusts it after that)"
  type        = number
  default     = 2
}

variable "min_capacity" {
  description = "Minimum number of tasks for autoscaling"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of tasks for autoscaling (handles traffic spikes)"
  type        = number
  default     = 10
}

variable "domain_name" {
  description = "Optional custom domain (e.g. dashboards.example.com). Leave empty to use the ALB DNS name."
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN. If set, the ALB serves HTTPS and redirects HTTP to HTTPS."
  type        = string
  default     = ""
}

# ---------- Database ----------
variable "db_instance_class" {
  description = "RDS instance size"
  type        = string
  default     = "db.t4g.micro"
}

variable "db_allocated_storage" {
  description = "RDS storage in GB"
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Run RDS in Multi-AZ mode (recommended for production)"
  type        = bool
  default     = true
}

variable "db_deletion_protection" {
  description = "Protect the database from accidental deletion"
  type        = bool
  default     = true
}

# ---------- CI/CD ----------
variable "github_repo" {
  description = "GitHub repository allowed to deploy, in owner/repo format"
  type        = string
}

variable "create_github_oidc_provider" {
  description = "Set to false if the GitHub OIDC provider already exists in this AWS account"
  type        = bool
  default     = true
}

# ---------- Monitoring ----------
variable "alarm_email" {
  description = "Optional email for CloudWatch alarm notifications"
  type        = string
  default     = ""
}
