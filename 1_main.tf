// Event Hubs
module "module_event_hubs" {
  source                  = "./modules/event_hubs"
  location                = var.location
  resource_group_name     = var.resource_group_name
  eventhub_namespace_name = var.eventhub_namespace_name
  eventhubs               = var.eventhubs
}

// DB
module "sql_database" {
  source              = "./modules/sql_database"
  depends_on          = [module.module_event_hubs]
  resource_group_name = var.resource_group_name
  location            = var.location
  sql_admin_login     = var.sql_admin_login
  sql_admin_password  = var.sql_admin_password
  schema_file_path    = "${path.root}/dwh_schema.sql"
}

// STREAM
module "stream_analytics" {
  source                  = "./modules/stream_analytics"
  depends_on              = [module.module_event_hubs, module.sql_database]
  resource_group_name     = var.resource_group_name
  location                = var.location
  eventhub_namespace_name = var.eventhub_namespace_name
  eventhub_listen_key     = module.module_event_hubs.listen_connection_string
  sql_server_fqdn         = module.sql_database.server_fqdn
  sql_database_name       = module.sql_database.database_name
  sql_admin_login         = var.sql_admin_login
  sql_admin_password      = var.sql_admin_password
}

// Event producers
module "container_producers" {
  source     = "./modules/container_producers"
  depends_on = [module.module_event_hubs, module.stream_analytics]

  resource_group_name = var.resource_group_name
  location            = var.location

  container_image   = var.container_producers_image
  connection_string = module.module_event_hubs.send_connection_string

  dockerhub_username = var.dockerhub_username
  dockerhub_token    = var.dockerhub_token
}

