# ETPA-K8S Architecture Documentation

## Overview

This document explains the architectural decisions, design patterns, and implementation details of the ETPA-K8S project.

## Architecture Principles

1. **Separation of Concerns**: Infrastructure (Terraform) is separated from application (Helm)
2. **Security by Design**: Network isolation, encryption, least privilege
3. **High Availability**: Multi-AZ deployment, redundancy
4. **Scalability**: Auto-scaling capabilities at both pod and cluster level
5. **Maintainability**: Clear structure, documentation, automation

## Network Architecture

### VPC Design

```
VPC: 10.0.0.0/16 (65,536 IPs)
│
├── Public Subnets (Internet Access)
│   ├── 10.0.1.0/24 (us-east-1a) - 256 IPs
│   └── 10.0.2.0/24 (us-east-1b) - 256 IPs
│
└── Private Subnets (No Direct Internet)
    ├── 10.0.10.0/24 (us-east-1a) - 256 IPs
    └── 10.0.20.0/24 (us-east-1b) - 256 IPs
```

### Routing Strategy

**Public Subnets**:
- Route: `0.0.0.0/0` → Internet Gateway
- Purpose: NAT Gateways, Load Balancers
- Internet-facing resources only

**Private Subnets**:
- Route: `0.0.0.0/0` → NAT Gateway
- Purpose: EKS worker nodes, application pods
- No direct internet access (security)

### Multi-AZ Deployment

Resources distributed across 2 availability zones for:
- **High Availability**: Survive AZ failure
- **Fault Tolerance**: No single point of failure
- **Load Distribution**: Spread traffic across zones

## Load Balancer Strategy

### Why Two Separate ALBs?

**External ALB** (Internet-Facing):
- Deployed in public subnets
- Public IP addresses
- Routes traffic from internet
- Exposes: `/get`, `/headers`, `/ip`

**Internal ALB** (Private):
- Deployed in private subnets
- Private IP addresses only
- Accessible from VPC only
- Exposes: `/post`, `/put`, `/delete`

### Alternative Solutions Considered

1. **Single ALB with Path-Based Routing**:
   - ❌ Cannot restrict paths to internal network only
   - ❌ All paths would be publicly accessible

2. **Network Policies**:
   - ❌ Only control pod-to-pod communication
   - ❌ Don't control external ingress traffic

3. **API Gateway**:
   - ❌ Additional service to manage
   - ❌ Higher cost and complexity

4. **Dual ALB** ✅ **CHOSEN**:
   - ✅ Clear network separation
   - ✅ Native AWS/K8s features
   - ✅ Simple to understand and maintain

## EKS Cluster Design

### Control Plane

- **Managed by AWS**: No management overhead
- **Multi-AZ**: HA control plane automatically
- **Version**: Kubernetes 1.28
- **Encryption**: Secrets encrypted with KMS

### Worker Nodes

```
Node Group Configuration:
- Instance Type: t3.medium
- Desired: 2 nodes
- Min: 1 node
- Max: 4 nodes
- Disk: 50GB encrypted gp3
```

**Why t3.medium?**:
- 2 vCPUs, 4GB RAM
- Burst capacity for variable workloads
- Cost-effective for dev/test
- Can run ~29 pods per node

### Security Hardening

1. **Private Subnets Only**:
   - Nodes have no public IPs
   - Internet access via NAT Gateway only

2. **IMDSv2 Required**:
   - Prevents SSRF attacks
   - Token-based metadata access

3. **Encrypted Storage**:
   - EBS volumes encrypted
   - Secrets encrypted with KMS

4. **No SSH Access**:
   - No SSH keys provisioned
   - Use AWS Systems Manager for access

## Application Architecture

### Deployment Strategy

```yaml
Replicas: 2
Strategy: RollingUpdate
  MaxUnavailable: 1
  MaxSurge: 1
```

**Benefits**:
- Zero-downtime deployments
- Always at least 1 pod running
- Gradual rollout reduces risk

### Resource Management

```yaml
Resources:
  Requests:
    memory: 64Mi
    cpu: 100m
  Limits:
    memory: 128Mi
    cpu: 200m
```

**Purpose**:
- **Requests**: Guarantee minimum resources
- **Limits**: Prevent resource hogging
- **Allows Burst**: Can use up to limits

### Health Checks

```yaml
LivenessProbe:
  httpGet: /status/200
  initialDelaySeconds: 10
  periodSeconds: 10

ReadinessProbe:
  httpGet: /status/200
  initialDelaySeconds: 5
  periodSeconds: 5
```

**Benefits**:
- **Liveness**: Restart unhealthy pods
- **Readiness**: Remove unready pods from LB
- **Fast Detection**: 5-10 second intervals

### Pod Anti-Affinity

```yaml
podAntiAffinity:
  preferredDuringSchedulingIgnoredDuringExecution:
    - weight: 100
      podAffinityTerm:
        labelSelector:
          matchExpressions:
            - key: app
              operator: In
              values: [httpbin]
        topologyKey: kubernetes.io/hostname
```

**Benefits**:
- Spreads pods across different nodes
- Improves availability
- Reduces impact of node failure

## Infrastructure as Code Design

### Terraform Structure

```
terraform/
├── providers.tf      # Provider configurations
├── variables.tf      # Input parameters
├── vpc.tf           # Network infrastructure
├── eks.tf           # Kubernetes cluster
├── alb-controller.tf # Load balancer setup
└── outputs.tf       # Export values
```

**Benefits**:
- **Modularity**: Each file has clear purpose
- **Reusability**: Can extract to modules
- **Maintainability**: Easy to find and update

### Helm Chart Structure

```
helm/httpbin-app/
├── Chart.yaml           # Metadata
├── values.yaml          # Configuration
└── templates/
    ├── deployment.yaml  # App deployment
    ├── service.yaml     # Service definition
    ├── ingress-external.yaml  # Public ALB
    └── ingress-internal.yaml  # Private ALB
```

**Benefits**:
- **Separation**: Infra vs. App concerns
- **Flexibility**: Easy to customize
- **Versioning**: Chart versions independent of infra

## Security Architecture

### Defense in Depth

**Layer 1 - Network Perimeter**:
- Internet Gateway for controlled internet access
- NAT Gateways for outbound only from private subnets

**Layer 2 - Network Segmentation**:
- Public subnets: Load balancers and NAT gateways only
- Private subnets: EKS nodes, no direct internet

**Layer 3 - Load Balancer**:
- External ALB: Public endpoints only
- Internal ALB: Private endpoints only

**Layer 4 - Kubernetes**:
- RBAC enabled by default
- Service accounts with IRSA
- Network policies (can be added)

**Layer 5 - Pod**:
- Non-root containers
- Resource limits
- ReadOnly root filesystem (can be enabled)

**Layer 6 - Data**:
- Secrets encrypted at rest (KMS)
- TLS in transit (can be enabled)

### IAM Security

**IRSA (IAM Roles for Service Accounts)**:
```
AWS Load Balancer Controller:
  ├── Service Account: aws-load-balancer-controller
  ├── IAM Role: etpa-k8s-aws-load-balancer-controller
  └── Permissions: Create/manage ALBs only
```

**Benefits**:
- No long-lived credentials
- Fine-grained permissions
- Automatic credential rotation

### Encryption

1. **At Rest**:
   - EKS secrets: KMS encryption
   - EBS volumes: Encrypted by default
   - S3 state: Server-side encryption

2. **In Transit** (can enable):
   - HTTPS/TLS for ALBs
   - Pod-to-pod encryption with service mesh

## Scalability Design

### Horizontal Pod Autoscaling (HPA)

Can be enabled:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: httpbin
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: httpbin
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### Cluster Autoscaling

Already configured:
- Automatically adds nodes when pods pending
- Removes nodes when underutilized
- Min: 1, Max: 4 nodes

### Load Balancer Scaling

ALBs automatically scale:
- No manual intervention needed
- Handles traffic spikes
- Brief warm-up period for large spikes

## Cost Optimization

### Current Architecture Costs

| Component | Cost/Month |
|-----------|-----------|
| EKS Control Plane | $72 |
| 2x t3.medium nodes | $60 |
| 2x NAT Gateways | $65 |
| 2x Application LBs | $35 |
| **Total** | **~$232** |

### Optimization Strategies

**Development/Testing**:
1. Single NAT Gateway: -$32/month
2. t3.small instances: -$30/month
3. Single AZ: -$65/month (NAT+LB)
4. Spot instances: -40% on EC2

**Production**:
1. Reserved Instances: -40% on EC2
2. Savings Plans: -20% on EKS
3. Right-sizing: Monitor and adjust

## Monitoring and Observability

### Built-in Monitoring

1. **CloudWatch Container Insights**:
   - Cluster metrics
   - Node metrics
   - Pod metrics

2. **EKS Control Plane Logs**:
   - API server logs
   - Audit logs
   - Controller manager logs

3. **Application Logs**:
   ```bash
   kubectl logs -f deployment/httpbin -n httpbin
   ```

### Recommended Additions

1. **Prometheus + Grafana**:
   - Custom metrics
   - Alerting
   - Dashboards

2. **ELK Stack**:
   - Centralized logging
   - Log analysis
   - Search capability

3. **Distributed Tracing**:
   - Jaeger or AWS X-Ray
   - Request flow analysis

## Disaster Recovery

### Backup Strategy

**What to Backup**:
1. Terraform state (S3 backend)
2. Helm values and charts (Git)
3. Application data (if any)
4. Secrets (AWS Secrets Manager)

**Recovery Time Objective (RTO)**:
- Infrastructure rebuild: ~20 minutes
- Application deployment: ~5 minutes
- **Total RTO: ~25 minutes**

**Recovery Point Objective (RPO)**:
- Infrastructure: Git commit (seconds)
- Application: Container image (latest)
- **Total RPO: Near-zero**

### Multi-Region Strategy

For production:
1. Replicate infrastructure in second region
2. Use Route53 for failover
3. Cross-region replication for data

## Future Enhancements

### Short Term
- [ ] Enable SSL/TLS with ACM
- [ ] Add Prometheus monitoring
- [ ] Implement HPA
- [ ] Add network policies

### Medium Term
- [ ] Service mesh (Istio/Linkerd)
- [ ] GitOps with ArgoCD
- [ ] Centralized logging (ELK)
- [ ] WAF for ALBs

### Long Term
- [ ] Multi-region deployment
- [ ] Blue-green deployments
- [ ] Chaos engineering
- [ ] Advanced observability

## Lessons Learned

### Best Practices Applied

1. ✅ **Infrastructure as Code**: Everything versioned and reproducible
2. ✅ **Separation of Concerns**: Clear boundaries between layers
3. ✅ **Security First**: Defense in depth, least privilege
4. ✅ **Automation**: One-command deployment
5. ✅ **Documentation**: Comprehensive guides and examples

### Common Pitfalls Avoided

1. ❌ **Hardcoded Values**: Use variables and parameters
2. ❌ **Single AZ**: Always multi-AZ for production
3. ❌ **Public Nodes**: Keep worker nodes private
4. ❌ **No Monitoring**: Always include observability
5. ❌ **Manual Processes**: Automate everything

## Conclusion

This architecture provides:
- ✅ Network isolation with dual ALBs
- ✅ Production-ready security
- ✅ High availability and scalability
- ✅ Clear separation of infrastructure and application
- ✅ Comprehensive automation and documentation

Perfect for enterprise DevOps practices and AWS best practices.
