variable "kubevip" {
  description = "IP pool for kube-vip API Load Balancer"
  type = object({
    api_vip      = string
    local_as     = number
    peer_router  = string
    remote_as    = number
    version      = string
    vip_dns_name = string
  })
}

variable "node" {
    description = "Properties for MachinePool node types"
    type = object({
      ctl_plane = map(any)
      worker    = map(any)
  })

    validation {
    condition     = alltrue([
      for x in var.node : can(regex("^ctl-plane*|^worker*", x.name ))
    ])
    error_message = "Err: MachinePool node names must begin with `ctl-plane' for Control Plane Node Pool & 'worker' for Autoscaling Worker Node Pool."
  }
}

variable "rancher_env" {
  description = "Variables for Rancher environment"
  type = object({
    autoscale_annotations = map(string)
    cloud_credential      = string
    cluster_annotations   = map(string)
    cluster_labels        = map(string)
    cni                   = string
    rke2_version          = string
  })
}

variable "vsphere_env" {
  description = "Variables for vSphere environment"
  type = object({
    cloud_image_name = string
    datacenter       = string
    datastore        = string
    library_name     = string
    server           = string
  })
}