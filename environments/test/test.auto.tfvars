# ───────────────────────────────────────────────────────────────
#  ENVIRONMENT & LOCATION
# ───────────────────────────────────────────────────────────────

env      = "test"         # Name of the deployment environment (dev/test/preprod/prod)
location = "centralindia" # Azure region where resources will be created


# ───────────────────────────────────────────────────────────────
#  RESOURCE GROUP MANAGEMENT
# ───────────────────────────────────────────────────────────────
rg_lock_enable = false # Enables a Resource Group level lock (ReadOnly/Delete) to prevent deletion
lock_level     = "CanNotDelete"

# ───────────────────────────────────────────────────────────────
#  NETWORKING COMPONENTS
# ───────────────────────────────────────────────────────────────
enable_virtual_networks = false # Creates Virtual Network(s) defined in locals/variables
enable_nsg              = false # Creates Network Security Groups (NSGs)
enable_nsg_association  = false # Associates each subnet with its corresponding NSG

# ───────────────────────────────────────────────────────────────
#  STORAGE ACCOUNT
# ───────────────────────────────────────────────────────────────
enable_storage_account = false # Creates Storage Accounts (Blob/File/Queue etc.)

# ───────────────────────────────────────────────────────────────
#  OBSERVABILITY / MONITORING
# ───────────────────────────────────────────────────────────────
enable_log_analytics_workspace = false # Creates a Log Analytics workspace
enable_diagnostics_settings    = false # Enables Diagnostic Settings for supported resources (send logs/metrics)
enable_appinsights             = false # Creates an Application Insights instance

# ───────────────────────────────────────────────────────────────
#  SECURITY AND IDENTITY
# ───────────────────────────────────────────────────────────────
enable_kv                 = false # Creates Azure Key Vault
enable_rbac               = false # Enables Role Assignments for modules that require RBAC
enable_UserAssignedIdenti = false # Creates User Assigned Managed Identity (UAMI)

# ───────────────────────────────────────────────────────────────
#  DATABASE SERVICES
# ───────────────────────────────────────────────────────────────
enable_postgresql_flex = false # Creates Azure PostgreSQL Flexible Server
enable_sqlmi           = false # Creates Azure SQL Managed Instance
enable_cosmos          = false # Creates Azure CosmosDB Account (Core/Mongo/Gremlin depending on module)

# ───────────────────────────────────────────────────────────────
#  APPLICATION PLATFORM RESOURCES
# ───────────────────────────────────────────────────────────────
enable_function_app     = false # Creates Azure Function App (Linux/Windows — based on module config)
enable_aks              = false # Deploys Azure Kubernetes Service cluster
enable_redis_cache      = false # Creates Azure Redis Cache instance
enable_apim             = false # Creates Azure API Management service
enable_azure_documentdb = false # Creates Azure DocumentDB resources if configured
enable_di_account       = false # Creates Azure Data Explorer / Data Integration related resources
enable_aml_workspace    = false # Creates Azure Machine Learning workspace
enable_azure_openai     = false # Creates Azure OpenAI resource (Cognitive account)

# ───────────────────────────────────────────────────────────────
#  PRIVATE NETWORKING
# ───────────────────────────────────────────────────────────────
enable_private_dns_zone  = false # Creates Private DNS Zones for Private Endpoints
enable_private_endpoints = false # Creates Private Endpoints for supported resources
