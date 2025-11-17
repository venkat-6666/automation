# **CI/CD Pipeline + Docker Swarm Deployment Documentation**
### **(Complete A4 Printable Technical Documentation)**
---

# **1. Introduction**
This document explains the full end-to-end CI/CD architecture and deployment workflow that was built between **14 November – 17 November**, including Jenkins, Google Cloud Platform (GCP), Terraform, Ansible, Docker Swarm, and Google Artifact Registry (GAR).

It is written in a clean, human‑readable, A4‑formatted manner suitable for printing or project submission.

---

# **2. High-Level Architecture Overview**
The deployment system consists of the following major components:

- **Jenkins VM** → CI/CD Orchestration
- **Google Artifact Registry (GAR)** → Container Image Storage
- **Terraform** → Infrastructure provisioning on GCP
- **GCE Virtual Machines** → Swarm Manager + Worker Nodes
- **Ansible** → Post‑provisioning automation
- **Docker Swarm Cluster** → Application deployment environment
- **Dynamic Inventory Script** → Automatically discovers VMs created by Terraform

Workflow summary:

1. Developer pushes code to GitHub
2. Jenkins Pipeline builds Docker image
3. Image is pushed to GAR
4. Terraform runs → Swarm Manager + Worker VMs created
5. Dynamic Inventory identifies new VMs automatically
6. Ansible configures Docker, initializes Swarm
7. Workers join the cluster
8. Docker stack is deployed automatically

---

# **3. Jenkins Pipeline Overview**
Jenkins executes the following major stages:

### **Stage 1: Build Docker Image**
- Jenkins builds a Docker image from the application’s Dockerfile
- Tags image with version or latest

### **Stage 2: Push to GAR**
- Authenticates to Google Artifact Registry
- Pushes the image

### **Stage 3: Terraform Apply**
- Creates GCE VM instances:
  - 1× Swarm Manager
  - N× Swarm Workers (using Terraform count)
- Applies firewall rules and IAM settings

### **Stage 4: Ansible Provisioning**
- Configures Docker
- Initializes Swarm
- Retrieves join token
- Workers join swarm manager
- Stack deployment is executed

---

# **4. Terraform Infrastructure Setup**
Terraform provisions the following:

### **Compute Instances**
- `swarm-manager`
- `swarm-worker-1`
- `swarm-worker-2`

### **Firewall Rules**
- Allow SSH (22)
- Allow Docker Swarm (2377)
- Allow Overlay Networks (UDP 4789)
- Allow HTTP/HTTPS depending on service

### **SSH Key Injection**
The VM reads the SSH public key from Terraform:

```
metadata = {
  ssh-keys = "venki:${file("id_rsa.pub")}"
}
```

This requires Ansible to use the same private key.

---

# **5. Dynamic Inventory System**
A Python script dynamically discovers GCP instances:

### **Responsibilities:**
- Lists all instances in a project
- Detects names: `swarm-manager` and `swarm-worker-*`
- Groups hosts into `manager` and `workers`
- Attaches host variables including:
  - ansible_host
  - ansible_user
  - ansible_ssh_private_key_file

This removes the need for a static `inventory.ini` and works automatically with Terraform-created machines.

---

# **6. SSH Access Fix**
The core SSH issue was caused by:

- VM created with username `venki`
- Ansible was connecting with user `ubuntu`

Solution:
- Update dynamic inventory with:

```
ansible_user = "venki"
```
- Provide absolute SSH key path:

```
/var/lib/jenkins/workspace/test_dev2/Terraform/id_rsa
```

---

# **7. Ansible Playbook Flow**
The playbook performs these steps:

## **7.1 Manager Setup**
1. Wait for Docker daemon
2. Detect if already in swarm
3. If not → initialize swarm
4. Retrieve join token
5. Store token using `set_fact`

## **7.2 Worker Setup**
1. Wait for Docker daemon
2. Leave old swarm (ignored on error)
3. Join the Swarm using:

```
docker swarm join --token <token> <manager-ip>:2377
```

`hostvars` lookup corrected using:

```
hostvars[groups['manager'][0]]
```

## **7.3 Stack Deployment**
1. Git clone repo with stack file
2. Wait for routing mesh to initialize
3. Deploy:

```
docker stack deploy -c docker-stack.yaml mystack
```

---

# **8. Dockerfile Corrections**
Original Flask app did not bind to 0.0.0.0.

Fixed CMD:

```
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000", "--debug"]
```

This ensures Swarm ingress routing + GCP Load Balancer can reach the service.

---

# **9. Load Balancer Fix**
The ERR_EMPTY_RESPONSE was caused by:

- Container listening only on localhost
- Swarm publishing port 5000 → 8000
- Load balancer forwarding traffic to backend port

Fix:
- Ensure Flask listens on 0.0.0.0
- Ensure published ports match LB configuration

---

# **10. Final Operational Workflow**
Below is the complete order of execution:

### **Step 1 — Developer Pushes Code**
Jenkins pulls latest code.

### **Step 2 — Docker Build & Push**
Image → Google Artifact Registry.

### **Step 3 — Terraform Deploy**
Manager + workers created.

### **Step 4 — Dynamic Inventory**
Discovers fresh VMs instantly.

### **Step 5 — Ansible Configure**
- Initializes Swarm (idempotent)
- Workers join cluster
- Deploys application stack

### **Step 6 — Application Live on GCP**
Docker stack running across Swarm.

---

# **11. Troubleshooting & Fixes (Summary)**
✔ SSH key mismatch → fixed via inventory update

✔ Incorrect username → updated to `venki`

✔ Docker Swarm init error → added detection logic:
```
docker info --format '{{ .Swarm.LocalNodeState }}'
```

✔ Worker join error → fixed with correct hostvars reference

✔ Load balancer empty response → fixed Flask binding

✔ Dynamic inventory not parsing → fixed indentation + permissions

---

# **12. Final Result**
The system is now:

- **Fully automated** (CI/CD end to end)
- **Idempotent** (can re-run without breaking)
- **Dynamic** (no static inventory or IP changes)
- **Production-ready** (correct network, swarm, LB handling)
- **Scalable** (Terraform count variable supports auto-scaling workers)

---

# **13. Future Enhancements (Optional)**
- Add health checks to Docker services
- Auto-scaling workers via Terraform + Cloud Monitoring
- Enable HTTPS with managed certificates
- Add Prometheus/Grafana monitoring stack
- Add Blue/Green or Canary deployments

---

# **14. Conclusion**
This documentation covers the entire journey from initial pipeline setup to a fully automated multi-node Docker Swarm deployment on GCP managed through Jenkins, Terraform, Ansible, and GAR. It is structured for readability, printability, and professional presentation.

---

**End of Document**

