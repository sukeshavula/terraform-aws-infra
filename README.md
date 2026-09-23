# terraform-aws-infra

A VPC, ALB and Auto Scaling group on AWS, built with reusable Terraform modules and remote state in S3 with DynamoDB locking. The same kind of setup also exists as a [CloudFormation version](https://github.com/sukeshavula/aws-cloudformation-vpc-3tier).

![terraform](https://github.com/sukeshavula/terraform-aws-infra/actions/workflows/terraform.yml/badge.svg)

```
bootstrap/     S3 bucket + DynamoDB table for remote state (run once, local state)
modules/vpc/   VPC, public/private subnets, IGW, NAT, route tables
modules/web/   SGs, ALB, launch template, ASG, CPU target tracking
envs/dev/      uses both modules, S3 backend
```

## Running it

Needs Terraform >= 1.6 and AWS credentials.

```bash
# 1. state backend (once)
cd bootstrap
terraform init
terraform apply -var="state_bucket_name=sukesh-tfstate-$(date +%s)"
# put the bucket name into the backend block in envs/dev/main.tf

# 2. dev
cd ../envs/dev
terraform init
terraform plan -out=dev.tfplan
terraform apply dev.tfplan
terraform output website_url

# 3. clean up (NAT gateway is billed hourly)
terraform destroy
```

## Design notes

- **Why the bootstrap step?** The backend bucket has to exist before `terraform init` can use it. It's created once with local state, and `prevent_destroy` stops it being deleted by accident.
- **DynamoDB locking** stops two applies from writing state at the same time. S3 versioning means I can roll back a bad state file.
- **Subnets come from `cidrsubnet()`**, so changing `az_count` from 2 to 3 doesn't mean rewriting CIDRs.
- **`nat_per_az`** switches between one shared NAT gateway (cheap) and one per AZ (HA).
- **`default_tags`** on the provider tags everything with Project, Environment and ManagedBy, which is handy in Cost Explorer.
- **Security baseline:** no SSH (SSM only), IMDSv2 required, encrypted EBS, and the app SG only allows the ALB SG.

## CI

Every push runs `terraform fmt -check` and `terraform validate` on `bootstrap/` and `envs/dev/`. There's also a `plan` job for pull requests, which runs when an IAM role for GitHub OIDC is configured and its ARN is saved as the `AWS_PLAN_ROLE_ARN` repository secret, so no AWS keys are stored in GitHub.

## TODO

- [ ] `envs/prod` with `nat_per_az = true`
- [ ] RDS module (Secrets Manager-managed password, like the CFN version)
- [ ] Add `tflint` and `checkov` to CI
