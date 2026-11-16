resource "random_string" "storage_suffix" {

  length  = 8
  special = false
  upper   = false
}

resource "azurerm_resource_group" "website" {

  name     = "${var.project_name}-${var.environment}-rg"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_storage_account" "website" {

  name = "${var.project_name}${random_string.storage_suffix.result}"

  resource_group_name = azurerm_resource_group.website.name

  location = azurerm_resource_group.website.location

  account_tier             = "Standard"
  account_replication_type = var.replication_type
  account_kind             = "StorageV2"

  https_traffic_only_enabled = true

  min_tls_version = "TLS1_2"

  allow_nested_items_to_be_public = false

  shared_access_key_enabled = true

  public_network_access_enabled = true

  infrastructure_encryption_enabled = true

  blob_properties {

    versioning_enabled = true

    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  static_website {

    index_document     = "index.html"
    error_404_document = "404.html"
  }

  network_rules {

    default_action = "Deny"

    bypass = ["AzureServices"]
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_cdn_frontdoor_profile" "website" {

  name = "${var.project_name}-${var.environment}-afd"

  resource_group_name = azurerm_resource_group.website.name

  sku_name = "Premium_AzureFrontDoor"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "random_string" "afd_suffix" {

  length  = 6
  special = false
  upper   = false
}

resource "azurerm_cdn_frontdoor_endpoint" "website" {

  name = "${var.project_name}-${random_string.afd_suffix.result}"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.website.id

  enabled = true

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_cdn_frontdoor_origin_group" "website" {

  name = "website-origin-group"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.website.id

  session_affinity_enabled = false

  load_balancing {
    sample_size                 = 4
    successful_samples_required = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {

    protocol            = "Https"
    interval_in_seconds = 100
    request_type        = "HEAD"
    path                = "/"
  }
}


resource "azurerm_cdn_frontdoor_origin" "website" {

  name = "private-storage-origin"

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.website.id

  enabled = true

  certificate_name_check_enabled = true

  host_name = azurerm_storage_account.website.primary_web_host

  origin_host_header = azurerm_storage_account.website.primary_web_host

  http_port  = 80
  https_port = 443

  priority = 1
  weight   = 1000

  private_link {

    request_message = "Private Link access for production static website"

    location = var.frontdoor_private_link_location

    private_link_target_id = azurerm_storage_account.website.id

    target_type = "web"
  }
}


resource "azurerm_cdn_frontdoor_firewall_policy" "website" {

  name                = "websitewaf${var.environment}"
  resource_group_name = azurerm_resource_group.website.name

  sku_name = "Premium_AzureFrontDoor"

  enabled = true

  mode = "Prevention"

  redirect_url = null

  managed_rule {

    type    = "Microsoft_DefaultRuleSet"
    version = "2.1"
    action  = "Block"
  }

  managed_rule {

    type    = "Microsoft_BotManagerRuleSet"
    version = "1.0"
    action  = "Block"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_cdn_frontdoor_route" "website" {

  name = "website-route"

  cdn_frontdoor_endpoint_id = azurerm_cdn_frontdoor_endpoint.website.id

  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.website.id

  cdn_frontdoor_origin_ids = [
    azurerm_cdn_frontdoor_origin.website.id
  ]

  enabled = true

  forwarding_protocol = "HttpsOnly"

  https_redirect_enabled = true

  patterns_to_match = [
    "/*"
  ]

  supported_protocols = [
    "Http",
    "Https"
  ]

  link_to_default_domain = true

  cache {

    query_string_caching_behavior = "IgnoreQueryString"

    compression_enabled = true

    content_types_to_compress = [
      "text/html",
      "text/css",
      "application/javascript",
      "application/json",
      "image/svg+xml"
    ]
  }
}


resource "azurerm_cdn_frontdoor_security_policy" "website" {

  name = "website-security-policy"

  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.website.id

  security_policies {

    firewall {

      cdn_frontdoor_firewall_policy_id = azurerm_cdn_frontdoor_firewall_policy.website.id

      association {

        patterns_to_match = [
          "/*"
        ]

        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.website.id
        }
      }
    }
  }
}


locals {

  website_files = fileset("${path.module}/www", "**/*")

  mime_types = {

    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    gif  = "image/gif"
    ico  = "image/x-icon"
    txt  = "text/plain"
  }
}

resource "azurerm_storage_blob" "website_files" {

  for_each = local.website_files

  name = each.value

  storage_account_name = azurerm_storage_account.website.name

  storage_container_name = "$web"

  type = "Block"

  source = "${path.module}/www/${each.value}"

  content_type = lookup(
    local.mime_types,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream"
  )

  content_md5 = filemd5base64("${path.module}/www/${each.value}")

  cache_control = endswith(each.value, ".html") ? "no-cache, max-age=0, must-revalidate" : "public, max-age=31536000"
}


