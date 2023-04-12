data "http" "kube_vip_rbac" {
  url = "https://kube-vip.io/manifests/rbac.yaml"
}

data "http" "kube_vip_version" {
  method = "GET"
  url    = "https://api.github.com/repos/kube-vip/kube-vip/releases/latest"
}

data "rancher2_cloud_credential" "auth" {
  name = var.rancher_env.cloud_credential
}