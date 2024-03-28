# k8s

### Please ensure to replace <AWS_ACCOUNT_ID> with your actual account ID before applying to your cluster.
### Please ensure to replace <IMAGE_TAG> with the relevant image tag before applying to your cluster.

Included in this folder is the following:

- `karpenter.yaml`

    This includes the values needed to install Karpenter correctly.
    
    You can install the helm chart using 
    
    `helm install karpenter oci://public.ecr.aws/karpenter/karpenter -n karpenter --values karpenter.yaml --create-namespace`

- `kong.yaml`
    
    This includes the values needed to install the Kong Ingress Controller correctly.

    You can install the helm chart using:
    
     `helm install kong kong/ingress -n kong --values kong.yaml --create-namespace`

The reset of the files are raw Kubernetes resources that can be installed with:

`kubectl apply -f <file_name>`
