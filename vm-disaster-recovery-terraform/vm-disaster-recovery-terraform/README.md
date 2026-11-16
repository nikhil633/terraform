# VM Backup and Disaster Recovery - AWS + Azure Terraform

This project adds backup protection for **existing** AWS EC2 and Azure VMs.
It does not create or replace your existing VMs.

## Included

- AWS Backup vault in the primary region, encrypted with KMS.
- Daily AWS Backup plan with 30-day retention.
- Cross-region copy to a second AWS region and a separately encrypted vault.
- Selection of one existing EC2 instance by its ARN.
- Azure Recovery Services Vault with Geo-redundant storage (GRS).
- Azure Cross Region Restore enabled.
- Daily Azure VM backup policy with 30-day retention.
- Protection of one existing Azure VM by its full resource ID.

> Backups cost money for stored recovery points, cross-region copies, and restore operations.
> Confirm service/region availability and pricing before applying.

## Prerequisites

- Terraform installed.
- AWS credentials configured (`aws configure`, an AWS profile, or environment credentials).
- Azure CLI authenticated (`az login`) or a service principal configured for the AzureRM provider.
- The identity running Terraform needs permission to create IAM roles/policies, KMS keys,
  AWS Backup resources, Azure resource groups, Recovery Services Vaults, and backup policies.
- The Azure subscription must have the `Microsoft.RecoveryServices` provider registered.

Register Azure provider if required:

```bash
az provider register --namespace Microsoft.RecoveryServices
az provider show --namespace Microsoft.RecoveryServices --query registrationState
```

## Important: existing VM identifiers

AWS: supply the EC2 instance ARN, for example:

```text
arn:aws:ec2:ap-south-1:123456789012:instance/i-0123456789abcdef0
```

Azure: supply the full Azure VM resource ID, for example:

```text
/subscriptions/<subscription-id>/resourceGroups/<vm-resource-group>/providers/Microsoft.Compute/virtualMachines/<vm-name>
```

Find the AWS ARN:

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=ap-south-1
INSTANCE_ID=i-xxxxxxxxxxxxxxxxx
echo "arn:aws:ec2:${REGION}:${ACCOUNT_ID}:instance/${INSTANCE_ID}" 
```

Find the Azure VM ID:

```bash
az vm show --resource-group <vm-resource-group> --name <vm-name> --query id -o tsv
```

## Deploy AWS

1. Change directory to `aws/`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`.
3. Set the primary region, a different destination region, and your existing EC2 ARN.
4. Run:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

The backup schedule is 20:00 UTC daily (01:30 India Standard Time the next day).
The plan selects only the EC2 instance ARN you provide. AWS Backup protects the EC2
instance and its supported attached EBS volumes. Confirm the instance and volumes are
supported and that the instance is in the primary region.

To see recovery points:

```bash
aws backup list-recovery-points-by-backup-vault \
  --backup-vault-name ec2-primary-backup-vault
```

## Deploy Azure

1. Change directory to `azure/`.
2. Copy `terraform.tfvars.example` to `terraform.tfvars`.
3. Set the existing VM resource ID, VM region, subscription ID, and a unique vault name.
4. Run:

```bash
terraform init
terraform fmt -recursive
terraform validate
terraform plan
terraform apply
```

The Azure Recovery Services Vault must be in the same Azure region as the protected VM.
The vault uses GRS and enables Cross Region Restore. Cross Region Restore is available
only for supported Azure regions/workloads; verify your region and subscription support.

## Restore testing

Do not consider the solution complete until a restore has been tested.

AWS:
- AWS Console -> AWS Backup -> Backup vaults -> recovery points -> select recovery point -> Restore.
- Restore to a test instance or restore the EBS volumes, then attach/mount them.
- For regional disaster recovery, use the copied recovery point in the destination region.

Azure:
- Recovery Services Vault -> Backup items -> Azure Virtual Machine -> select VM -> Restore VM
  or Restore disks.
- For a regional disaster test, use Cross Region Restore where supported.
- Verify files and application/database consistency.

## Important operational notes

- This is a VM-level backup solution, not a replacement for database-native backups.
  For MySQL/PostgreSQL or other databases, also configure database-aware backups and
  transaction-log backups where applicable.
- For files that must survive VM deletion independently, store them in S3 or Azure Blob
  Storage as well, and enable versioning/soft delete/replication as appropriate.
- The VM backup protects the VM at backup time. Data written after the last successful
  backup can be lost. Daily backups can mean nearly 24 hours of data loss.
- The code deliberately does not configure an irreversible vault lock or immutable
  retention. Add those only after understanding the retention and deletion implications.
- Keep Terraform state in a protected remote backend with encryption, access control,
  and versioning. Do not commit `terraform.tfvars` or state files.
- Keep backup vaults and backup permissions separate from ordinary VM operator access.
- Do not delete the Recovery Services Vault or AWS Backup vault when deleting the VM.
- Test recovery regularly and document your RPO and RTO.

## Existing Terraform state warning

If your EC2/VM is already managed in a different Terraform root/module, do not declare
the VM a second time in this project. This project only manages backup resources and
references the existing VM using its ARN/resource ID. Keep the existing VM's Terraform
state and this backup project's state separate.
