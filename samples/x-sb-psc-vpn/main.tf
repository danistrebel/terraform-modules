/**
 * Copyright 2022 Google LLC
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
  psa_config = {
    ranges = {
      apigee-range         = var.peering_range
      apigee-support-range = var.support_range
    }
    routes = null
  }
  subnets = [
    var.demo_subnet,
  ]
}

module "apigee-x-core" {
  source              = "../../modules/apigee-x-core"
  project_id          = module.project.project_id
  apigee_environments = var.apigee_environments
  ax_region           = var.ax_region
  apigee_envgroups    = var.apigee_envgroups
  network             = module.vpc.network.id
  apigee_instances    = var.apigee_instances
}

module "psc-vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = module.project.project_id
  name       = var.psc_network
  subnets    = []
}

resource "google_compute_subnetwork" "psc_euw1_subnet" {
  name          = var.psc_subnet.name
  project       = module.project.project_id
  region        = var.psc_subnet.region
  network       = module.psc-vpc.network.id
  ip_cidr_range = var.psc_subnet.ip_cidr_range
  purpose = "PRIVATE"
}

resource "google_compute_subnetwork" "psc_nat_euw1_subnet" {
  name          = var.psc_nat_subnet.name
  project       = module.project.project_id
  region        = var.psc_nat_subnet.region
  network       = module.psc-vpc.network.id
  ip_cidr_range = var.psc_nat_subnet.ip_cidr_range
  purpose = "PRIVATE_SERVICE_CONNECT"
}

resource "google_compute_subnetwork" "psc_ibl_euw1_subnet" {
  name          = var.psc_ilb_subnet.name
  project       = module.project.project_id
  region        = var.psc_ilb_subnet.region
  network       = module.psc-vpc.network.id
  ip_cidr_range = var.psc_ilb_subnet.ip_cidr_range
  purpose       = "INTERNAL_HTTPS_LOAD_BALANCER"
  role          = "ACTIVE"
}

module "on-prem-vpc" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpc?ref=v16.0.0"
  project_id = module.project.project_id
  name       = var.on_prem_network
  subnets = [
    var.on_prem_subnet,
  ]
}

module "backend-example" {
  source     = "../../modules/development-backend"
  project_id = module.project.project_id
  name       = var.backend_name
  network    = module.on-prem-vpc.network.id
  subnet     = module.on-prem-vpc.subnet_self_links["${var.on_prem_subnet.region}/${var.on_prem_subnet.name}"]
  region     = var.on_prem_region
}

module "vpn_ha-1" {
  source                  = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v16.0.0"
  project_id              = module.project.project_id
  region                  = var.on_prem_region
  network                 = module.psc-vpc.network.id
  name                    = "on-prem-to-apigee"
  peer_gcp_gateway        = module.vpn_ha-2.self_link
  router_asn              = 64514
  router_advertise_config = null
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
      vpn_gateway_interface           = 1
    }
  }
}

module "vpn_ha-2" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-vpn-ha?ref=v16.0.0"
  project_id = module.project.project_id
  region     = var.on_prem_region
  network    = module.on-prem-vpc.network.id
  name       = "apigee-to-on-prem"
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "${var.peering_range}" = "Apigee X Peering Range"
    }
    mode = "CUSTOM"
  }
  router_asn       = 64513
  peer_gcp_gateway = module.vpn_ha-1.self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn_ha-1.random_secret
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn_ha-1.random_secret
      vpn_gateway_interface           = 1
    }
  }
}


module "southbound-psc" {
  source              = "../../modules/sb-psc-attachment"
  project_id          = module.project.project_id
  name                = var.psc_name
  region              = var.on_prem_region
  apigee_organization = module.apigee-x-core.org_id
  nat_subnets         = [google_compute_subnetwork.psc_nat_euw1_subnet.id]
  target_service      = "on-prem-backend-service"
  depends_on = [
    module.apigee-x-core.instance_endpoints,
    module.psc-ilb,
  ]
}

module "api-client" {
  count      = var.api_client_vm == null ? 0 : 1
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/compute-vm?ref=v16.0.0"
  project_id = module.project.project_id
  zone       = var.api_client_vm.zone
  name       = var.api_client_vm.name
  options = {
    spot               = true
    allow_stopping_for_update = true
    deletion_protection = false
  }
  network_interfaces = [{
    network    = module.vpc.network.id
    subnetwork =  module.vpc.subnet_self_links["${var.demo_subnet.region}/${var.demo_subnet.name}"]
    addresses = null
    nat = false
  }]
  tags = var.api_client_vm.network_tags
  service_account_create = true
  instance_type          = "f1-micro"
}

resource "google_compute_firewall" "allow_api_client_ssh" {
  name          = "api-client-allow-ssh"
  project       = module.project.project_id
  network       = module.vpc.network.id
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.api_client_vm.allow_ssh ? var.api_client_vm.network_tags : []
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

module "psc-ilb" {
  source     = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-ilb-l7?ref=40a37e9328d2a2692e7a91be0e8bfaad6a971549"
  name       = "on-prem-backend-service"
  project_id = module.project.project_id
  region     = var.psc_ilb_subnet.region
  backend_service_configs = {
    default = {
      backends = [{
        balancing_mode = "RATE"
        group = "on-prem-service"
        max_rate       = { per_endpoint = 1 }
      }]
    }
  }
  neg_configs = {
    on-prem-service = {
      zone      = "${var.psc_ilb_subnet.region}-b"
      is_hybrid = true
      endpoints = [{
        ip_address = module.backend-example.ilb_forwarding_rule_address
        port = 80
      }]
    }
  }
  vpc_config = {
    network    = module.psc-vpc.network.id
    subnetwork = google_compute_subnetwork.psc_euw1_subnet.id
  }
}

resource "google_compute_firewall" "allow_on_prem_backend_http" {
  name          = "on-prem-sample-backend-http"
  project       = module.project.project_id
  network       = module.on-prem-vpc.network.id
  source_ranges = ["0.0.0.0/0"]
  target_tags   = [var.backend_name]
  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
}