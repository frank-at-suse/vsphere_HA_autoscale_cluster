resource "rancher2_app_v2" "cluster_autoscaler" {
  chart_name    = "cluster-autoscaler"
  chart_version = "9.28.0"
  cluster_id    = rancher2_cluster_v2.rke2.cluster_v1_id
  name          = "cluster-autoscaler"
  namespace     = "cattle-system"
  repo_name     = "autoscaler"
  values        = <<EOF
    autoDiscovery:
      clusterName: ${rancher2_cluster_v2.rke2.name}
    cloudProvider: rancher
    extraArgs:
      cloud-config: /etc/rancher/rancher.conf
      skip-nodes-with-local-storage: false
      skip-nodes-with-system-pods: false
    extraVolumeSecrets:
      cloud-config:
        name: ${rancher2_secret_v2.cluster_autoscaler_cloud_config.name}
        mountPath: /etc/rancher
    image:
      repository: registry.k8s.io/autoscaling/cluster-autoscaler
      tag: v1.26.2
    nodeSelector:
      node-role.kubernetes.io/control-plane: "true"
    tolerations:
    - effect: NoSchedule
      key: node-role.kubernetes.io/control-plane
    - effect: NoExecute
      key: node-role.kubernetes.io/etcd
  EOF
}

resource "rancher2_catalog_v2" "cluster_autoscaler" {
  cluster_id = rancher2_cluster_v2.rke2.cluster_v1_id
  name       = "autoscaler"
  url        = "https://kubernetes.github.io/autoscaler"
}

resource "rancher2_secret_v2" "cluster_autoscaler_cloud_config" {
  cluster_id = rancher2_cluster_v2.rke2.cluster_v1_id
  name       = "cluster-autoscaler-cloud-config"
  namespace  = "cattle-system"
  data = {
    "rancher.conf" = <<EOF
        url: ${file("${path.cwd}/files/.rancher-api-url")}
        token: ${rancher2_token.cluster_autoscaler.token}
        clusterName: ${rancher2_cluster_v2.rke2.name}
        clusterNamespace: fleet-default # This is the Namespace for the "cluster.provisioning.cattle.io" API resource on "local" cluster
    EOF
  }
}

resource "rancher2_token" "cluster_autoscaler" {
  description = "Unscoped Rancher API Token for Cluster Autoscaling"
  ttl         = 0
}
