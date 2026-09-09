locals {
  zonal_regions = {
    "uksouth" = true
    "ukwest"  = false
  }

  # Is this Environment a post-run environment that has existing Resource Groups (that were created in a previous run) fed into it? If so, we're only going to handle Virtual Networks
  # Check the first Resource Group being fed, to see if the created_resource resource_id exists. If it has, this is being fed from a previous vend output
  post_run_environment = length(var.post_run_resources) > 0 ? true : false
}
