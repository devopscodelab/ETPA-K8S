# Terraform Quick Reference Guide

## Essential Terraform Commands

### Initialization and Setup

```bash
# Initialize Terraform (downloads providers and modules)
terraform init

# Initialize with backend reconfiguration
terraform init -reconfigure

# Initialize without downloading modules
terraform init -backend=false

# Upgrade providers to latest versions
terraform init -upgrade
```

### Planning and Validation

```bash
# Validate configuration syntax
terraform validate

# Format Terraform files
terraform fmt

# Format and check if files are formatted
terraform fmt -check

# Create execution plan
terraform plan

# Save plan to file
terraform plan -out=tfplan

# Plan with variable file
terraform plan -var-file="prod.tfvars"

# Plan with specific target
terraform plan -target=aws_vpc.main
```

### Applying Changes

```bash
# Apply changes
terraform apply

# Apply saved plan
terraform apply tfplan

# Apply with auto-approve (no confirmation)
terraform apply -auto-approve

# Apply with variable
terraform apply -var="aws_region=us-west-2"

# Apply specific resource
terraform apply -target=aws_eks_cluster.main
```

### Destroying Resources

```bash
# Destroy all resources
terraform destroy

# Destroy with auto-approve
terraform destroy -auto-approve

# Destroy specific resource
terraform destroy -target=aws_eks_cluster.main

# Plan destruction
terraform plan -destroy
```

### State Management

```bash
# List resources in state
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Remove resource from state (doesn't destroy)
terraform state rm aws_vpc.main

# Move resource in state
terraform state mv aws_vpc.main aws_vpc.new_main

# Pull remote state
terraform state pull

# Push state to remote
terraform state push

# Replace provider in state
terraform state replace-provider hashicorp/aws registry.terraform.io/hashicorp/aws
```

### Outputs

```bash
# Show all outputs
terraform output

# Show specific output
terraform output cluster_name

# Output in JSON format
terraform output -json

# Output raw value (no quotes)
terraform output -raw cluster_name
```

### Workspace Management

```bash
# List workspaces
terraform workspace list

# Create new workspace
terraform workspace new dev

# Select workspace
terraform workspace select dev

# Show current workspace
terraform workspace show

# Delete workspace
terraform workspace delete dev
```

### Import Existing Resources

```bash
# Import VPC
terraform import aws_vpc.main vpc-1234567890

# Import EKS cluster
terraform import module.eks.aws_eks_cluster.this etpa-k8s

# Import with module
terraform import 'module.eks.aws_eks_cluster.this[0]' etpa-k8s
```

### Debugging and Logging

```bash
# Enable debug logging
TF_LOG=DEBUG terraform apply

# Set log level (TRACE, DEBUG, INFO, WARN, ERROR)
TF_LOG=TRACE terraform apply

# Log to file
TF_LOG=DEBUG TF_LOG_PATH=./terraform.log terraform apply

# Disable logging
TF_LOG=
```

## Working with Variables

### Define Variables

```hcl
# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_types" {
  description = "EC2 instance types"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default = {
    Environment = "dev"
  }
}
```

### Use Variables

```bash
# Command line
terraform apply -var="aws_region=us-west-2"

# Variable file (terraform.tfvars)
aws_region = "us-west-2"
instance_types = ["t3.large"]

# Apply with variable file
terraform apply -var-file="prod.tfvars"

# Environment variable
export TF_VAR_aws_region="us-west-2"
terraform apply
```

## Working with Modules

### Use Module

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"
}
```

### Module Commands

```bash
# Initialize modules
terraform get

# Update modules
terraform get -update

# Show module tree
terraform providers
```

## Backend Configuration

### S3 Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "etpa-k8s/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock"
  }
}
```

### Initialize Backend

```bash
# Initialize with backend
terraform init

# Migrate state to new backend
terraform init -migrate-state

# Reconfigure backend
terraform init -reconfigure
```

## Data Sources

### Query Existing Resources

```hcl
# Get AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-*"]
  }
}

# Get availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# Use data source
resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

## Useful Patterns

### Count

```hcl
resource "aws_subnet" "public" {
  count      = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}
```

### For_each

```hcl
resource "aws_instance" "server" {
  for_each = toset(["web", "api", "db"])
  
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  
  tags = {
    Name = "server-${each.key}"
  }
}
```

### Conditional

```hcl
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? 1 : 0
  domain = "vpc"
}
```

### Dynamic Blocks

```hcl
resource "aws_security_group" "example" {
  name = "example"

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

## Terraform Graph

```bash
# Generate dependency graph
terraform graph | dot -Tpng > graph.png

# Install graphviz first
brew install graphviz  # macOS
sudo apt-get install graphviz  # Ubuntu
```

## Common Troubleshooting

### State Lock Issues

```bash
# Force unlock (use carefully!)
terraform force-unlock <lock-id>
```

### Refresh State

```bash
# Refresh state without modifying infrastructure
terraform refresh

# Or use apply with -refresh-only
terraform apply -refresh-only
```

### Taint Resource (Force Recreation)

```bash
# Mark resource for recreation
terraform taint aws_instance.example

# Untaint
terraform untaint aws_instance.example

# In newer versions, use replace
terraform apply -replace=aws_instance.example
```

### Import Existing Resources

```bash
# Import resource into state
terraform import aws_vpc.main vpc-1234567890

# Show what would be imported
terraform plan -generate-config-out=generated.tf
```

## Best Practices

1. **Use Version Constraints**
   ```hcl
   terraform {
     required_version = ">= 1.0"
     required_providers {
       aws = {
         source  = "hashicorp/aws"
         version = "~> 5.0"
       }
     }
   }
   ```

2. **Use Remote State**
   - Store state in S3 with encryption
   - Use DynamoDB for state locking
   - Never commit state files to Git

3. **Use Modules**
   - Reuse common infrastructure patterns
   - Use official modules when available
   - Version your modules

4. **Use Variables**
   - Parameterize configurations
   - Use descriptive variable names
   - Provide defaults where appropriate

5. **Tag Everything**
   ```hcl
   tags = merge(
     var.common_tags,
     {
       Name = "specific-resource"
     }
   )
   ```

6. **Plan Before Apply**
   - Always review plans
   - Save plans for production
   - Use `-target` carefully

7. **Use `.gitignore`**
   ```
   **/.terraform/*
   *.tfstate
   *.tfstate.*
   *.tfvars
   crash.log
   ```

## Useful Terraform Functions

```hcl
# String functions
upper("hello")                    # "HELLO"
lower("HELLO")                    # "hello"
join(", ", ["a", "b"])           # "a, b"
split(",", "a,b")                # ["a", "b"]

# Collection functions
length([1, 2, 3])                # 3
merge({a=1}, {b=2})              # {a=1, b=2}
concat([1, 2], [3, 4])           # [1, 2, 3, 4]

# Type conversion
tostring(123)                     # "123"
tolist(["a", "b"])               # List
tomap({a=1})                     # Map

# Encoding
jsonencode({a=1})                # JSON string
yamlencode({a=1})                # YAML string
base64encode("hello")            # Base64 string

# File functions
file("path/to/file")             # Read file
templatefile("template.tpl", {}) # Render template
```

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Registry](https://registry.terraform.io/)
- [AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
