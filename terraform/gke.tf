
variable "gke_num_nodes" {
  default     = 3
  description = "number of gke nodes"
}

variable "zone" {
  description = "zone"
}


# GKE cluster
resource "google_container_cluster" "primary" {
  name     = "${var.project_id}-gke"
  location = var.zone

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  master_auth {
    client_certificate_config {
      issue_client_certificate = true
    }
  }
}

# Separately Managed Node Pool
resource "google_container_node_pool" "primary_nodes" {
  name       = google_container_cluster.primary.name
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.gke_num_nodes

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      env = var.project_id
    }

    # preemptible  = true
    machine_type = "n1-standard-1"
    disk_size_gb = 100
    tags         = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }
}

data "google_client_config" "default" {}

# resource "kubernetes_service_account" "k8_service_account" {
#   metadata {
#     name = "equifax-service-account"
#   }
# }

variable "app_password" {
  description = "Password for the first User of the app"
}


provider "kubernetes" {

  host     = "https://${google_container_cluster.primary.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.primary.master_auth.0.cluster_ca_certificate)

  token = "${data.google_client_config.default.access_token}"
}

resource "kubernetes_secret" "db_secret" {
  metadata {
    name = "db-cfg"
  }


  data = {
    DEMO_APP_DATABASE_NAME = "${var.sql_db_name}"
    DEMO_APP_DATABASE_USERNAME = "${var.sql_user}"
    DEMO_APP_DATABASE_PASSWORD = "${var.sql_pass}"
    DEMO_APP_DATABASE_HOST = "${google_sql_database_instance.master.ip_address.0.ip_address}"
    DEMO_APP_USER_PASSWORD="${var.app_password}"
  }
    
}

resource "kubernetes_deployment" "rails" {
  metadata {
    name = "scalable-rails-example"
    labels = {
      App = "ScalableRailsExample"
    }
  }

  spec {
    replicas = 3
    selector {
      match_labels = {
        App = "ScalableRailsExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableRailsExample"
        }
      }
      spec {
        container {
          image = "gcr.io/${var.project_id}/demoapp:0.0.3"
          name  = "example"
          image_pull_policy = "Always"

          port {
            container_port = 3000
          }

          env_from {
            secret_ref {
              name = "${kubernetes_secret.db_secret.metadata[0].name}"
            }
          }
          

          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "rails" {
  metadata {
    name = "rails-example"
  }
  spec {
    selector = {
      App = kubernetes_deployment.rails.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}

output "lb_ip" {
  value = kubernetes_service.rails.status.0.load_balancer.0.ingress.0.ip
}