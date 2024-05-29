# Kubernetes Configuration for Karpenter and Kong Ingress Controller

This directory contains the necessary configuration files for setting up Karpenter and the Kong Ingress Controller in a Kubernetes cluster.

**Note:** Before applying these configurations to your cluster, replace `<AWS_ACCOUNT_ID>` and `<IMAGE_TAG>` with your actual AWS account ID and the relevant image tag, respectively.

## Included Files

- `karpenter.yaml`: This file contains the values needed to correctly install Karpenter. Install the Helm chart using the following command:

    ```bash
    helm install karpenter oci://public.ecr.aws/karpenter/karpenter -n karpenter --values karpenter.yaml --create-namespace
    ```

- `kong.yaml`: This file contains the values needed to correctly install the Kong Ingress Controller. Install the Helm chart using the following command:

    ```bash
    helm install kong kong/ingress -n kong --values kong.yaml --create-namespace
    ```

- The remaining files in this directory are raw Kubernetes resources that can be installed directly into your cluster.
    ```bash
    kubectl apply -f <file_name>
    ```