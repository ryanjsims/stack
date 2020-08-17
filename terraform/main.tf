terraform {
  backend "s3" {
    bucket = "ps2alerts"
    key    = "terraform/states/ps2alerts"
    region = "eu-west-2"
  }
}

data "digitalocean_kubernetes_cluster" "cluster" {
  name = "my-cluster"
}

provider "kubernetes" {
  load_config_file = false
  host             = data.digitalocean_kubernetes_cluster.cluster.endpoint
  token            = data.digitalocean_kubernetes_cluster.cluster.kube_config[0].token
  cluster_ca_certificate = base64decode(
    data.digitalocean_kubernetes_cluster.cluster.kube_config[0].cluster_ca_certificate
  )
}

resource "kubernetes_namespace" "ps2alerts" {
  metadata {
    name = "ps2alerts"
  }
}

module "ps2alerts_database" {
  source  = "./modules/database"
  db_user = var.db_user
  db_pass = var.db_pass
}

module "ps2alerts_redis" {
  source  = "./modules/redis"
  redis_pass = var.redis_pass
}