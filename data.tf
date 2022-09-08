data "rancher2_cloud_credential" "auth" {
  name = var.rancher_env.cloud_credential
}