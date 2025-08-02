# Rancher

AWS IAM Policies
- AmazonEKSComputePolicy
- AmazonVPCFullAccess
- AmazonEC2FullAccess
- IAMFullAccess
- AWSCloudFormationFullAccess
- custom policy - * on eks

## 1 Rancher + Multi Region EKS Deployment
```sh
# root dir - k8s-rancher
cd terraform
# 1. create vpc & subnets (public, private w NAT) in aws-me-central-1 & aws-me-south-1
cd environments/test/aws/0_network
echo "AWS_ACCESS_KEY_ID=your_access_key_id" > .env
echo "AWS_SECRET_ACCESS_KEY=your_secret_access_key" >> .env
dotenvx run -f .env -- terraform init
dotenvx run -f .env -- terraform apply -var-file=terraform.tfvars
# dotenvx run -f .env -- terraform destroy
cd -

# 2. create rancher server in aws-me-central-1 public subnet
cd environments/test/aws/1_rancher
echo "AWS_ACCESS_KEY_ID=your_access_key_id" > .env
echo "AWS_SECRET_ACCESS_KEY=your_secret_access_key" >> .env
dotenvx run -f .env -- terraform init
dotenvx run -f .env -- terraform apply -var-file=terraform.tfvars
# dotenvx run -f .env -- terraform destroy
cd -

# 2.1 - access rancher ui & create api key
# to to rancher ui - https://{rancher_server_dns}
# sign in with password - adminadminadmin
# gen api key - profile picture -> account & api keys -> create API key

# 3. create eks cluster in aws-me-central-1 & aws-me-south-1 public subnets
cd environments/test/aws/2_clusters
echo "AWS_ACCESS_KEY_ID=your_access_key_id" > .env
echo "AWS_SECRET_ACCESS_KEY=your_secret_access_key" >> .env
# update values in secret.tfvars
cp secret.tfvars.example secret.tfvars
dotenvx run -f .env -- terraform init
dotenvx run -f .env -- terraform apply -var-file=terraform.tfvars -var-file=secret.tfvars
# dotenvx run -f .env -- terraform destroy
cd -
```
