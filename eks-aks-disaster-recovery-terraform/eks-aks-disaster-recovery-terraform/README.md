# EKS + AKS Kubernetes Backup with Terraform

This project configures backup for **existing** EKS and AKS clusters. It does not create
or replace your Kubernetes clusters, VPC/VNet, node pools, ECR/ACR, or application
deployments. It creates the backup resources and connects them to the existing clusters.

## Important scope and current AKS limitation

- EKS: AWS Backup supports Kubernetes cluster state and supported persistent storage
  connected through PVCs (EBS, EFS and S3, subject to the relevant prerequisites).
- AKS: this Terraform example configures the AKS **Operational tier** backup workflow:
  Backup Vault, storage account/container, backup extension, trusted access, RBAC,
  policy, and backup instance.
- **Current Azure support-matrix limitation:** Microsoft currently documents that
  Vault-tier AKS backup is not supported through Terraform deployment. Therefore this
  Terraform AKS example does not claim cross-region disaster recovery. Operational-tier
  AKS recovery is regional. For regional AKS DR, implement a supported Vault-tier
  workflow using Azure's current supported portal/CLI/PowerShell path or wait until
  Terraform deployment is supported, and verify current regional availability.
- Terraform backup configuration is not a substitute for a tested restore.

## Prerequisites

### Both
- Terraform installed.
- Existing EKS/AKS cluster already created and healthy.
- Separate Terraform state for backup resources is recommended.
- Do not put credentials in `.tfvars`; use AWS profiles/environment credentials and
  `az login` or a service principal/OIDC for Azure.
- The identity running Terraform must be allowed to create backup resources and IAM/RBAC
  assignments. Azure role assignment creation requires `Microsoft.Authorization/roleAssignments/write`.

### AWS EKS
- AWS provider credentials configured.
- Existing EKS cluster ARN and AWS region.
- EKS cluster authentication mode must be `API` or `API_AND_CONFIG_MAP`. AWS Backup
  needs this so it can create the required EKS access entry.
- AWS Backup service role permissions are granted by the AWS managed backup/restore
  policies attached in this project.
- If the cluster uses S3-backed persistent storage, add the documented S3 backup policy
  and prerequisites. EBS/EFS persistent volumes are covered by the AWS Backup service
  role managed policy.
- The EKS cluster and source backup vault must be in the primary AWS region.

Check cluster authentication mode:

```bash
aws eks describe-cluster --name <cluster-name> --region <primary-region> \
  --query 'cluster.accessConfig.authenticationMode' --output text
```

If your existing cluster is managed by Terraform, update its `aws_eks_cluster` resource
with this block (do not declare the cluster a second time in this backup root):

```hcl
access_config {
  authentication_mode = "API_AND_CONFIG_MAP"
}
```

Apply that change through the Terraform state that owns the EKS cluster.

Get the cluster ARN:

```bash
aws eks describe-cluster --name <cluster-name> --region <primary-region> \
  --query 'cluster.arn' --output text
```

### Azure AKS
- Azure CLI authenticated (`az login`).
- Existing AKS cluster uses a system-assigned managed identity in this example.
- AKS cluster and Backup Vault must be in the same subscription and region.
- Storage account name must be globally unique, 3-24 lowercase letters/numbers.
- Register providers if needed:

```bash
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.DataProtection
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.Storage
```

- The Azure identity running Terraform needs sufficient permissions to create resources
  and role assignments at the relevant scopes. The example assigns the service roles
  needed for the backup workflow; it cannot grant the Terraform caller permission to
  create those assignments.

Find the AKS cluster name and resource group from Azure Portal or:

```bash
az aks list --query '[].{name:name, resourceGroup:resourceGroup, location:location}' -o table
```

## Deploy AWS EKS backup

```bash
cd eks
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: primary region, DR region, cluster ARN
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

Creates:
- KMS-encrypted primary AWS Backup vault.
- KMS-encrypted destination-region backup vault.
- AWS Backup service IAM role and managed backup/restore policies.
- Daily AWS Backup plan, 30-day retention.
- Cross-region copy action with 30-day retention.
- Backup selection targeting the supplied EKS cluster ARN.

The example runs daily at 20:00 UTC. Change the cron expression in `main.tf` if needed.
The EKS backup is a composite recovery point; supported PVC storage resources have child
recovery points.

## Deploy Azure AKS backup

```bash
cd aks
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars: subscription, AKS name/resource group, unique storage account
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

This creates backup resources around your existing AKS cluster:
- Dedicated backup resource group and snapshot resource group.
- Storage account and private blob container for the backup extension's operational data.
- Azure Data Protection Backup Vault with system-assigned identity.
- AKS Backup Extension.
- Trusted access role binding.
- Required role assignments for the extension identity, Backup Vault identity and AKS identity.
- Daily operational-tier backup policy with 30-day retention.
- Backup instance that selects all namespaces/resources by default and enables volume snapshots.

The extension stores Kubernetes resource data in the configured Blob container; disk-backed
PVC data is protected through snapshots in the snapshot resource group.

## Verify

AWS:

```bash
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name eks-primary-backup-vault \
  --region <primary-region>
```

Azure:

- Azure Portal -> Backup vault -> Backup instances -> select the AKS backup instance.
- Check protection state and the first successful backup job.
- Check the extension status:

```bash
az k8s-extension show --cluster-type managedClusters \
  --cluster-name <aks-name> --resource-group <aks-resource-group> \
  --name azure-aks-backup
```

## Restore testing

### EKS
Use AWS Backup -> Backup vault -> recovery point -> Restore. Restore to a supported
existing or new EKS target using the AWS Backup restore workflow. Recreate/verify
networking, IAM roles, add-ons, load balancers, DNS, and ECR image availability. Validate
PVCs and application data. If S3-backed PVCs are used, ensure their separate prerequisites
and recovery permissions are configured.

### AKS
Use the Azure Backup workflow to restore the backup to a target AKS cluster in the same
region (Operational tier). Validate namespace resources, PVCs, mounted files and app health.
Operational-tier backup is not a cross-region DR copy.

## Production notes

- Back up source code/manifests in Git and use Helm/Argo CD to recreate declarative workloads.
- Back up container images separately: ECR replication for AWS and ACR geo-replication
  or another image replication strategy for Azure.
- Use database-native backups/PITR for databases; Kubernetes volume snapshots alone do
  not guarantee application-consistent database recovery.
- Back up external dependencies separately: load balancers, DNS, secrets, certificates,
  IAM, network, KMS keys, Key Vault, and external databases.
- Define RPO/RTO and test restore regularly.
- Do not delete backup vaults, storage accounts, or snapshot resource groups as part of
  cluster teardown.
- Keep Terraform state protected and remote; it can contain sensitive values.
