output "resource_group_name" {

  value = azurerm_resource_group.website.name
}

output "storage_account_name" {

  value = azurerm_storage_account.website.name
}

output "storage_static_website_endpoint" {

  value = azurerm_storage_account.website.primary_web_endpoint
}

output "frontdoor_endpoint" {

  value = azurerm_cdn_frontdoor_endpoint.website.host_name
}

output "website_url" {

  value = "https://${azurerm_cdn_frontdoor_endpoint.website.host_name}"
}