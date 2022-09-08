resource "random_pet" "cluster_name" {
  length = 2
}

resource "rancher2_machine_config_v2" "nodes" {
  for_each      = var.node
  generate_name = replace(each.key, "_", "-")

  vsphere_config {
    cfgparam   = ["disk.enableUUID=TRUE"]
    clone_from = var.vsphere_env.cloud_image_name
    cloud_config = templatefile("${path.cwd}/files/user_data.tftmpl",
      {
        ssh_user       = "rancher",
        ssh_public_key = file("${path.cwd}/files/.ssh-public-key")
    }) # End of templatefile
    content_library = var.vsphere_env.library_name
    cpu_count       = each.value.vcpu
    creation_type   = "library"
    datacenter      = var.vsphere_env.datacenter
    datastore       = var.vsphere_env.datastore
    disk_size       = each.value.hdd_capacity
    memory_size     = each.value.vram
    network         = [each.value.vm_network]
    vcenter         = var.vsphere_env.server
  }
} # End of rancher2_machine_config_v2

resource "rancher2_cluster_v2" "rke2" {
  annotations        = var.rancher_env.cluster_annotations
  kubernetes_version = var.rancher_env.rke2_version
  labels             = var.rancher_env.cluster_labels
  name               = random_pet.cluster_name.id

  rke_config {
    additional_manifest = templatefile("${path.cwd}/files/additional_manifests.tftmpl",
      {
        bgp_local_as     = var.kubevip.local_as,    # BGP AS for kube-vip routers
        bgp_peer_router  = var.kubevip.peer_router, # IP address for external BGP router
        bgp_remote_as    = var.kubevip.remote_as,   # BGP AS for upstream router
        k8s_api_vip      = var.kubevip.api_vip,     # IP address for advertising K8s API
        kube_vip_version = var.kubevip.version      # Pin kube-vip version for stability (optional)
    })

    machine_global_config = <<EOF
      advertise-address: ${var.kubevip.api_vip} # IP address to advertise for K8s API
      cni: ${var.rancher_env.cni}
      etcd-arg: [ "experimental-initial-corrupt-check=true" ] # Can be removed with etcd v3.6, which will enable corruption check by default (see: https://github.com/etcd-io/etcd/issues/13766)
      kube-proxy-arg: [ "proxy-mode=ipvs" ] # enable IPVS for kube-vip load balancer (kernel modules are installed via cloud-init)
      tls-san: [ "${var.kubevip.api_vip}","${var.kubevip.vip_dns_name}" ] # vip_dns_name can be omitted if no DNS server is available
    EOF

    dynamic "machine_pools" {
      for_each = var.node
      content {
        annotations                  = machine_pools.key != "ctl_plane" ? var.rancher_env.autoscale_annotations : null # Annotate only "worker" machine pools for autoscaling
        cloud_credential_secret_name = data.rancher2_cloud_credential.auth.id
        control_plane_role           = machine_pools.key == "ctl_plane" ? true : false
        etcd_role                    = machine_pools.key == "ctl_plane" ? true : false
        name                         = replace(machine_pools.key, "_", "-")
        quantity                     = machine_pools.value.quantity
        worker_role                  = machine_pools.key != "ctl_plane" ? true : false

        machine_config {
          kind = rancher2_machine_config_v2.nodes[machine_pools.key].kind
          name = replace(rancher2_machine_config_v2.nodes[machine_pools.key].name, "_", "-")
        } # End of machine_config
      }   # End of dynamic for_each
    }     # End of machine_pools

    machine_selector_config {
      config = null
    } # End machine_selector_config
  }   # End of rke_config

  lifecycle {
    ignore_changes = [
      rke_config[0].machine_pools[1].quantity # Instruct Terraform to ignore changes to the quantity of "worker" pool nodes, as autoscaler will cause this value to drift beteen state refreshes
    ]
  } # End of lifecycle
}   # End of rancher2_cluster_v2