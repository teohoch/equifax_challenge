# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.56.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.1"
    }
    postgresql = {
      source = "cyrilgdn/postgresql"
      version = "1.18.0"
    }
  }


  required_version = ">= 0.14"
}

