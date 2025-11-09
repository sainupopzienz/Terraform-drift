# AWS Config Monitoring Setup
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "notification_email" {
  description = "Email for notifications"
  type        = string
}

# Provider configuration
provider "aws" {
  region = var.aws_region
}

# SNS Topic for alerts
resource "aws_sns_topic" "config_alerts" {
  name = "aws-config-alerts"
}

# SNS Subscription
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.config_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

# S3 Bucket for Config
resource "aws_s3_bucket" "config_bucket" {
  bucket        = "aws-config-bucket-${random_string.suffix.result}"
  force_destroy = true
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSConfigBucketPermissionsCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketExistenceCheck"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:ListBucket"
        Resource = aws_s3_bucket.config_bucket.arn
      },
      {
        Sid    = "AWSConfigBucketDelivery"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.config_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# IAM Role for Config
resource "aws_iam_role" "config_role" {
  name = "aws-config-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "config_role_policy" {
  role       = aws_iam_role.config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# Config Delivery Channel
resource "aws_config_delivery_channel" "main" {
  name           = "main-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

# Config Configuration Recorder
resource "aws_config_configuration_recorder" "main" {
  name     = "main-recorder"
  role_arn = aws_iam_role.config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# EventBridge Rule for Config Changes
resource "aws_cloudwatch_event_rule" "config_changes" {
  name = "aws-config-changes"
  event_pattern = jsonencode({
    source      = ["aws.config"]
    detail-type = ["Config Configuration Item Change"]
    detail = {
      configurationItemStatus = ["ResourceDiscovered", "ResourceDeleted", "ResourceDeletedNotRecorded"]
    }
  })
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "sns_target" {
  rule      = aws_cloudwatch_event_rule.config_changes.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.config_alerts.arn

  input_transformer {
    input_paths = {
      resource = "$.detail.resourceType"
      account  = "$.account"
      region   = "$.region"
      time     = "$.time"
      status   = "$.detail.configurationItemStatus"
      id       = "$.detail.resourceId"
    }
    input_template = "\"ALERT: AWS Resource Change Detected\\n\\nResource Type: <resource>\\nResource ID: <id>\\nStatus: <status>\\nAccount: <account>\\nRegion: <region>\\nTime: <time>\\n\\nThis change was made outside of Terraform. Please investigate.\""
  }
}

# SNS Topic Policy
resource "aws_sns_topic_policy" "config_alerts_policy" {
  arn = aws_sns_topic.config_alerts.arn
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
        Action   = "SNS:Publish"
        Resource = aws_sns_topic.config_alerts.arn
      }
    ]
  })
}

# Output
output "sns_topic_arn" {
  value = aws_sns_topic.config_alerts.arn
}

output "config_bucket_name" {
  value = aws_s3_bucket.config_bucket.bucket
}
