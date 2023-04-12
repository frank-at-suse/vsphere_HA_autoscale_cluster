kubevip = {
  api_vip      = "1.1.1.2"
  local_as     = 64513
  peer_router  = "1.1.1.3"
  remote_as    = 64513
  vip_dns_name = "vip.domain.com"
}

# These are machine specs for nodes.  Be mindful of System Requirements/Limitations!
node = {
  ctl_plane = { hdd_capacity = 30720, name = "ctl-plane", quantity = 3, vcpu = 2, vm_network = "VLAN_60", vram = 4096 }
  worker    = { hdd_capacity = 40960, name = "worker", quantity = 3, vcpu = 2, vm_network = "VLAN_70", vram = 4096 }
}

rancher_env = {
  autoscale_annotations = { "cluster.provisioning.cattle.io/autoscaler-max-size" = "4", "cluster.provisioning.cattle.io/autoscaler-min-size" = "1" }
  cloud_credential      = "local-vsphere"
  cluster_annotations   = { "foo" = "bar" }
  cluster_labels        = { "something" = "amazing" }
  cni                   = "calico"
  rke2_version          = "v1.25.7+rke2r1"
}

vsphere_env = {
  cloud_image_name = "os-of-your-choice"
  datacenter       = "datacenter-name"
  datastore        = "datastore-name"
  library_name     = "content-library-name"
  server           = "vcenter-server-name.domain.com"
}