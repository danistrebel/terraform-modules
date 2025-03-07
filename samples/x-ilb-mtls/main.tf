/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  subnet_region_name = { for subnet in var.exposure_subnets :
    subnet.region => "${subnet.region}/${subnet.name}"
  }
}

module "project" {
  source          = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/project?ref=v16.0.0"
  name            = var.project_id
  parent          = var.project_parent
  billing_account = var.billing_account
  project_create  = var.project_create
  services = [
    "apigee.googleapis.com",
    "cloudkms.googleapis.com",
    "compute.googleapis.com",
    "servicenetworking.googleapis.com"
  ]
}

module "vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = module.project.project_id
  name       = var.network
  subnets    = var.exposure_subnets
  psa_config = {
    ranges = {
      apigee-range         = var.peering_range
      apigee-support-range = var.support_range
    }
    routes = null
  }
}

module "apigee-x-core" {
  source              = "../../modules/apigee-x-core"
  project_id          = module.project.project_id
  apigee_environments = var.apigee_environments
  apigee_envgroups    = var.apigee_envgroups
  apigee_instances    = var.apigee_instances
  ax_region           = var.ax_region
  network             = module.vpc.network.id
}

module "apigee-x-mtls-mig" {
  for_each      = var.apigee_instances
  source        = "../../modules/apigee-x-mtls-mig"
  project_id    = module.project.project_id
  endpoint_ip   = module.apigee-x-core.instance_endpoints[each.key]
  ca_cert_path  = var.ca_cert_path
  tls_cert_path = var.tls_cert_path
  tls_key_path  = var.tls_key_path
  network       = var.network
  network_tags  = var.network_tags
  subnet        = module.vpc.subnet_self_links[local.subnet_region_name[each.value.region]]
  region        = each.value.region
}

module "ilb" {
  for_each      = var.apigee_instances
  source        = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-ilb?ref=v16.0.0"
  project_id    = module.project.project_id
  region        = each.value.region
  name          = "apigee-mtls-${each.key}"
  service_label = "apigee-mtls-${each.key}"
  network       = module.vpc.network.id
  subnetwork    = module.vpc.subnet_self_links[local.subnet_region_name[each.value.region]]
  ports         = [443]
  backends = [
    {
      group          = module.apigee-x-mtls-mig[each.key].instance_group,
      failover       = false
      balancing_mode = "CONNECTION"
    }
  ]
  health_check_config = {
    type    = "tcp"
    check   = { port = 443 }
    config  = {}
    logging = true
  }
}

resource "google_compute_firewall" "allow_ilb_hc" {
  name          = "hc-mtls-ilb"
  project       = module.project.project_id
  network       = var.network
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = var.network_tags
  allow {
    protocol = "tcp"
    ports    = ["443"]
  }
}
