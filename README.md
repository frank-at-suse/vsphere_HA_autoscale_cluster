# RKE2 Cluster with Autoscaling  & API Server HA
![Rancher](https://img.shields.io/badge/rancher-%230075A8.svg?style=for-the-badge&logo=rancher&logoColor=white) ![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white) 	![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)

## Reason for Being
This Terraform plan is for creating a multi-node RKE2 cluster in vSphere with machine pool autoscaling via [upstream K8s Cluster Autoscaler](https://github.com/kubernetes/autoscaler) & API Server HA via a [kube-vip](https://kube-vip.io/) DaemonSet manifest - bringing our cluster some "cloud-provider-like" behavior in the comfort of our own datacenter.

## Environment Prerequisites 
- Functional Rancher Management Server with vSphere Cloud Credential
- vCenter >= 7.x and credentials with appropriate permissions (see https://rancher.com/docs/rancher/v2.6/en/cluster-provisioning/rke-clusters/node-pools/vsphere/creating-credentials)
- Virtual Machine Hardware Compatibility at Version >= 15
- Create the following in the files/ directory:

    | NAME | PURPOSE |
    | ------ | ------ |
    | .rancher-api-url | URL for Rancher Management Server
    | .rancher-bearer-token | API bearer token generated via Rancher UI
    | .ssh-public-key | SSH public key for additional OS user
- Since this plan leverages BGP for K8s Control Plane load balancing, a router capable of BGP is required.  For lab/dev/test use, a small single-CPU Linux VM running [BIRD v2 daemon](https://bird.network.cz/?get_doc&f=bird.html&v=20) (`sudo apt install bird2`) with the following config would suffice:

```
protocol bgp kubevip {
        description "kube-vip for Cluster CP";
        local <router eth interface IP address> as 64513;
        neighbor range <network prefix of Control Plane subnet> as <AS value configured in kube-vip manifest>;
        graceful restart;
        ipv4 {
                import filter {accept;};
                export filter {reject;};
        };
        dynamic name "kubeVIP";
}
```

## Caveats
The `cluster_autoscaler.tf` plan includes the following values in `ExtraArgs:`
```
    skip-nodes-with-local-storage: false
    skip-nodes-with-system-pods: false
```
Those exist here to make the autoscaler logic more easily demonstrable and should be **_used with caution_** in production or any other environment you care about, as they could incur data loss or workload instability.

## To Run
    > terraform apply

## Tested Versions

| SOFTWARE | VERSION | DOCS |
| ------ | ------ | ------ |
| K8s Cluster Autoscaler | 1.25.0 | https://github.com/kubernetes/autoscaler/tree/master/charts/cluster-autoscaler#readme
| kube-vip | 0.5.0 | https://kube-vip.io/docs/
| Rancher Server | 2.6.8 | https://rancher.com/docs/rancher/v2.6/en/overview
| Rancher Terraform Provider| 1.24.1 | https://registry.terraform.io/providers/rancher/rancher2/latest/docs
| RKE2 | 1.24.4+rke2r1 | https://docs.rke2.io
| Terraform | 1.2.7 | https://www.terraform.io/docs
| vSphere | 7.0.3 Build 20150588 | https://docs.vmware.com/en/VMware-vSphere/index.html