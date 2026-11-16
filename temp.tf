
terraform {
  required_version = ">= 1.9.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "storage_account_name" {
  description = "Globally unique storage account name"
  type        = string

  validation {
    condition = (
      length(var.storage_account_name) >= 3 &&
      length(var.storage_account_name) <= 24 &&
      can(regex("^[a-z0-9]+$", var.storage_account_name))
    )
    error_message = "Name must contain 3-24 lowercase letters or numbers."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "private_endpoint_subnet_id" {
  description = "ID of an existing subnet for private endpoints"
  type        = string
}

variable "vnet_id" {
  description = "ID of the VNet used by private workloads"
  type        = string
}

resource "azurerm_storage_account" "example" {
  name                = var.storage_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  # Security
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  public_network_access_enabled   = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  # Encryption
  infrastructure_encryption_enabled = true

  # Prevent replication to another Entra tenant
  cross_tenant_replication_enabled = false

  # Managed identity for supported Azure integrations
  identity {
    type = "SystemAssigned"
  }

  # Blob protection and recovery
  blob_properties {
    versioning_enabled = true
    change_feed_enabled = true

    delete_retention_policy {
      days                     = 30
      permanent_delete_enabled = false
    }

    container_delete_retention_policy {
      days = 30
    }

    last_access_time_enabled = true
  }

  # Explicitly deny network-rule access by default
  network_rules {
    default_action = "Deny"
    bypass         = []
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
    service     = "storage"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_management_lock" "storage" {
  name       = "production-storage-delete-lock"
  scope      = azurerm_storage_account.example.id
  lock_level = "CanNotDelete"
  notes      = "Prevents accidental deletion of production storage."
}

# Private DNS zone for Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "blob-private-dns-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
}

# Private Endpoint for Blob Storage
resource "azurerm_private_endpoint" "blob" {
  name                = "${var.storage_account_name}-blob-pe"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "${var.storage_account_name}-blob-connection"
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "blob-dns-zone-group"

    private_dns_zone_ids = [
      azurerm_private_dns_zone.blob.id
    ]
  }

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.blob
  ]
}

output "storage_account_id" {
  value = azurerm_storage_account.example.id
}

output "storage_account_name" {
  value = azurerm_storage_account.example.name
}

output "storage_primary_blob_endpoint" {
  value = azurerm_storage_account.example.primary_blob_endpoint
}













terraform {
  required_version = ">= 1.6.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name"
  type        = string

  validation {
    condition = (
      length(var.bucket_name) >= 3 &&
      length(var.bucket_name) <= 63 &&
      can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", var.bucket_name)) &&
      !can(regex("\\.\\.", var.bucket_name))
    )
    error_message = "Provide a valid S3 bucket name between 3 and 63 characters."
  }
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

# S3 bucket
resource "aws_s3_bucket" "example" {
  bucket = var.bucket_name

  # Helps prevent accidental Terraform deletion
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name        = var.bucket_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Service     = "S3"
  }
}

# Block every form of public access
resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.example.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce ownership by the bucket owner; disable ACLs
resource "aws_s3_bucket_ownership_controls" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "example" {
  bucket = aws_s3_bucket.example.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Customer-managed KMS encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 bucket ${var.bucket_name}"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.bucket_name}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

resource "aws_s3_bucket_server_side_encryption_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }

    bucket_key_enabled = true
  }
}

# Lifecycle: transition current objects and expire old versions
resource "aws_s3_bucket_lifecycle_configuration" "example" {
  bucket = aws_s3_bucket.example.id

  rule {
    id     = "production-object-lifecycle"
    status = "Enabled"

    filter {}

    # Transition current objects to cheaper storage
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Expire noncurrent versions after 90 days
    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    # Remove expired delete markers where applicable
    expiration {
      expired_object_delete_marker = true
    }

    # Clean up incomplete multipart uploads
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# Deny unencrypted transport
data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.example.arn,
      "${aws_s3_bucket.example.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "example" {
  bucket = aws_s3_bucket.example.id
  policy = data.aws_iam_policy_document.bucket_policy.json

  depends_on = [
    aws_s3_bucket_public_access_block.example
  ]
}

output "bucket_name" {
  value = aws_s3_bucket.example.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.example.arn
}

output "kms_key_arn" {
  value = aws_kms_key.s3.arn
}







