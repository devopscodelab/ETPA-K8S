# kubectl Quick Reference Guide

## Essential kubectl Commands

### Cluster Information

```bash
# Get cluster info
kubectl cluster-info

# Get cluster version
kubectl version

# View cluster nodes
kubectl get nodes

# Get node details
kubectl get nodes -o wide

# Describe a node
kubectl describe node <node-name>
```

### Working with Namespaces

```bash
# List all namespaces
kubectl get namespaces

# Get resources in a namespace
kubectl get all -n httpbin

# Set default namespace
kubectl config set-context --current --namespace=httpbin

# Create namespace
kubectl create namespace my-namespace

# Delete namespace
kubectl delete namespace my-namespace
```

### Pods

```bash
# List pods
kubectl get pods -n httpbin

# Get pods with details
kubectl get pods -o wide -n httpbin

# Describe pod
kubectl describe pod <pod-name> -n httpbin

# View pod logs
kubectl logs <pod-name> -n httpbin

# Follow logs in real-time
kubectl logs -f <pod-name> -n httpbin

# View logs from previous crashed container
kubectl logs <pod-name> --previous -n httpbin

# Execute command in pod
kubectl exec -it <pod-name> -n httpbin -- /bin/sh

# Copy files to/from pod
kubectl cp <pod-name>:/path/to/file ./local-file -n httpbin
kubectl cp ./local-file <pod-name>:/path/to/file -n httpbin
```

### Deployments

```bash
# List deployments
kubectl get deployments -n httpbin

# Describe deployment
kubectl describe deployment httpbin -n httpbin

# Scale deployment
kubectl scale deployment httpbin --replicas=3 -n httpbin

# Update image
kubectl set image deployment/httpbin httpbin=kennethreitz/httpbin:latest -n httpbin

# Edit deployment
kubectl edit deployment httpbin -n httpbin

# Rollout status
kubectl rollout status deployment/httpbin -n httpbin

# Rollout history
kubectl rollout history deployment/httpbin -n httpbin

# Undo rollout
kubectl rollout undo deployment/httpbin -n httpbin

# Pause rollout
kubectl rollout pause deployment/httpbin -n httpbin

# Resume rollout
kubectl rollout resume deployment/httpbin -n httpbin
```

### Services

```bash
# List services
kubectl get services -n httpbin

# Describe service
kubectl describe service httpbin -n httpbin

# Get service endpoints
kubectl get endpoints -n httpbin

# Port forward service to local machine
kubectl port-forward svc/httpbin 8080:80 -n httpbin
```

### Ingress

```bash
# List ingresses
kubectl get ingress -n httpbin

# Describe ingress
kubectl describe ingress httpbin-external -n httpbin

# Get ingress details
kubectl get ingress httpbin-external -n httpbin -o yaml

# Get load balancer address
kubectl get ingress httpbin-external -n httpbin -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

### ConfigMaps and Secrets

```bash
# List configmaps
kubectl get configmaps -n httpbin

# Create configmap from file
kubectl create configmap my-config --from-file=config.txt -n httpbin

# List secrets
kubectl get secrets -n httpbin

# Create secret
kubectl create secret generic my-secret --from-literal=password=secret123 -n httpbin

# Decode secret
kubectl get secret my-secret -n httpbin -o jsonpath='{.data.password}' | base64 --decode
```

### Events and Debugging

```bash
# Get events
kubectl get events -n httpbin

# Get events sorted by timestamp
kubectl get events -n httpbin --sort-by='.lastTimestamp'

# Watch events in real-time
kubectl get events -n httpbin --watch

# Get pod events
kubectl describe pod <pod-name> -n httpbin | grep -A 10 Events
```

### Resource Management

```bash
# Get resource usage
kubectl top nodes
kubectl top pods -n httpbin

# Get resource quotas
kubectl get resourcequota -n httpbin

# Get limit ranges
kubectl get limitrange -n httpbin

# Describe resources
kubectl describe nodes
```

### Labels and Selectors

```bash
# Get pods with labels
kubectl get pods -n httpbin --show-labels

# Filter by label
kubectl get pods -l app=httpbin -n httpbin

# Add label to pod
kubectl label pod <pod-name> env=production -n httpbin

# Remove label
kubectl label pod <pod-name> env- -n httpbin
```

### Context and Configuration

```bash
# Get contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Set current context namespace
kubectl config set-context --current --namespace=httpbin

# View kubeconfig
kubectl config view
```

### Useful Output Formats

```bash
# YAML output
kubectl get pod <pod-name> -n httpbin -o yaml

# JSON output
kubectl get pod <pod-name> -n httpbin -o json

# JSONPath
kubectl get pods -n httpbin -o jsonpath='{.items[*].metadata.name}'

# Custom columns
kubectl get pods -n httpbin -o custom-columns=NAME:.metadata.name,STATUS:.status.phase

# Wide output
kubectl get pods -n httpbin -o wide
```

### Common Debugging Scenarios

#### Pod is not starting

```bash
# Check pod status
kubectl get pod <pod-name> -n httpbin

# Describe pod for events
kubectl describe pod <pod-name> -n httpbin

# Check logs
kubectl logs <pod-name> -n httpbin

# Check previous logs if crashed
kubectl logs <pod-name> --previous -n httpbin
```

#### Service not accessible

```bash
# Check service
kubectl get svc httpbin -n httpbin

# Check endpoints
kubectl get endpoints httpbin -n httpbin

# Check if pods are ready
kubectl get pods -l app=httpbin -n httpbin

# Test service from inside cluster
kubectl run test-pod --image=curlimages/curl -n httpbin --rm -it -- sh
# curl http://httpbin.httpbin.svc.cluster.local
```

#### Ingress not working

```bash
# Check ingress
kubectl get ingress -n httpbin

# Describe ingress
kubectl describe ingress httpbin-external -n httpbin

# Check ingress controller
kubectl get pods -n kube-system | grep ingress

# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

### Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgi='kubectl get ingress'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias kex='kubectl exec -it'
alias kaf='kubectl apply -f'
alias kdel='kubectl delete'
alias kgn='kubectl get nodes'
alias kgns='kubectl get namespaces'
```

### Kubectl Plugins

Install useful plugins with krew:

```bash
# Install krew
curl -fsSL https://krew.sigs.k8s.io/install | bash

# Install useful plugins
kubectl krew install ctx      # Switch contexts easily
kubectl krew install ns       # Switch namespaces easily
kubectl krew install tree     # Show resource hierarchy
kubectl krew install tail     # Tail logs from multiple pods
```

## Tips and Tricks

1. **Use `--dry-run` for testing**:
   ```bash
   kubectl apply -f deployment.yaml --dry-run=client
   ```

2. **Generate YAML templates**:
   ```bash
   kubectl create deployment nginx --image=nginx --dry-run=client -o yaml > deployment.yaml
   ```

3. **Watch resources in real-time**:
   ```bash
   kubectl get pods -n httpbin --watch
   ```

4. **Use `-A` or `--all-namespaces` to see all**:
   ```bash
   kubectl get pods -A
   ```

5. **Quick pod access**:
   ```bash
   kubectl run temp --image=busybox --rm -it -- sh
   ```

6. **Force delete stuck pods**:
   ```bash
   kubectl delete pod <pod-name> -n httpbin --grace-period=0 --force
   ```

## Additional Resources

- [Official kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [kubectl Book](https://kubectl.docs.kubernetes.io/)
- [Kubernetes API Reference](https://kubernetes.io/docs/reference/kubernetes-api/)
