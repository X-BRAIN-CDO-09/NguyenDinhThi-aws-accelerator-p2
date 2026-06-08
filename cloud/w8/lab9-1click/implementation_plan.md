# Lab CD9 â€” 1-Click: Terraform â†’ EC2 (Minikube driver=none) â†’ ALB

## âœ… Checklist Ä‘á»‘i chiáº¿u Ä‘á» bĂ i & SÆ¡ Ä‘á»“

| # | RĂ ng buá»™c / YĂªu cáº§u trong sÆ¡ Ä‘á»“ | CĂ¡ch Ä‘Ă¡p á»©ng trong plan | Tráº¡ng thĂ¡i |
|---|---|---|:---:|
| 1 | Háº¡ táº§ng dá»±ng báº±ng **Terraform** | EC2, ALB, SG, Target Group, Key Pair â€” viáº¿t trong cĂ¡c file `.tf` | âœ… |
| 2 | Cá»¥m K8s cháº¡y báº±ng **Minikube** trĂªn EC2 | CĂ i Docker + Minikube vá»›i `--driver=none` qua `user_data.sh` | âœ… |
| 3 | App cháº¡y **trong K8s** (Nginx) | Deploy `nginx:alpine` (replicas: 1) vĂ  NodePort Service | âœ… |
| 4 | App truy cáº­p tá»« **Internet qua ALB** | ALB :80 â†’ Target Group â†’ EC2:30080 (NodePort) â†’ Pod | âœ… |
| 5 | **Má»™t lá»‡nh** dá»±ng táº¥t cáº£ (1-click) | `terraform apply` tá»± táº¡o key, EC2, ALB, tá»± cáº¥u hĂ¬nh K8s app | âœ… |
| 6 | DĂ¹ng **â‰¥2 provider** (wire provider khĂ¡c) | Provider 1: **`aws`** (háº¡ táº§ng) + Provider 2: **`tls`** (gen SSH Key Ä‘á»ƒ truyá»n vĂ o `aws_key_pair`) | âœ… |

---

## So sĂ¡nh: SÆ¡ Ä‘á»“ cá»§a báº¡n vs Báº£n káº¿ hoáº¡ch cÅ©

SÆ¡ Ä‘á»“ cá»§a báº¡n Ä‘á» xuáº¥t má»™t kiáº¿n trĂºc ráº¥t thá»±c táº¿ vĂ  á»•n Ä‘á»‹nh hÆ¡n báº£n káº¿ hoáº¡ch cÅ©. DÆ°á»›i Ä‘Ă¢y lĂ  phĂ¢n tĂ­ch chi tiáº¿t:

| TiĂªu chĂ­ | Trong SÆ¡ Ä‘á»“ cá»§a báº¡n | Báº£n káº¿ hoáº¡ch cÅ© | Æ¯u Ä‘iá»ƒm cá»§a sÆ¡ Ä‘á»“ |
| :--- | :--- | :--- | :--- |
| **Minikube Driver** | `--driver=none` | `--driver=docker` | **`--driver=none` Ä‘Æ¡n giáº£n hÆ¡n**: Minikube cháº¡y trá»±c tiáº¿p trĂªn host, tá»± Ä‘á»™ng bind port `30080` ra IP cá»§a EC2. KhĂ´ng cáº§n cĂ i `socat` hay cháº¡y port-forward ngáº§m cá»±c ká»³ dá»… lá»—i. |
| **CĂ¡ch Deploy App K8s** | DĂ¹ng **User Data** (`kubectl apply` cĂ¡c file manifest) | DĂ¹ng **Kubernetes Provider** viáº¿t báº±ng code HCL (`kubernetes.tf`) | **á»”n Ä‘á»‹nh hÆ¡n nhiá»u**: TrĂ¡nh lá»—i vĂ²ng láº·p phá»¥ thuá»™c (dependency cycle) trong Terraform khi cá»‘ gáº¯ng káº¿t ná»‘i K8s Provider vĂ o cá»¥m Minikube chÆ°a khá»Ÿi táº¡o xong. |
| **Há»‡ Ä‘iá»u hĂ nh EC2** | `Ubuntu 22.04` | `Amazon Linux 2` | Ubuntu lĂ  mĂ´i trÆ°á»ng chuáº©n vĂ  á»•n Ä‘á»‹nh nháº¥t Ä‘á»ƒ cháº¡y Minikube `--driver=none`. |
| **Providers sá»­ dá»¥ng** | `aws` + `tls` | `aws` + `kubernetes` + `tls` | Giáº£m bá»›t sá»± phá»©c táº¡p cá»§a Kubernetes Provider, váº«n Ä‘Ă¡p á»©ng yĂªu cáº§u "wire 2 providers" báº±ng cĂ¡ch dĂ¹ng `tls` Ä‘á»ƒ sinh SSH Key rá»“i truyá»n sang `aws`. |

> [!TIP]
> **Quyáº¿t Ä‘á»‹nh:** TĂ´i Ä‘Ă£ cáº­p nháº­t toĂ n bá»™ báº£n káº¿ hoáº¡ch bĂªn dÆ°á»›i theo Ä‘Ăºng **SÆ¡ Ä‘á»“** cá»§a báº¡n Ä‘á»ƒ Ä‘áº£m báº£o bĂ i lab cháº¡y mÆ°á»£t mĂ , dá»… debug vĂ  á»•n Ä‘á»‹nh nháº¥t.

---

## SÆ¡ Ä‘á»“ kiáº¿n trĂºc (Khá»›p 100% sÆ¡ Ä‘á»“ cá»§a báº¡n)

```text
  Developer (terraform init/plan/apply)
       â”‚
       â–¼
   Terraform
   â”œâ”€â”€ Provider 1: aws (AWS Cloud Infrastructure)
   â””â”€â”€ Provider 2: tls (Generate Private Key) â”€â”€â–º Wired to aws_key_pair
       â”‚
       â–¼
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ AWS Cloud â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                                                                       â”‚
â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Default VPC â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚
â”‚  â”‚                                                                 â”‚  â”‚
â”‚  â”‚  â”Œâ”€â”€ Public Subnet A (AZ-a) â”€â”€â”      â”Œâ”€â”€ Public Subnet B (AZ-b) â”€â”€â” â”‚  â”‚
â”‚  â”‚  â”‚                            â”‚      â”‚                            â”‚ â”‚  â”‚
â”‚  â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚      â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚ â”‚  â”‚
â”‚  â”‚  â”‚  â”‚ ALB (Internet-facing)â”‚â—€â”€â”¼â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”‚   Inbound: 80/tcp    â”‚  â”‚ â”‚  â”‚
â”‚  â”‚  â”‚  â”‚     Listener: :80    â”‚  â”‚      â”‚  â”‚    from 0.0.0.0/0    â”‚  â”‚ â”‚  â”‚
â”‚  â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚      â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚ â”‚  â”‚
â”‚  â”‚  â”‚             â”‚              â”‚      â”‚             â”‚ (ALB-SG)     â”‚ â”‚  â”‚
â”‚  â”‚  â”‚             â”‚ Forward      â”‚      â”‚             â”‚              â”‚ â”‚  â”‚
â”‚  â”‚  â”‚             â–¼ Port 30080   â”‚      â”‚             â–¼              â”‚ â”‚  â”‚
â”‚  â”‚  â”‚      Target Group          â”‚      â”‚      Security Group        â”‚ â”‚  â”‚
â”‚  â”‚  â”‚  Port 30080 / Health: /    â”‚      â”‚         (ALB-SG)           â”‚ â”‚  â”‚
â”‚  â”‚  â”‚             â”‚              â”‚      â”‚                            â”‚ â”‚  â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜      â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜ â”‚  â”‚
â”‚  â”‚                â”‚                                                    â”‚  â”‚
â”‚  â”‚                â–¼ Forward to port 30080                              â”‚  â”‚
â”‚  â”‚  â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ EC2 Instance â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”  â”‚  â”‚
â”‚  â”‚  â”‚             â”‚                                                 â”‚  â”‚  â”‚
â”‚  â”‚  â”‚             â–¼                                                 â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    Security Group (EC2-SG)                                    â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â€¢ Inbound: 30080/tcp from ALB-SG                           â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â€¢ Inbound: 22/tcp from MyIP                                â”‚  â”‚  â”‚
â”‚  â”‚  â”‚                                                               â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    Ubuntu 22.04 (t3.medium)                                   â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â””â”€ User Data Bootstrap:                                    â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       1. Install Docker                                       â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       2. Install kubectl                                      â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       3. Install Minikube                                     â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       4. Start Minikube (--driver=none)                       â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       5. Apply deployment.yaml (nginx:alpine, replica: 1)     â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       6. Apply service-nodeport.yaml (NodePort: 30080)        â”‚  â”‚  â”‚
â”‚  â”‚  â”‚       7. Wait for Service Ready                               â”‚  â”‚  â”‚
â”‚  â”‚  â”‚                                                               â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€ Minikube Cluster â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â”‚                                                      â”‚   â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â”‚  [Deployment: nginx:alpine] â”€â”€â–º [Service: NodePort]  â”‚   â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â”‚        (replicas: 1)              (Port: 30080)      â”‚   â”‚  â”‚  â”‚
â”‚  â”‚  â”‚    â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â”‚  â”‚  â”‚
â”‚  â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚  â”‚
â”‚  â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜

Outputs:
  â€¢ alb_dns_name = http://<alb-dns-name>  â”€â”€â–º Access from Internet
  â€¢ instance_public_ip = <public-ip-for-ssh>
```

---

## Cáº¥u trĂºc thÆ° má»¥c

ChĂºng ta sáº½ táº¡o thÆ° má»¥c `lab-cd9` vá»›i cĂ¡c file sau:

```text
lab-cd9/
â”œâ”€â”€ README.md                   # HÆ°á»›ng dáº«n vĂ  sÆ¡ Ä‘á»“ (giá»‘ng nhÆ° báº¡n yĂªu cáº§u)
â”œâ”€â”€ providers.tf                # Khai bĂ¡o AWS + TLS + Local providers
â”œâ”€â”€ variables.tf                # aws_region, instance_type, my_ip, app_port
â”œâ”€â”€ locals.tf                   # Tags chung, name_prefix
â”œâ”€â”€ data.tf                     # Data sources: Ubuntu 22.04 AMI, default VPC, Subnets
â”œâ”€â”€ security_groups.tf          # SG cho ALB vĂ  SG cho EC2
â”œâ”€â”€ key_pair.tf                 # đŸ†• Táº¡o SSH Key báº±ng TLS provider vĂ  import lĂªn AWS
â”œâ”€â”€ ec2.tf                      # Dá»±ng EC2 vĂ  náº¡p user_data.sh
â”œâ”€â”€ alb.tf                      # ALB, Target Group, Listener & Attachment
â”œâ”€â”€ outputs.tf                  # URL ALB, IP public, cĂ¢u lá»‡nh SSH debug
â””â”€â”€ scripts/
    â”œâ”€â”€ user_data.sh            # Script cĂ i Docker, Minikube vĂ  deploy app
    â”œâ”€â”€ deployment.yaml         # Manifest Deployment nginx
    â””â”€â”€ service-nodeport.yaml   # Manifest Service NodePort 30080
```

---

## Chi tiáº¿t cĂ¡c thay Ä‘á»•i (Proposed Changes)

### 1. [NEW] [providers.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/providers.tf)
Khai bĂ¡o cĂ¡c providers cáº§n thiáº¿t. á» Ä‘Ă¢y ta wire 3 provider: `aws`, `tls` (táº¡o key), `local` (lÆ°u file key).

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 2. [NEW] [variables.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/variables.tf)
CĂ¡c biáº¿n Ä‘á»ƒ dá»… tĂ¹y biáº¿n cáº¥u hĂ¬nh:
- `aws_region`: Máº·c Ä‘á»‹nh `"ap-southeast-1"`.
- `instance_type`: Máº·c Ä‘á»‹nh `"t3.medium"` (Minikube báº¯t buá»™c â‰¥ 2 vCPUs).
- `my_ip`: IP cá»§a báº¡n Ä‘á»ƒ giá»›i háº¡n quyá»n SSH báº£o máº­t.
- `app_port`: Máº·c Ä‘á»‹nh `30080` (NodePort).

### 3. [NEW] [locals.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/locals.tf)
Khai bĂ¡o cĂ¡c tags chung vĂ  tiá»n tá»‘ tĂªn resource.
```hcl
locals {
  name_prefix = "lab-cd9"
  common_tags = {
    Project     = "CD9-Automation"
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}
```

### 4. [NEW] [data.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/data.tf)
Láº¥y thĂ´ng tin Ä‘á»™ng tá»« AWS. **Quan trá»ng lĂ  dĂ¹ng Ubuntu 22.04 LTS**.
```hcl
# TĂ¬m Ubuntu 22.04 AMI má»›i nháº¥t
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Láº¥y VPC máº·c Ä‘á»‹nh
data "aws_vpc" "default" {
  default = true
}

# Láº¥y cĂ¡c Subnet trong VPC máº·c Ä‘á»‹nh (Ä‘á»ƒ ALB span qua nhiá»u AZ)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
```

### 5. [NEW] [key_pair.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/key_pair.tf)
**Minh chá»©ng wiring 2 providers (`tls` vĂ  `aws`)**: 
1. Sinh private key RSA báº±ng `tls`.
2. Truyá»n public key sang `aws_key_pair` Ä‘á»ƒ táº¡o SSH key trĂªn AWS.
3. DĂ¹ng `local_file` Ä‘á»ƒ lÆ°u private key xuá»‘ng mĂ¡y local cá»§a dev Ä‘á»ƒ SSH.

```hcl
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${local.name_prefix}-key"
  public_key = tls_private_key.ssh.public_key_openssh
  tags       = local.common_tags
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = "${path.module}/${local.name_prefix}-key.pem"
  file_permission = "0400"
}
```

### 6. [NEW] [security_groups.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/security_groups.tf)
Khai bĂ¡o Security Group:
- `alb_sg`: Má»Ÿ port 80 cho toĂ n bá»™ Internet (`0.0.0.0/0`).
- `ec2_sg`:
  - Má»Ÿ port 30080 **chá»‰ tá»« ALB SG** (Target Group forward qua Ä‘Ă¢y).
  - Má»Ÿ port 22 (SSH) tá»« `var.my_ip`.
  - Outbound: Allow All (Ä‘á»ƒ EC2 táº£i Docker/Minikube tá»« Internet).

### 7. [NEW] [scripts/deployment.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/deployment.yaml)
Manifest K8s Deployment cháº¡y app nginx Ä‘Æ¡n giáº£n.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  labels:
    app: web-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: web-app
  template:
    metadata:
      labels:
        app: web-app
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "500m"
            memory: "256Mi"
          requests:
            cpu: "100m"
            memory: "128Mi"
```

### 8. [NEW] [scripts/service-nodeport.yaml](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/service-nodeport.yaml)
Manifest K8s Service expose app qua NodePort 30080.
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
```

### 9. [NEW] [scripts/user_data.sh](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/user_data.sh)
Script tá»± Ä‘á»™ng cháº¡y khi EC2 khá»Ÿi táº¡o. Script nĂ y sáº½:
1. CĂ i Ä‘áº·t cĂ¡c thÆ° viá»‡n cáº§n thiáº¿t, Docker, kubectl vĂ  Minikube.
2. Khá»Ÿi Ä‘á»™ng Minikube vá»›i `--driver=none`.
3. Táº¡o trá»±c tiáº¿p cĂ¡c file manifest K8s (hoáº·c copy tá»« file) vĂ  cháº¡y `kubectl apply`.
4. Äá»£i cho Service K8s vĂ  Pod sáºµn sĂ ng Ä‘á»ƒ phá»¥c vá»¥.

```bash
#!/bin/bash
set -euxo pipefail

# Redirect logs Ä‘á»ƒ dá»… debug
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "=== 1. Cap nhat he thong & Cai dat Docker ==="
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release conntrack socat

# CĂ i Docker Engine
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Äáº£m báº£o docker group vĂ  permissions
systemctl enable docker
systemctl start docker

echo "=== 2. Cai dat kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/

echo "=== 3. Cai dat Minikube ==="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube

echo "=== 4. Khoi dong Minikube voi driver=none ==="
# Minikube driver=none yeu cau chay duoi quyen root va su dung Docker co san tren host
export CHANGE_MINIKUBE_NONE_USER=true
minikube start --driver=none --kubernetes-version=v1.28.3

echo "=== 5. Tao va Apply K8s Manifests ==="
# Ghi de file manifest tá»« template/heredoc (de phong viec file copy bi loi)
cat <<'EOF' > /tmp/deployment.yaml
${deployment_yaml}
EOF

cat <<'EOF' > /tmp/service-nodeport.yaml
${service_yaml}
EOF

kubectl apply -f /tmp/deployment.yaml
kubectl apply -f /tmp/service-nodeport.yaml

echo "=== 6. Doi Service san sang ==="
kubectl rollout status deployment/web-app --timeout=300s

echo "=== BOOTSTRAP HOAN TAT ==="
touch /var/log/bootstrap_done
```

### 10. [NEW] [ec2.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/ec2.tf)
Táº¡o EC2 Instance Ubuntu 22.04, truyá»n variables vĂ o `user_data.sh` thĂ´ng qua hĂ m `templatefile()` cá»§a Terraform.
CĂ³ sá»­ dá»¥ng `remote-exec` Ä‘á»ƒ Ä‘á»£i `user_data.sh` cháº¡y hoĂ n thĂ nh, trĂ¡nh trÆ°á»ng há»£p Terraform bĂ¡o apply xong nhÆ°ng Web app thá»±c táº¿ chÆ°a cháº¡y.

```hcl
resource "aws_instance" "minikube" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  subnet_id     = tolist(data.aws_subnets.default.ids)[0]
  key_name      = aws_key_pair.deployer.key_name

  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # Truyá»n manifest vĂ o user_data thĂ´ng qua templatefile
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    deployment_yaml = file("${path.module}/scripts/deployment.yaml")
    service_yaml    = file("${path.module}/scripts/service-nodeport.yaml")
  })

  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-minikube"
  })
}

# Äá»£i cho user_data script cháº¡y xong hoĂ n toĂ n
resource "null_resource" "wait_for_minikube" {
  depends_on = [aws_instance.minikube]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh.private_key_pem
    host        = aws_instance.minikube.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init (user_data) to complete...'",
      "sudo cloud-init status --wait",
      "echo '=== Kubernetes Pods ==='",
      "sudo kubectl get pods -A",
      "echo '=== Kubernetes Services ==='",
      "sudo kubectl get svc"
    ]
  }
}
```

### 11. [NEW] [alb.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/alb.tf)
Cáº¥u hĂ¬nh ALB phĂ¢n phá»‘i lÆ°u lÆ°á»£ng:
- ALB nháº­n cá»•ng `:80` tá»« Internet, chuyá»ƒn tiáº¿p vĂ o Target Group cá»•ng `:30080`.
- Target Group Ä‘á»‹nh nghÄ©a cá»•ng `:30080` (NodePort) cá»§a EC2 vĂ  cĂ³ Health Check path `/`.
- ÄĂ­nh kĂ¨m EC2 Instance vĂ o Target Group.

### 12. [NEW] [outputs.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/outputs.tf)
CĂ¡c output giĂºp báº¡n nhanh chĂ³ng sá»­ dá»¥ng:
```hcl
output "alb_dns_name" {
  description = "URL truy cap ung dung qua Internet"
  value       = "http://${aws_lb.app.dns_name}"
}

output "instance_public_ip" {
  description = "IP Public cua EC2 instance"
  value       = aws_instance.minikube.public_ip
}

output "ssh_command" {
  description = "Lenh SSH vao EC2 nhanh chong"
  value       = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.minikube.public_ip}"
}
```

---

## đŸ”— Chuá»—i phá»¥ thuá»™c & Thá»© tá»± dá»±ng (Dependency Chain)

Cáº­p nháº­t láº¡i sÆ¡ Ä‘á»“ thá»© tá»± dá»±ng vĂ¬ khĂ´ng cĂ²n dĂ¹ng Kubernetes Provider tá»« local:

```text
  data.aws_ami â”€â”€â”
  data.aws_vpc â”€â”€â”¼â”€â–º [Tá»± Ä‘á»™ng truy váº¥n thĂ´ng tin]
  data.aws_subnetsâ”˜
        â”‚
        â–¼
  tls_private_key (Táº¡o SSH key ngáº«u nhiĂªn trĂªn mĂ¡y local)
        â”‚
        â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â–¼ (Public Key)                            â–¼ (Private Key)
  aws_key_pair (ÄÄƒng kĂ½ key lĂªn AWS)         local_file (Ghi key.pem xuá»‘ng mĂ¡y local)
        â”‚                                         â”‚
        â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
        â–¼
  aws_security_group (alb_sg & ec2_sg)
        â”‚
        â”œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â–¼                                         â–¼
  aws_instance.minikube                       aws_lb.app (ALB)
  (Náº¡p user_data.sh & báº¯t Ä‘áº§u cháº¡y ngáº§m)       (Span qua 2 Subnet cĂ´ng cá»™ng)
        â”‚                                         â”‚
        â–¼                                         â–¼
  null_resource.wait_for_minikube            aws_lb_target_group (Port 30080)
  (SSH remote-exec: Ä‘á»£i cloud-init hoĂ n táº¥t)  aws_lb_listener (Port 80 -> Target Group)
        â”‚                                         â”‚
        â”‚                                         â–¼
        â”‚                              aws_lb_target_group_attachment
        â”‚                              (Gáº¯n EC2 vĂ o Target Group)
        â–¼                                         â”‚
  [K8s App Running] (Port 30080 má»Ÿ trĂªn host)     â”‚
        â”‚                                         â”‚
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                            â–¼
                     [ALB Health Check Pass]
                            â”‚
                            â–¼
              Truy cáº­p: http://<alb-dns-name>
```

---

## â ï¸ Váº¥n Ä‘á» ká»¹ thuáº­t & CĂ¡ch giáº£i quyáº¿t (Má»›i)

### Váº¥n Ä‘á» 1: Lá»—i giĂ¡n Ä‘oáº¡n do Minikube driver=none dĂ¹ng chung Docker vá»›i host
- **MĂ´ táº£**: Khi cháº¡y `--driver=none`, Minikube chia sáº» Docker daemon trá»±c tiáº¿p vá»›i há»‡ Ä‘iá»u hĂ nh Ubuntu. ÄĂ´i khi cĂ³ sá»± xung Ä‘á»™t vá» systemd/cgroup hoáº·c service Docker bá»‹ khá»Ÿi Ä‘á»™ng láº¡i giá»¯a chá»«ng khiáº¿n Minikube bá»‹ lá»—i "kubelet not healthy".
- **Giáº£i phĂ¡p**: Thiáº¿t láº­p `export CHANGE_MINIKUBE_NONE_USER=true` trÆ°á»›c khi cháº¡y `minikube start`. Sá»­ dá»¥ng phiĂªn báº£n Kubernetes vĂ  Minikube tÆ°Æ¡ng thĂ­ch á»•n Ä‘á»‹nh nháº¥t (nhÆ° `v1.28.3`) vĂ  Ä‘áº£m báº£o Docker Ä‘Æ°á»£c báº­t sáºµn sĂ ng trÆ°á»›c khi cháº¡y.

### Váº¥n Ä‘á» 2: Äá»“ng bá»™ hĂ³a quĂ¡ trĂ¬nh bootstrap
- **MĂ´ táº£**: Terraform táº¡o EC2 chá»‰ máº¥t 30 giĂ¢y vĂ  sáº½ bĂ¡o hoĂ n thĂ nh, nhÆ°ng tiáº¿n trĂ¬nh cĂ i Ä‘áº·t Docker + Minikube ngáº§m trong `user_data.sh` máº¥t 3â€“5 phĂºt. Náº¿u ngÆ°á»i dĂ¹ng truy cáº­p ngay hoáº·c Terraform káº¿t thĂºc ngay, ALB sáº½ tráº£ vá» `502 Bad Gateway` vĂ¬ Target Group chÆ°a tháº¥y cá»•ng 30080 má»Ÿ.
- **Giáº£i phĂ¡p**: Sá»­ dá»¥ng `null_resource` kĂ¨m provisioner `remote-exec` cháº¡y cĂ¢u lá»‡nh `sudo cloud-init status --wait`. Lá»‡nh nĂ y sáº½ **cháº·n (block)** tiáº¿n trĂ¬nh Terraform cho tá»›i khi script `user_data.sh` cháº¡y xong 100%. NgÆ°á»i dĂ¹ng sáº½ tháº¥y tráº¡ng thĂ¡i cháº¡y cá»¥ thá»ƒ ngay trĂªn terminal.

---

## Verification Plan

### Manual Verification
1. Cháº¡y lá»‡nh:
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
2. Äá»£i cho Ä‘áº¿n khi quĂ¡ trĂ¬nh `apply` hoĂ n táº¥t (nĂ³ sáº½ Ä‘á»©ng Ä‘á»£i khoáº£ng 3-4 phĂºt á»Ÿ bÆ°á»›c `null_resource.wait_for_minikube`).
3. Sau khi hoĂ n thĂ nh, copy URL tá»« `alb_dns_name` dĂ¡n vĂ o trĂ¬nh duyá»‡t â†’ Nháº­n Ä‘Æ°á»£c trang chĂ o má»«ng cá»§a Nginx.
4. Cháº¡y cĂ¢u lá»‡nh `ssh_command` Ä‘Æ°á»£c xuáº¥t ra Ä‘á»ƒ SSH vĂ o EC2 kiá»ƒm tra logs náº¿u cáº§n:
   ```bash
   sudo cat /var/log/user-data.log  # Xem logs qua trinh bootstrap
   kubectl get pods -A              # Xem trang thai cac Pod
   ```
5. Cháº¡y `terraform destroy` Ä‘á»ƒ thu há»“i toĂ n bá»™ tĂ i nguyĂªn trĂ¡nh phĂ¡t sinh chi phĂ­.