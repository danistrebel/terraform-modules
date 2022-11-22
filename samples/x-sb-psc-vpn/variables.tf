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

variable "project_id" {
  description = "Project id (also used for the Apigee Organization)."
  type        = string
}

variable "ax_region" {
  description = "GCP region for storing Apigee analytics data (sxee https://cloud.google.com/apigee/docs/api-platform/get-started/install-cli)."
  type        = string
}

variable "apigee_envgroups" {
  description = "Apigee Environment Groups."
  type = map(object({
    environments = list(string)
    hostnames    = list(string)
  }))
  default = {}
}

variable "apigee_instances" {
  description = "Apigee Instances (only one instance for EVAL orgs)."
  type = map(object({
    region       = string
    ip_range     = string
    environments = list(string)
  }))
  default = {}
}

variable "apigee_environments" {
  description = "List of Apigee Environment Names."
  type        = list(string)
  default     = []
}

variable "network" {
  description = "Name of the VPC network to peer with the Apigee tennant project."
  type        = string
}

variable "demo_subnet" {
  description = "Subnet to host an API client in the Apigee Peering VPC."
  type = object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  })
}

variable "peering_range" {
  description = "Service Peering CIDR range."
  type        = string
}

variable "support_range" {
  description = "Support CIDR range of length /28 (required by Apigee for troubleshooting purposes)."
  type        = string
}

variable "billing_account" {
  description = "Billing account id."
  type        = string
  default     = null
}

variable "project_parent" {
  description = "Parent folder or organization in 'folders/folder_id' or 'organizations/org_id' format."
  type        = string
  default     = null
  validation {
    condition     = var.project_parent == null || can(regex("(organizations|folders)/[0-9]+", var.project_parent))
    error_message = "Parent must be of the form folders/folder_id or organizations/organization_id."
  }
}

variable "project_create" {
  description = "Create project. When set to false, uses a data source to reference existing project."
  type        = bool
  default     = false
}

variable "backend_name" {
  description = "Name for the Demo Backend"
  type        = string
  default     = "demo-backend"
}

variable "psc_network" {
  description = "PSC VPC name."
  type        = string
}

variable "psc_subnet" {
  description = "Subnet for PSC Network."
  type = object({
    name               = string
    ip_cidr_range      = string
    region             = string
  })
}

variable "psc_ilb_subnet" {
  description = "Subnet to host the PSC ILB."
  type = object({
    name               = string
    ip_cidr_range      = string
    region             = string
  })
}

variable "psc_nat_subnet" {
  description = "Subnet to host the PSC NAT."
  type = object({
    name          = string
    ip_cidr_range = string
    region             = string
  })
}
variable "on_prem_network" {
  description = "On-Premise VPC name."
  type        = string
}

variable "on_prem_region" {
  description = "GCP Region Backend (ensure this matches backend_subnet.region)."
  type        = string
}

variable "on_prem_subnet" {
  description = "Subnet to host the on-prem backend service."
  type = object({
    name               = string
    ip_cidr_range      = string
    region             = string
    secondary_ip_range = map(string)
  })
}

variable "psc_name" {
  description = "PSC name."
  type        = string
}

variable "api_client_vm" {
  description = "Example API client VM"
  type = object({
    name          = string
    zone          = string
    allow_ssh     = bool
    network_tags  = list(string)
  })
  default = null
}