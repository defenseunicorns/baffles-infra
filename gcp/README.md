## Contents:
- [K3s on GCP](#k3s-on-gcp)
  - [Prerequisites](#prerequisites)
    - [Download `k3sup`](#download-k3sup)
    - [GCloud setup](#gcloud-setup)
  - [Usage](#usage)
    - [Quickstart](#quickstart)
    - [Variables](#variables)

## Prerequisites
### Download `k3sup`

Before running the setup, download `k3sup` on your local machine before starting the Terraform deployment. You can use the installer on MacOS and Linux, or visit the [Releases page](https://github.com/alexellis/k3sup/releases) to download the executable for Windows.

```sh
curl -sLS https://get.k3sup.dev | sh
sudo install k3sup /usr/local/bin/

k3sup --help
```

### GCloud Setup
Since k3sup requires an SSH key to access to GCP instances, we need to generate an SSH key and save the configuration into an SSH config file (~/.ssh/config).

```sh
$ gcloud compute config-ssh
```

By default, the SSH key is generated in ~/.ssh/google_compute_engine.

## Usage

### Quickstart
```sh
$ terraform init
$ terraform plan -var-file=your.tfvars
$ terraform apply -var-file=your.tfvars -auto-approve
```

### Variables
| Variable | Required | Type | Default Value |
|--|--|--|--|
| project| Yes | String | |
| credentials_file | Yes | String | |
| service_account | Yes | String | |
| ssh_user | Yes | String | |
| region | No | String | us-central1 |
| zone | No | String| us-central1-b |
| agent_nodes | No | Integer | 1 |

### Post Installation

After Terraform finishes creating the cluster, `k3sup` fetches the `kubeconfig` file to the current working directory.

```sh
$ kubectl get nodes --kubeconfig=kubeconfig
NAME               STATUS   ROLES                  AGE     VERSION
k3s-controlplane   Ready    control-plane,master   4m21s   v1.24.3+k3s1
k3s-agent-1        Ready    <none>                 28s     v1.24.3+k3s1
k3s-agent-0        Ready    <none>                 54s     v1.24.3+k3s1
```
