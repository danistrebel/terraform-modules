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

ax_region = "europe-west1"

apigee_environments = ["test1", "test2"]

apigee_envgroups = {
  test = {
    environments = ["test1", "test2"]
    hostnames    = ["test.api.example.com"]
  }
}

apigee_instances = {
  euw1-instance = {
    region       = "europe-west1"
    ip_range     = "10.0.0.0/22"
    environments = ["test1", "test2"]
  }
}

network = "apigee-network"
demo_subnet = {
  name               = "demo-subnet"
  ip_cidr_range      = "10.200.0.0/28" # intentionally same as on-prem
  region             = "europe-west1"
  secondary_ip_range = null
}

peering_range = "10.0.0.0/22"

support_range = "10.1.0.0/28"

psc_network = "psc-network"
psc_subnet = {
  name               = "psc-euw1"
  ip_cidr_range      = "10.24.0.0/22"
  region             = "europe-west1"
  secondary_ip_range = null
}
psc_ilb_subnet = {
  name               = "psc-ilb-euw1"
  ip_cidr_range      = "10.25.0.0/22"
  region             = "europe-west1"
  secondary_ip_range = null
}
psc_nat_subnet = {
  ip_cidr_range = "10.0.4.0/22"
  name          = "psc-nat-euw1"
  region             = "europe-west1"
}

on_prem_network = "on-prem-network"
on_prem_region  = "europe-west1"
on_prem_subnet = {
  name               = "on-prem-euw1"
  ip_cidr_range      = "10.200.0.0/28"
  region             = "europe-west1"
  secondary_ip_range = null
}

psc_name = "demopsc"

api_client_vm = {
  allow_ssh = true
  name = "apigee-demo-api-client"
  network_tags = [ "demo-api-client" ]
  subnet = "demo-client"
  zone = "europe-west1-b"
}