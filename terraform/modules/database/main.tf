resource "kubernetes_service" "ps2alerts_database_service" {
  metadata {
    name = "ps2alerts-db"
    namespace = var.namespace
    labels = {
      app = var.db_identifier
      environment = var.environment
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = var.db_identifier
      environment = var.environment
    }
    port {
      port = var.db_port
      target_port = var.db_port
    }
  }
}

resource "kubernetes_persistent_volume_claim" "ps2alerts_database_volume" {
  metadata {
    name = var.db_identifier
    namespace = var.namespace
  }
  spec {
    access_modes = ["ReadWriteOnce"]
    storage_class_name = "do-block-storage"
    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

resource "kubernetes_deployment" "ps2alerts_database_deployment" {
  metadata {
    name = var.db_identifier
    namespace = var.namespace
    labels = {
      app = var.db_identifier
      environment = var.environment
    }
  }
  spec {
    replicas = 1
    revision_history_limit = 1
    selector {
      match_labels = {
        app = var.db_identifier
        environment = var.environment
      }
    }
    template {
      metadata {
        labels = {
          app = var.db_identifier
          environment = var.environment
        }
      }
      spec {
        container {
          name = var.db_identifier
          image = "mongo:4.2"
          volume_mount {
            mount_path = "/data"
            name = kubernetes_persistent_volume_claim.ps2alerts_database_volume.metadata[0].name
          }
          resources {
            limits {
              cpu = "1000m"
              memory = "1024Mi"
            }
            requests {
              cpu = "500m"
              memory = "512Mi"
            }
          }
          port {
            container_port = var.db_port
          }
          env {
            name = "MONGO_INITDB_DATABASE"
            value = "ps2alerts"
          }
          env {
            name = "MONGO_INITDB_ROOT_USERNAME"
            value = var.db_user
          }
          env {
            name = "MONGO_INITDB_ROOT_PASSWORD"
            value = var.db_pass
          }
        }
        volume {
          name = kubernetes_persistent_volume_claim.ps2alerts_database_volume.metadata[0].name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.ps2alerts_database_volume.metadata[0].name
          }
        }
      }
    }
  }
}
