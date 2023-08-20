# Terraform EKS Cluster Setup

This Terraform repository provides an example setup for deploying an Amazon EKS cluster into an existing VPC. The setup includes configurations to allow pods within the EKS cluster to assume IAM roles, enabling them to access AWS resources such as S3 buckets.

## Prerequisites

Before you begin, ensure you have the following prerequisites in place:

- [Terraform](https://www.terraform.io/downloads.html) installed on your machine.
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured with your AWS credentials.
- An existing VPC with subnets where you plan to deploy the EKS cluster.
- An S3 bucket created that you want to grant access to from the pods in the EKS cluster.

## Usage

Follow these steps to deploy the EKS cluster and configure pod IAM role assumption:

1. **Clone the Repository:**

    Clone this repository to your local machine using the following commands:

    ```bash
    git clone https://github.com/travka/terraform-eks-task.git
    cd terraform-eks-task
    ```

2. **Configure Variables:**

    Open the `variables.tf` file and adjust the variables according to your preferences and requirements. You can modify the EKS cluster's region, name, version, VPC CIDR block, and other settings. Make sure to review and customize the variables before proceeding.

3. **Initialize Terraform:**

    Initialize Terraform to download the required provider plugins and modules:

    ```bash
    terraform init
    ```

4. **Deploy the EKS Cluster:**

    Deploy the EKS cluster and related resources using Terraform:

    ```bash
    terraform apply
    ```

5. **Configure kubectl:**

    Configure `kubectl` to work with the newly created EKS cluster:

    ```bash
    aws eks --region <your-region> update-kubeconfig --name <eks-cluster-name>
    ```

6. **Deploy a Sample Pod:**

    Use the following sample YAML configuration (`sample-pod.yaml`) to deploy a pod within the EKS cluster. Replace `<your-service-account-name>` with the actual service account name:

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: sample-pod
    spec:
      containers:
        - name: sample-container
          image: amazonlinux:latest
          command: ["sleep", "3600"]
      automountServiceAccountToken: true
      serviceAccountName: <your-service-account-name>
    ```

    Apply the sample pod configuration:

    ```bash
    kubectl apply -f sample-pod.yaml
    ```

7. **Verify S3 Access:**

    Verify that the pod can access the specified S3 bucket:

    ```bash
    kubectl exec -it sample-pod -- aws s3 ls s3://your-bucket-name
    ```

8. **Clean Up:**

    When you're done experimenting, don't forget to clean up the resources:

    ```bash
    terraform destroy
    ```

## Further Resources

- For more information on configuring pods to assume IAM roles and accessing S3 buckets, refer to the [official AWS documentation](https://docs.aws.amazon.com/eks/latest/userguide/pod-configuration.html).
- Explore Terraform's documentation for advanced configurations and customizations: [Terraform Documentation](https://www.terraform.io/docs/index.html).


---
Maintained by [travka](https://github.com/travka)

