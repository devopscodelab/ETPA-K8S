# ETPA-K8S: Kubernetes Deployment on AWS

## Overview

This project provides a production-ready Infrastructure as Code (IaC) solution for deploying a web application on AWS EKS with **network segmentation using separate load balancers**. The solution separates infrastructure provisioning (Terraform) from application deployment (Helm), following modern DevOps best practices.

### Key Features

- **Separate Infrastructure & Application**: Infrastructure managed by Terraform, application deployed via Helm
- **Dual Load Balancers**: 
  - **External ALB** (internet-facing) for public endpoints (`/get`)
  - **Internal ALB** (private) for internal endpoints (`/post`, `/put`)
- **Production-Ready**: Multi-AZ deployment, auto-scaling, security hardening
- **Manual Step-by-Step Deployment**: Learn each component as you deploy

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                  ┌─────────▼─────────┐
                  │  Internet Gateway │
                  └─────────┬─────────┘
                            │
┌───────────────────────────┼─────────────────────────────────────┐
│ VPC (10.0.0.0/16)        │                                      │
│                           │                                      │
│  ┌────────────────────────▼────────────────────────┐            │
│  │      Public Subnets (Multi-AZ)                  │            │
│  │  ┌──────────────┐       ┌──────────────┐       │            │
│  │  │ NAT Gateway  │       │ NAT Gateway  │       │            │
│  │  │  us-east-1a  │       │  us-east-1b  │       │            │
│  │  └──────┬───────┘       └──────┬───────┘       │            │
│  │         │                      │               │            │
│  │  ┌──────▼──────────────────────▼───────┐      │            │
│  │  │   External ALB (Internet-Facing)     │      │            │
│  │  │   Managed by: Helm Chart             │      │            │
│  │  │   Exposes: /get, /headers, /ip       │      │            │
│  │  └──────────────────┬───────────────────┘      │            │
│  └─────────────────────┼──────────────────────────┘            │
│                        │                                        │
│  ┌─────────────────────┼──────────────────────────┐            │
│  │      Private Subnets (Multi-AZ)      │          │            │
│  │                     │                 │          │            │
│  │  ┌──────────────────▼─────────────────▼────┐   │            │
│  │  │   Internal ALB (VPC-Only)              │   │            │
│  │  │   Managed by: Helm Chart                │   │            │
│  │  │   Exposes: /post, /put, /delete         │   │            │
│  │  └──────────────────┬──────────────────────┘   │            │
│  │                     │                           │            │
│  │  ┌──────────────────▼──────────────────────┐   │            │
│  │  │      EKS Cluster (Managed by Terraform)  │   │            │
│  │  │   - Control Plane (AWS Managed)          │   │            │
│  │  │   - Worker Nodes (2x t3.medium)          │   │            │
│  │  │   - AWS Load Balancer Controller         │   │            │
│  │  │                                           │   │            │
│  │  │  ┌──────────┐  ┌──────────┐              │   │            │
│  │  │  │ httpbin  │  │ httpbin  │              │   │            │
│  │  │  │  Pod 1   │  │  Pod 2   │              │   │            │
│  │  │  └──────────┘  └──────────┘              │   │            │
│  │  └──────────────────────────────────────────┘   │            │
│  └──────────────────────────────────────────────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

## Project Structure

```
ETPA-K8S/
├── terraform/                    # Infrastructure as Code
│   ├── providers.tf             # AWS, Helm providers
│   ├── variables.tf             # Configurable parameters
│   ├── vpc.tf                   # VPC, subnets, routing
│   ├── eks.tf                   # EKS cluster & node groups
│   ├── alb-controller.tf        # AWS Load Balancer Controller
│   └── outputs.tf               # Deployment outputs
│
├── helm/                        # Application deployment
│   └── httpbin-app/
│       ├── Chart.yaml           # Helm chart metadata
│       ├── values.yaml          # Configuration values
│       └── templates/
│           ├── namespace.yaml   # Namespace definition
│           ├── deployment.yaml  # httpbin deployment
│           ├── service.yaml     # ClusterIP service
│           ├── ingress-external.yaml  # Public ALB
│           ├── ingress-internal.yaml  # Private ALB
│           └── NOTES.txt        # Post-install instructions
│
└── docs/                        # Additional documentation
    ├── TERRAFORM-GUIDE.md       # Terraform reference
    ├── KUBECTL-GUIDE.md         # kubectl reference
    └── ARCHITECTURE.md          # Architecture details
```

## Prerequisites

### Required Tools

Install the following tools before deployment:

1. **Terraform** >= 1.0
   ```bash
   # macOS
   brew install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   
   # Verify
   terraform version
   ```

2. **AWS CLI** >= 2.0
   ```bash
   # macOS
   brew install awscli
   
   # Linux
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   
   # Verify
   aws --version
   ```

3. **kubectl** >= 1.28
   ```bash
   # macOS
   brew install kubectl
   
   # Linux
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   
   # Verify
   kubectl version --client
   ```

4. **Helm** >= 3.0
   ```bash
   # macOS
   brew install helm
   
   # Linux
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   
   # Verify
   helm version
   ```

### AWS Requirements

- AWS account with appropriate permissions
- IAM user/role with permissions to create:
  - VPC, Subnets, Route Tables, NAT Gateways
  - EKS clusters and node groups
  - EC2 instances
  - IAM roles and policies
  - Application Load Balancers
  - KMS keys

### Cost Estimate

| Resource | Quantity | Cost/Month (Approx) |
|----------|----------|---------------------|
| EKS Cluster | 1 | $72 |
| EC2 Instances (t3.medium) | 1 | $60 |
| NAT Gateways | 2 | $65 |
| Application Load Balancers | 2 | $35 |
| **Total** | | **~$232** |

⚠️ **Important**: Remember to destroy resources when done to avoid charges!

## Step-by-Step Deployment

### Phase 1: AWS Credentials Setup

**Step 1: Configure AWS CLI**

```bash
aws configure
```

Enter your credentials:
- AWS Access Key ID: `<your-access-key>`
- AWS Secret Access Key: `<your-secret-key>`
- Default region name: `us-east-1`
- Default output format: `json`

**Step 2: Verify AWS Access**

```bash
# This should show your AWS account information
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-username"
}
```

### Phase 2: Deploy Infrastructure with Terraform

**Step 3: Navigate to Terraform Directory**

```bash
cd ETPA-K8S/terraform
```

**Step 4: Initialize Terraform**

```bash
terraform init
```

This downloads:
- AWS provider
- Helm provider
- EKS module

Expected output: "Terraform has been successfully initialized!"

**Step 5: Validate Terraform Configuration**

```bash
terraform validate
```

Expected output: "Success! The configuration is valid."

**Step 6: Review the Plan**

```bash
terraform plan
```

This shows what will be created:
- 1 VPC
- 2 Public subnets
- 2 Private subnets
- 2 NAT Gateways
- 1 Internet Gateway
- Route tables
- EKS cluster
- EKS node group
- IAM roles
- Security groups
- KMS key
- AWS Load Balancer Controller (via Helm)

Review carefully. You should see approximately 40-50 resources to be created.

**Step 7: Apply Terraform Configuration**

```bash
terraform apply
```

Type `yes` when prompted.

**⏱️ This takes approximately 15-20 minutes**

What's happening:
1. Creating VPC and networking (2-3 mins)
2. Creating NAT Gateways (3-5 mins)
3. Creating EKS cluster (10-12 mins)
4. Creating node group (3-5 mins)
5. Installing AWS Load Balancer Controller via Helm (1-2 mins)

**Step 8: Verify Infrastructure Deployment**

```bash
# Check Terraform outputs
terraform output

# You should see outputs like:
# cluster_name = "etpa-k8s"
# cluster_endpoint = "https://XXXXX.eks.us-east-1.amazonaws.com"
# region = "us-east-1"
```

### Phase 3: Configure kubectl

**Step 9: Update kubeconfig**

```bash
# Get cluster name from Terraform output
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -raw region)

# Configure kubectl
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
```

Expected output: "Added new context arn:aws:eks:us-east-1:...:cluster/etpa-k8s to /Users/.../.kube/config"

**Step 10: Verify Cluster Access**

```bash
# Check cluster connection
kubectl cluster-info
```

Expected output:
```
Kubernetes control plane is running at https://XXXXX.eks.us-east-1.amazonaws.com
CoreDNS is running at https://XXXXX.eks.us-east-1.amazonaws.com/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
```

**Step 11: Check Nodes are Ready**

```bash
kubectl get nodes
```

Expected output:
```
NAME                         STATUS   ROLES    AGE   VERSION
ip-10-0-10-XX.ec2.internal   Ready    <none>   5m    v1.28.x
```

If nodes show "NotReady", wait a minute and check again.

**Step 12: Verify AWS Load Balancer Controller**

```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

Expected output:
```
aws-load-balancer-controller-XXXXX   1/1     Running   0          5m
aws-load-balancer-controller-XXXXX   1/1     Running   0          5m
```

Both pods should be in "Running" state.

### Phase 4: Deploy Application with Helm

**Step 13: Navigate to Helm Directory**

```bash
cd ../helm
```

**Step 14: Validate Helm Chart**

```bash
# Lint the chart
helm lint httpbin-app/
```

Expected output: "1 chart(s) linted, 0 chart(s) failed"

**Step 15: Review Helm Values**

```bash
# View the default values
cat httpbin-app/values.yaml
```

Review the configuration:
- 2 replicas
- External ingress for `/get`, `/headers`, `/ip`
- Internal ingress for `/post`, `/put`, `/delete`

**Step 16: Test Template Rendering**

```bash
# Dry run to see what will be created
helm template httpbin httpbin-app/
```

This shows all the Kubernetes manifests that will be created.

**Step 17: Install Application with Helm**

```bash
helm install httpbin httpbin-app/ --namespace httpbin --create-namespace --wait
```

**⏱️ This takes approximately 3-5 minutes**

What's happening:
1. Creating namespace `httpbin` (instant)
2. Creating deployment with 2 pods (30 seconds)
3. Creating ClusterIP service (instant)
4. Creating external ingress (2-3 mins for ALB provisioning)
5. Creating internal ingress (2-3 mins for ALB provisioning)

**Step 18: Verify Application Deployment**

```bash
# Check Helm release
helm list -n httpbin
```

Expected output:
```
NAME    NAMESPACE  REVISION  STATUS    CHART           APP VERSION
httpbin httpbin    1         deployed  httpbin-app-1.0.0  1.0
```

**Step 19: Check Pods are Running**

```bash
kubectl get pods -n httpbin
```

Expected output:
```
NAME                      READY   STATUS    RESTARTS   AGE
httpbin-XXXXXXXXX-XXXXX   1/1     Running   0          2m
httpbin-XXXXXXXXX-XXXXX   1/1     Running   0          2m
```

**Step 20: Check Services**

```bash
kubectl get svc -n httpbin
```

Expected output:
```
NAME      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
httpbin   ClusterIP   10.100.XX.XX    <none>        80/TCP    2m
```

**Step 21: Check Ingresses**

```bash
kubectl get ingress -n httpbin
```

Expected output:
```
NAME               CLASS   HOSTS   ADDRESS                                    PORTS   AGE
httpbin-external   alb     *       k8s-httpbin-httpbine-XXXXX.us-east-1.elb.amazonaws.com   80      3m
httpbin-internal   alb     *       internal-k8s-httpbin-httpbini-XXXXX.us-east-1.elb.amazonaws.com   80      3m
```

⚠️ **Note**: If ADDRESS is empty, wait 2-3 minutes for ALBs to be provisioned. Check again with:
```bash
kubectl get ingress -n httpbin --watch
```
Press Ctrl+C to stop watching.

### Phase 5: Testing the Deployment

**Step 22: Get Load Balancer DNS Names**

```bash
# External (public) ALB
EXTERNAL_ALB=$(kubectl get ingress httpbin-external -n httpbin -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "External ALB: $EXTERNAL_ALB"

# Internal (private) ALB  
INTERNAL_ALB=$(kubectl get ingress httpbin-internal -n httpbin -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Internal ALB: $INTERNAL_ALB"
```

**Step 23: Test Public Endpoints**

```bash
# Test /get endpoint (should work from anywhere)
curl http://$EXTERNAL_ALB/get

# Expected: JSON response with request details
```

```bash
# Test /headers endpoint
curl http://$EXTERNAL_ALB/headers

# Expected: JSON response showing HTTP headers
```

```bash
# Test /ip endpoint
curl http://$EXTERNAL_ALB/ip

# Expected: JSON response showing your IP address
```

**Step 24: Verify Public Endpoint Restriction**

```bash
# Try to access /post from external ALB (should fail)
curl http://$EXTERNAL_ALB/post -X POST -d '{"test":"data"}'

# Expected: 404 Not Found
```

This confirms that `/post` is NOT exposed on the public ALB.

**Step 25: Test Internal Endpoints (from within VPC)**

Since internal endpoints are only accessible from within the VPC, we need to test from inside the cluster:

```bash
# Create a test pod
kubectl run test-pod --image=curlimages/curl -n httpbin --rm -it -- sh
```

Inside the pod shell:
```bash
# Test /post endpoint (should work)
curl http://internal-k8s-httpbin-httpbini-XXXXX.us-east-1.elb.amazonaws.com/post -X POST -H "Content-Type: application/json" -d '{"test":"data"}'

# Expected: JSON response echoing back your POST data
```

```bash
# Test /put endpoint
curl http://internal-k8s-httpbin-httpbini-XXXXX.us-east-1.elb.amazonaws.com/put -X PUT -H "Content-Type: application/json" -d '{"test":"data"}'

# Expected: JSON response echoing back your PUT data
```

```bash
# Test /delete endpoint
curl http://internal-k8s-httpbin-httpbini-XXXXX.us-east-1.elb.amazonaws.com/delete -X DELETE

# Expected: JSON response confirming DELETE request
```

Type `exit` to leave the test pod (it will be automatically deleted).

### Phase 6: Verify Network Isolation

**Step 26: Confirm Public/Private Separation**

From your local machine (outside VPC):

```bash
# Public ALB - /get should work
curl http://$EXTERNAL_ALB/get
# ✅ Success: Returns JSON

# Public ALB - /post should NOT work
curl http://$EXTERNAL_ALB/post -X POST
# ✅ Success: Returns 404 (endpoint not exposed)

# Internal ALB - /get should timeout (not exposed internally)
curl http://$INTERNAL_ALB/get --max-time 10
# ✅ Success: Should timeout or refuse connection

# Internal ALB - /post should timeout (private network only)
curl http://$INTERNAL_ALB/post -X POST --max-time 10
# ✅ Success: Should timeout (can't reach from internet)
```

This confirms:
- ✅ External ALB: Only exposes `/get`, `/headers`, `/ip` to the internet
- ✅ Internal ALB: Only exposes `/post`, `/put`, `/delete` within VPC
- ✅ Network isolation is working correctly

### Phase 7: Monitoring and Validation

**Step 27: Check Pod Logs**

```bash
# View logs from httpbin pods
kubectl logs -f deployment/httpbin -n httpbin

# You should see HTTP request logs
```

**Step 28: Check Events**

```bash
# View recent events
kubectl get events -n httpbin --sort-by='.lastTimestamp'
```

**Step 29: Check Resource Usage**

```bash
# View pod resource usage
kubectl top pods -n httpbin

# View node resource usage
kubectl top nodes
```

**Step 30: Verify ALBs in AWS Console**

1. Go to AWS Console → EC2 → Load Balancers
2. You should see 2 ALBs:
   - `k8s-httpbin-httpbine-...` (internet-facing)
   - `k8s-httpbin-httpbini-...` (internal)
3. Check target groups - both should show healthy targets

## Cleanup / Destroy Resources

When you're done testing, follow these steps to destroy all resources:

### Step 1: Delete Helm Release

```bash
helm uninstall httpbin -n httpbin
```

**⏱️ Wait 2-3 minutes for ALBs to be deleted**

You can monitor ALB deletion:
```bash
kubectl get ingress -n httpbin --watch
```

When both ingresses are gone (empty list), proceed to next step.

### Step 2: Verify ALBs are Deleted

```bash
# Check in AWS Console or via CLI
aws elbv2 describe-load-balancers --region us-east-1 | grep k8s-httpbin
```

Should return empty. If ALBs still exist, wait another minute.

### Step 3: Destroy Infrastructure

```bash
cd terraform
terraform destroy
```

Type `yes` when prompted.

**⏱️ This takes approximately 10-15 minutes**

### Step 4: Verify Cleanup

```bash
# Check no EKS clusters
aws eks list-clusters --region us-east-1

# Check no VPCs with our name
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=etpa-k8s-vpc" --region us-east-1

# Check no load balancers
aws elbv2 describe-load-balancers --region us-east-1
```

All should return empty lists.

## Troubleshooting

### Issue: Terraform Apply Fails

**Problem**: Permission denied or insufficient permissions

**Solution**:
```bash
# Verify AWS credentials
aws sts get-caller-identity

# Check you have admin permissions or at minimum:
# - VPC full access
# - EKS full access
# - EC2 full access
# - IAM role creation
```

### Issue: Nodes Not Ready

**Problem**: `kubectl get nodes` shows "NotReady"

**Solution**:
```bash
# Wait 2-3 minutes, nodes take time to initialize

# Check node details
kubectl describe node <node-name>

# Check events
kubectl get events --all-namespaces --sort-by='.lastTimestamp'
```

### Issue: Pods Not Starting

**Problem**: Pods stuck in "Pending" or "ContainerCreating"

**Solution**:
```bash
# Describe the pod
kubectl describe pod <pod-name> -n httpbin

# Check events section for errors
# Common issues:
# - Insufficient resources (need larger nodes)
# - Image pull errors (check internet connectivity)
# - Volume mount errors
```

### Issue: Ingress No Address

**Problem**: `kubectl get ingress` shows empty ADDRESS column

**Solution**:
```bash
# Check AWS Load Balancer Controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Verify controller is running
kubectl get pods -n kube-system | grep aws-load-balancer

# Describe ingress for events
kubectl describe ingress httpbin-external -n httpbin

# Wait 3-5 minutes - ALB provisioning takes time
```

### Issue: External ALB Not Accessible

**Problem**: `curl` to external ALB times out

**Solution**:
```bash
# Check ALB exists in AWS Console
aws elbv2 describe-load-balancers --region us-east-1

# Check security groups allow port 80
aws ec2 describe-security-groups --filters "Name=vpc-id,Values=<vpc-id>"

# Check target health
kubectl describe ingress httpbin-external -n httpbin

# Verify DNS resolution
nslookup <alb-dns-name>
```

### Issue: Internal ALB Accessible from Internet

**Problem**: Can access internal ALB from outside VPC (security issue!)

**Solution**:
```bash
# Check ingress annotation
kubectl get ingress httpbin-internal -n httpbin -o yaml | grep scheme

# Should show: alb.ingress.kubernetes.io/scheme: internal

# If not, edit ingress:
kubectl edit ingress httpbin-internal -n httpbin
# Add annotation: alb.ingress.kubernetes.io/scheme: internal

# Wait for ALB to recreate
```

## Understanding the Components

### Terraform Components

1. **vpc.tf**: Creates network infrastructure
   - VPC with CIDR 10.0.0.0/16
   - 2 public subnets (for NAT gateways and ALBs)
   - 2 private subnets (for EKS nodes)
   - Internet Gateway
   - 2 NAT Gateways (one per AZ for HA)
   - Route tables

2. **eks.tf**: Creates Kubernetes cluster
   - EKS control plane
   - Managed node group (2 t3.medium instances)
   - IAM roles for cluster and nodes
   - Security groups
   - KMS key for encryption

3. **alb-controller.tf**: Sets up load balancer management
   - IAM role for controller
   - Helm release for AWS Load Balancer Controller
   - Enables automatic ALB creation from Ingress resources

### Helm Components

1. **Deployment**: Runs httpbin container
   - 2 replicas for high availability
   - Health checks (liveness + readiness probes)
   - Resource limits

2. **Service**: Internal load balancing
   - ClusterIP type (internal to cluster)
   - Routes traffic to httpbin pods

3. **Ingress External**: Public ALB
   - Scheme: internet-facing
   - Paths: /get, /headers, /ip, /status/*
   - Creates public-facing ALB automatically

4. **Ingress Internal**: Private ALB
   - Scheme: internal
   - Paths: /post, /put, /delete, /patch
   - Creates internal ALB automatically

## Customization

### Change AWS Region

Edit `terraform/variables.tf`:
```hcl
variable "aws_region" {
  default = "eu-west-1"  # Change to your preferred region
}
```

Then run:
```bash
cd terraform
terraform plan
terraform apply
```

### Change Instance Type

Edit `terraform/variables.tf`:
```hcl
variable "instance_types" {
  default = ["t3.small"]  # Smaller for dev/test
}
```

### Adjust Node Count

Edit `terraform/variables.tf`:
```hcl
variable "desired_capacity" {
  default = 3  # More nodes
}
```

### Add More Endpoints

Edit `helm/httpbin-app/values.yaml`:
```yaml
ingress:
  external:
    paths:
      - path: /get
        pathType: Exact
      - path: /delay/*  # Add new endpoint
        pathType: Prefix
```

Then upgrade Helm release:
```bash
helm upgrade httpbin helm/httpbin-app/ -n httpbin
```

## Security Best Practices

### Implemented

- ✅ EKS nodes in private subnets
- ✅ No public IPs on worker nodes
- ✅ IMDSv2 required (prevents SSRF)
- ✅ Secrets encrypted with KMS
- ✅ Network segmentation (public/private ALBs)
- ✅ IAM Roles for Service Accounts (IRSA)
- ✅ Non-root containers
- ✅ Resource limits on pods

### Recommended Additions

1. **Enable SSL/TLS**:
   - Get ACM certificate
   - Add to ingress annotations:
   ```yaml
   alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:...
   alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
   ```

2. **Enable AWS WAF**:
   ```yaml
   alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:...
   ```

3. **Add Network Policies**:
   - Install Calico or Cilium
   - Restrict pod-to-pod communication

## Additional Resources

- [Terraform Guide](./docs/TERRAFORM-GUIDE.md) - Complete Terraform reference
- [kubectl Guide](./docs/KUBECTL-GUIDE.md) - Complete kubectl reference  
- [Architecture Documentation](./docs/ARCHITECTURE.md) - Design decisions

## Support

For issues:
1. Check Troubleshooting section above
2. Review logs: `kubectl logs -f deployment/httpbin -n httpbin`
3. Check events: `kubectl get events -n httpbin --sort-by='.lastTimestamp'`
4. Review AWS Console for ALB and EKS status

## License

This project is provided for educational and assessment purposes.

---

**Remember**: Destroy all resources when done to avoid AWS charges! (~$232/month)
