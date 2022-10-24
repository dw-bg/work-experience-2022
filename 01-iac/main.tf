# ----------------------------------------- #
#
#       Variables you must provide
#   (use the my-variables.tfvars file)
#
# ----------------------------------------- #

variable "project" {
  type = string
  description = "The name you will give this application"
}

variable "environment" {
  type = string
  description = "Environment (dev / stage / prod)"
  default = "dev"
}

variable "location" {
  type = string
  description = "Which Azure region will you deploy to (should match your resource group location)"
}

variable "resource_group_name" {
  type = string
  description = "The resource group into which this resource should be placed"
}

variable "difficulty" {
  type = string
  description = "How many digits are in the guessing game? Choose easy (1), normal (2), or hard (3)"
  default = "easy"
  validation {
    condition     = contains(["easy", "normal", "hard"], var.difficulty)
    error_message = "Valid values for var: difficulty are (easy, normal, hard)."
  }
}

# ----------------------------------------- #
#
#       Resources to deploy to Azure
#
# ----------------------------------------- #

# A random string of lowercase letters and numbers
resource "random_string" "storage_name" {
    length = 12
    upper = false
    lower = true
    numeric = true
    special = false
}

# A random string of numbers
resource "random_string" "guessing_game" {
    length = 8
    upper = false
    lower = false
    numeric = true
    special = false
}

# A storage account to save files in
resource "azurerm_storage_account" "storage_account" {
  name = "storage${random_string.storage_name.result}"
  resource_group_name = var.resource_group_name
  location = var.location
  account_tier = "Standard"
  account_replication_type = "LRS"
}

# A resource to monitor your running app - Ignore
resource "azurerm_application_insights" "application_insights" {
  name                = "${var.project}-${var.environment}-application-insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  application_type    = "Node.JS"
}

# A resource plan for your application (how much are you using? how much does it cost?)
resource "azurerm_app_service_plan" "app_service_plan" {
  name                = "${var.project}-${var.environment}-app-service-plan"
  resource_group_name = var.resource_group_name
  location            = var.location
  kind                = "FunctionApp"
  reserved = false # this has to be set to true for Linux. Not related to the Premium Plan
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

# A function app to run your code 
resource "azurerm_function_app" "function_app" {
  name                       = "${var.project}-${var.environment}-function-app-${random_string.storage_name.result}"
  resource_group_name        = var.resource_group_name
  location                   = var.location
  app_service_plan_id        = azurerm_app_service_plan.app_service_plan.id
  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY" = azurerm_application_insights.application_insights.instrumentation_key,
    "Answer" = random_string.guessing_game.result,
    "Difficulty" = var.difficulty
  }
  
  site_config {}
  storage_account_name       = azurerm_storage_account.storage_account.name
  storage_account_access_key = azurerm_storage_account.storage_account.primary_access_key
  version                    = "4"
}

# ----------------------------------------- #
#
#       Outputs from your deployment
#
# ----------------------------------------- #

output "function_app_name" {
  value = azurerm_function_app.function_app.name
  description = "Deployed function app name"
}

output "function_app_default_hostname" {
  value = azurerm_function_app.function_app.default_hostname
  description = "Deployed function app hostname"
}

# ----------------------------------------- #
#
#       Terraform Setup Code (ignore)
#
# ----------------------------------------- #

terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # Root module should specify the maximum provider version
      # The ~> operator is a convenient shorthand for allowing only patch releases within a specific minor release.
      version = "~> 2.26"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}
