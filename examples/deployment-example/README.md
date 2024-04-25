# Example Deployment

## Inputs
1. Specify the region where you want to deploy the IOMETE Data Plane.
2. Create a bucket in the region where you want to deploy the IOMETE Data Plane.

Follow this guide: https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html

> Pay attention the bucket region should match the region where you want to deploy the IOMETE Data Plane.

3. Specify any name for the cluster


## Deploying IOMETE Data Plane

Ensure you're targeting the right Kubernetes cluster with `kubectl` and have the necessary repository cloned.

Run:

```shell
terraform init -upgrade
terraform apply
```