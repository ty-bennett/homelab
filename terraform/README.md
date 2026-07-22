# Ty Bennett's HA k3s Hhomelab

I set out on a mission this summer to finally get around to setting up a
Kubernetes homelab. The goal is to mimic production a k8s environments with
hardware that I owned. I picked up most of this from recycling or buying secondhand,
and I bought 3 RPi 5's because those fit inside of a small rack that I found and I
wanted it to be small enough for all of this to live on top of my desk.

I was also inspired by Mischa van den Burg videos to start this using Rapsberry Pi's.
I am glad that I finally did get around to setting it up because it has been fun learning
how to set everything up for the first time following the documentation and running `kubectl`
commands to see the nodes and watch everything come together. 

I also was inspired by the cost of some SaaS service that I pay monthly fees for to finally
start this. I saw some services that you can self host like Immich, Karakeep, Sonarr, Jellyfin, 
Ollama for AI fun, and dev environments so I can have different workspaces based on the langugage I am 
programming in (I will be a junior this fall, so lots of programming happening)

## Design

I have 7 nodes total and their specs are as follows:

1. opensuse -> 32GB of RAM, Quad Core Dell Optiplex workstation
2. node0 -> 8GB of RAM, Quad Core ThinkCentre SFF workstation
3. node1 -> 8GB of RAM, Quad Core ThinkCentre SFF workstation
4. pi0 -> an RPi 4 with 8GB of RAM
5. pi1 -> an RPi5 with 8GB of RAM and 1TB NVME storage
6. pi2 -> an RPi5 with 8GB of RAM and 1TB NVME storage
7. pi3 -> an RPi5 with 16GB of RAM and 1TB NVME storage

K3s Terraform Provider: `danielbooth-cloud/k3s` 0.2.3 (installs k3s over SSH).

## Prerequisites before starting

- SSH key access + passwordless sudo for `ssh_user` on every node.
- an IP address that is open on your LAN (excluded from DHCP) that can be used as a VIP for kube-vip.
- Disabling firewalld on openSUSE nodes (I have 3 and k3s docs recommend to just disable.)
- Raspberry Pi's: append `cgroup_memory=1 cgroup_enable=memory`
  to /boot/firmware/cmdline.txt and reboot BEFORE starting.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # edit IPs
export TF_VAR_ssh_private_key="$(cat ~/.ssh/id_ed25519)" # need this for the provider to get into the different hosts to install k3s
terraform init
terraform plan
terraform apply

terraform output -raw kubeconfig > ~/.kube/config 
kubectl get nodes # verify 
```

*Note*: Copy the .kube/config file to any other node that you want to access the control plane from (i.e. a computer that lives outside or inside the cluster)

### Ex from another machine: 
`scp ty@node0:~/.kube/config .` and authenticate accordingly

## Notes

- Apply order: init cluster with first server -> joining ctrl plane nodes -> kube-vip + worker nodes.
- `kube_vip_interface` -> Normally this would ideally be one network interface, but my nodes use a combination of 
  Wired and wireless connectivity to my LAN, so if you leave this blank it will auto pick the interface to talk to the other
  control plane nodes
- Do not commit .tfstate files (it contains secrets)
