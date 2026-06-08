# đŸ“ TĂ i Liá»‡u Ă”n Táº­p: LAB CD9 â€” 1-Click Automation

TĂ i liá»‡u nĂ y tá»•ng há»£p toĂ n bá»™ kiáº¿n thá»©c báº¡n cáº§n náº¯m vá»¯ng Ä‘á»ƒ tá»± tin thuyáº¿t trĂ¬nh vĂ  tráº£ lá»i má»i cĂ¢u há»i vá» bĂ i Lab CD9.

---

## Pháº§n 1: Terraform â€” CĂ´ng Cá»¥ Tá»± Äá»™ng HĂ³a Háº¡ Táº§ng

### 1.1. Terraform lĂ  gĂ¬?
- LĂ  cĂ´ng cá»¥ **Infrastructure as Code (IaC)** cá»§a HashiCorp.
- Cho phĂ©p báº¡n viáº¿t code (ngĂ´n ngá»¯ HCL) Ä‘á»ƒ mĂ´ táº£ háº¡ táº§ng, sau Ä‘Ă³ Terraform tá»± Ä‘á»™ng dá»±ng/xĂ³a háº¡ táº§ng cho báº¡n.
- **Declarative (Khai bĂ¡o):** Báº¡n chá»‰ cáº§n mĂ´ táº£ tráº¡ng thĂ¡i mong muá»‘n, Terraform tá»± tĂ¬m cĂ¡ch thá»±c hiá»‡n.

### 1.2. CĂ¡c lá»‡nh cÆ¡ báº£n (Pháº£i thuá»™c!)
| Lá»‡nh | Má»¥c Ä‘Ă­ch |
|---|---|
| `terraform init` | Táº£i cĂ¡c Provider cáº§n thiáº¿t, khá»Ÿi táº¡o thÆ° má»¥c `.terraform` |
| `terraform plan` | Xem trÆ°á»›c nhá»¯ng gĂ¬ Terraform sáº½ táº¡o/sá»­a/xĂ³a (dry-run) |
| `terraform apply` | Thá»±c thi káº¿ hoáº¡ch, dá»±ng háº¡ táº§ng tháº­t trĂªn cloud |
| `terraform destroy` | XĂ³a sáº¡ch toĂ n bá»™ háº¡ táº§ng Ä‘Ă£ táº¡o |
| `terraform state list` | Liá»‡t kĂª táº¥t cáº£ tĂ i nguyĂªn Ä‘ang Ä‘Æ°á»£c Terraform quáº£n lĂ½ |
| `terraform state rm <resource>` | Loáº¡i bá» 1 tĂ i nguyĂªn khá»i state (khĂ´ng xĂ³a trĂªn cloud) |

### 1.3. Terraform State (`terraform.tfstate`) lĂ  gĂ¬?
- LĂ  file JSON lÆ°u trá»¯ **tráº¡ng thĂ¡i hiá»‡n táº¡i** cá»§a toĂ n bá»™ háº¡ táº§ng mĂ  Terraform Ä‘ang quáº£n lĂ½.
- Má»—i láº§n cháº¡y `plan` hoáº·c `apply`, Terraform so sĂ¡nh **code má»›i** vá»›i **state cÅ©** Ä‘á»ƒ tĂ¬m ra sá»± khĂ¡c biá»‡t cáº§n thá»±c hiá»‡n.
- **Quan trá»ng:** Náº¿u xĂ³a file nĂ y, Terraform sáº½ "quĂªn" háº¿t táº¥t cáº£ tĂ i nguyĂªn vĂ  táº¡o má»›i láº¡i tá»« Ä‘áº§u (tĂ i nguyĂªn cÅ© váº«n cháº¡y trĂªn AWS nhÆ°ng Terraform khĂ´ng biáº¿t).

### 1.4. Provider lĂ  gĂ¬? BĂ i lab dĂ¹ng bao nhiĂªu Provider?
- Provider lĂ  **plugin káº¿t ná»‘i** giĂºp Terraform giao tiáº¿p vá»›i cĂ¡c ná»n táº£ng bĂªn ngoĂ i (AWS, Kubernetes, v.v.).
- BĂ i lab sá»­ dá»¥ng **5 Provider**:

| Provider | Vai trĂ² | File khai bĂ¡o |
|---|---|---|
| **aws** | Táº¡o/quáº£n lĂ½ tĂ i nguyĂªn trĂªn AWS (VPC, EC2, ALB...) | `providers.tf` |
| **tls** | Sinh cáº·p khĂ³a SSH Private/Public key tá»± Ä‘á»™ng | `key_pair.tf` |
| **kubernetes** | Káº¿t ná»‘i qua proxy 8081 Ä‘á»ƒ táº¡o Namespace, Deployment, Service | `kubernetes.tf` |
| **local** | Ghi file private key `.pem` xuá»‘ng mĂ¡y tĂ­nh cá»§a báº¡n | `key_pair.tf` |
| **null** | Cháº¡y script SSH kiá»ƒm tra EC2 Ä‘Ă£ sáºµn sĂ ng chÆ°a (`null_resource`) | `ec2.tf` |

### 1.5. CĂ¡c khĂ¡i niá»‡m HCL quan trá»ng
| KhĂ¡i niá»‡m | Giáº£i thĂ­ch | VĂ­ dá»¥ trong lab |
|---|---|---|
| `resource` | Khai bĂ¡o 1 tĂ i nguyĂªn cáº§n táº¡o | `resource "aws_vpc" "main" { ... }` |
| `data` | Truy váº¥n dá»¯ liá»‡u cĂ³ sáºµn (khĂ´ng táº¡o má»›i) | `data "aws_ami" "ubuntu" { ... }` â€” TĂ¬m AMI Ubuntu má»›i nháº¥t |
| `variable` | Biáº¿n Ä‘áº§u vĂ o Ä‘á»ƒ tĂ¹y chá»‰nh | `var.aws_region`, `var.app_port` |
| `locals` | GiĂ¡ trá»‹ tĂ­nh toĂ¡n ná»™i bá»™, dĂ¹ng láº¡i nhiá»u láº§n | `local.name_prefix = "lab-cd9"` |
| `output` | Xuáº¥t káº¿t quáº£ sau khi apply xong | `output "alb_dns_name"` |
| `depends_on` | RĂ ng buá»™c thá»© tá»± táº¡o/xĂ³a tĂ i nguyĂªn | Namespace phá»¥ thuá»™c vĂ o IGW vĂ  Route Table |
| `templatefile()` | Äá»c file vĂ  thay tháº¿ biáº¿n bĂªn trong | `templatefile("scripts/user_data.sh", { proxy_port = 8081 })` |

---

## Pháº§n 2: AWS â€” Háº¡ Táº§ng Cloud

### 2.1. VPC (Virtual Private Cloud)
- LĂ  **máº¡ng áº£o riĂªng** cá»§a báº¡n trĂªn AWS, hoĂ n toĂ n cĂ¡ch ly vá»›i cĂ¡c tĂ i khoáº£n khĂ¡c.
- CIDR trong lab: `10.0.0.0/16` â€” nghÄ©a lĂ  cĂ³ tá»•ng cá»™ng 65,536 Ä‘á»‹a chá»‰ IP kháº£ dá»¥ng.
- File cáº¥u hĂ¬nh: `vpc.tf`

### 2.2. Subnet (Máº¡ng con)
- LĂ  **phĂ¢n vĂ¹ng nhá» hÆ¡n** bĂªn trong VPC.
- Lab sá»­ dá»¥ng **2 Public Subnet** á»Ÿ 2 vĂ¹ng kháº£ dá»¥ng (AZ) khĂ¡c nhau:
  - **Subnet A** (`10.0.1.0/24`) â€” AZ `ap-southeast-1a` â€” Cháº¡y EC2 vĂ  ALB.
  - **Subnet B** (`10.0.2.0/24`) â€” AZ `ap-southeast-1b` â€” Cháº¡y ALB (Ä‘áº£m báº£o High Availability).
- **Táº¡i sao cáº§n 2 Subnet?** AWS yĂªu cáº§u ALB pháº£i gáº¯n vĂ o **Ă­t nháº¥t 2 Subnet thuá»™c 2 AZ khĂ¡c nhau** Ä‘á»ƒ Ä‘áº£m báº£o tĂ­nh sáºµn sĂ ng cao (HA).

### 2.3. Internet Gateway (IGW)
- LĂ  **cá»•ng káº¿t ná»‘i** giá»¯a VPC vĂ  Internet bĂªn ngoĂ i.
- Náº¿u khĂ´ng cĂ³ IGW, cĂ¡c mĂ¡y chá»§ bĂªn trong VPC sáº½ **khĂ´ng thá»ƒ** truy cáº­p hoáº·c bá»‹ truy cáº­p tá»« Internet.

### 2.4. Route Table (Báº£ng Ä‘á»‹nh tuyáº¿n)
- Chá»©a cĂ¡c **quy táº¯c Ä‘iá»u hÆ°á»›ng traffic** trong VPC.
- Trong lab: Má»i traffic Ä‘i ra ngoĂ i (`0.0.0.0/0`) sáº½ Ä‘Æ°á»£c chuyá»ƒn qua Internet Gateway.
- Route Table Ä‘Æ°á»£c **liĂªn káº¿t (associate)** vá»›i cáº£ 2 Subnet A vĂ  B.

### 2.5. Security Group (NhĂ³m báº£o máº­t)
- Hoáº¡t Ä‘á»™ng nhÆ° **tÆ°á»ng lá»­a áº£o** kiá»ƒm soĂ¡t traffic vĂ o/ra cho tá»«ng tĂ i nguyĂªn.
- Lab cĂ³ **2 Security Group**:

| Security Group | Inbound (VĂ o) | Outbound (Ra) |
|---|---|---|
| **ALB-SG** | Port 80 (HTTP) tá»« `0.0.0.0/0` (toĂ n bá»™ Internet) | Táº¥t cáº£ |
| **EC2-SG** | Port 30080 (NodePort) chá»‰ tá»« ALB-SG | Táº¥t cáº£ |
| | Port 22 (SSH) chá»‰ tá»« `var.my_ip` | |
| | Port 8081 (K8s Proxy) chá»‰ tá»« `var.my_ip` | |

- **CĂ¢u há»i hay gáº·p:** *Táº¡i sao EC2 khĂ´ng má»Ÿ port 30080 cho `0.0.0.0/0`?*
  - VĂ¬ ngÆ°á»i dĂ¹ng khĂ´ng truy cáº­p trá»±c tiáº¿p vĂ o EC2. Há» truy cáº­p qua ALB (port 80), ALB sáº½ forward tá»›i EC2 (port 30080). NĂªn chá»‰ cáº§n cho phĂ©p ALB-SG káº¿t ná»‘i tá»›i port 30080 lĂ  Ä‘á»§.

### 2.6. EC2 Instance (MĂ¡y chá»§ áº£o)
- Loáº¡i instance: **t3.medium** (2 vCPU, 4GB RAM) â€” Ä‘á»§ sá»©c cháº¡y Kind Cluster.
- AMI: **Ubuntu 22.04 LTS** (tĂ¬m tá»± Ä‘á»™ng báº±ng `data "aws_ami"`).
- **User Data (`user_data.sh`):** Script tá»± Ä‘á»™ng cháº¡y khi EC2 khá»Ÿi Ä‘á»™ng láº§n Ä‘áº§u:
  1. CĂ i Docker Engine
  2. CĂ i kubectl
  3. CĂ i Kind
  4. Táº¡o Kind Cluster vá»›i cáº¥u hĂ¬nh NodePort 30080
  5. Khá»Ÿi Ä‘á»™ng `kubectl proxy` trĂªn port 8081

### 2.7. Application Load Balancer (ALB)
- LĂ  bá»™ **cĂ¢n báº±ng táº£i táº§ng á»©ng dá»¥ng** (Layer 7 â€” HTTP/HTTPS).
- Nháº­n request tá»« Internet (port 80) vĂ  phĂ¢n phá»‘i tá»›i Target Group.
- **Target Group:** NhĂ³m cĂ¡c mĂ¡y chá»§ Ä‘Ă­ch. Trong lab, Target Group chá»‰ chá»©a 1 EC2, trá» vĂ o port 30080.
- **Health Check:** ALB Ä‘á»‹nh ká»³ gá»­i request tá»›i `/` trĂªn port 30080 Ä‘á»ƒ kiá»ƒm tra xem á»©ng dá»¥ng cĂ²n sá»‘ng khĂ´ng.

### 2.8. Key Pair (Cáº·p khĂ³a SSH)
- **TLS Provider** sinh ra cáº·p khĂ³a RSA 4096-bit.
- **Public key** Ä‘Æ°á»£c Ä‘Äƒng kĂ½ lĂªn AWS (`aws_key_pair`) vĂ  gáº¯n vĂ o EC2.
- **Private key** Ä‘Æ°á»£c ghi xuá»‘ng file `lab-cd9-key.pem` trĂªn mĂ¡y local (báº±ng `local_file`).
- Khi SSH vĂ o EC2, báº¡n dĂ¹ng file `.pem` nĂ y Ä‘á»ƒ xĂ¡c thá»±c.

---

## Pháº§n 3: Kubernetes â€” Äiá»u Phá»‘i Container

### 3.1. Kubernetes (K8s) lĂ  gĂ¬?
- LĂ  há»‡ thá»‘ng **Ä‘iá»u phá»‘i container** mĂ£ nguá»“n má»Ÿ, giĂºp tá»± Ä‘á»™ng hĂ³a viá»‡c triá»ƒn khai, má»Ÿ rá»™ng vĂ  quáº£n lĂ½ cĂ¡c á»©ng dá»¥ng cháº¡y trong container.

### 3.2. Kind lĂ  gĂ¬? Táº¡i sao dĂ¹ng Kind thay Minikube?
- **Kind (Kubernetes in Docker):** Cháº¡y cá»¥m Kubernetes bĂªn trong Docker container.
- **Minikube:** Cháº¡y Kubernetes báº±ng VM hoáº·c trá»±c tiáº¿p trĂªn host (`--driver=none`).
- **LĂ½ do chá»n Kind:**
  - Minikube vá»›i `--driver=none` thÆ°á»ng gáº·p lá»—i phĂ¢n quyá»n Docker vĂ  Systemd trĂªn Ubuntu 22.04.
  - Kind nháº¹ hÆ¡n, khá»Ÿi Ä‘á»™ng nhanh hÆ¡n vĂ  á»•n Ä‘á»‹nh hÆ¡n trĂªn mĂ´i trÆ°á»ng EC2.
  - Vá» máº·t chá»©c nÄƒng, cáº£ hai Ä‘á»u cung cáº¥p má»™t cá»¥m K8s chuáº©n.

### 3.3. CĂ¡c khĂ¡i niá»‡m K8s trong bĂ i lab (Pháº£i thuá»™c!)

| KhĂ¡i niá»‡m | Giáº£i thĂ­ch | Trong bĂ i lab |
|---|---|---|
| **Node** | MĂ¡y chá»§ cháº¡y Kubernetes (pháº§n cá»©ng/VM) | EC2 Instance chĂ­nh lĂ  Node |
| **Pod** | ÄÆ¡n vá»‹ nhá» nháº¥t cháº¡y á»©ng dá»¥ng, bá»c 1 hoáº·c nhiá»u Container | Pod chá»©a container Nginx |
| **Namespace** | "PhĂ²ng lĂ m viá»‡c riĂªng" Ä‘á»ƒ gom nhĂ³m tĂ i nguyĂªn, trĂ¡nh xung Ä‘á»™t tĂªn | `lab-cd9` |
| **ConfigMap** | LÆ°u trá»¯ dá»¯ liá»‡u cáº¥u hĂ¬nh/file tÄ©nh bĂªn ngoĂ i container | `web-html` chá»©a file `index.html` |
| **Deployment** | Quáº£n lĂ½ vĂ²ng Ä‘á»i Pod (táº¡o, cáº­p nháº­t, rollback, scale) | `web-app` vá»›i `replicas: 1` |
| **Service** | Expose á»©ng dá»¥ng ra ngoĂ i, cung cáº¥p IP/Port á»•n Ä‘á»‹nh | `web-service` kiá»ƒu NodePort trĂªn port `30080` |

### 3.4. Service NodePort lĂ  gĂ¬?
- **NodePort** lĂ  má»™t loáº¡i Service trong K8s cho phĂ©p truy cáº­p á»©ng dá»¥ng tá»« bĂªn ngoĂ i cluster thĂ´ng qua má»™t port cá»‘ Ä‘á»‹nh trĂªn Node.
- Dáº£i port NodePort: `30000â€“32767`.
- Trong lab: Port `30080` trĂªn EC2 (Node) sáº½ chuyá»ƒn tiáº¿p traffic vĂ o Port `80` cá»§a Pod Nginx.

### 3.5. kubectl proxy lĂ  gĂ¬?
- LĂ  lá»‡nh táº¡o má»™t **cá»•ng káº¿t ná»‘i táº¡m thá»i** (proxy) tá»« bĂªn ngoĂ i vĂ o Kubernetes API Server.
- Trong lab: `kubectl proxy --port=8081` má»Ÿ cá»•ng `8081` trĂªn EC2 Ä‘á»ƒ Terraform (tá»« mĂ¡y local) cĂ³ thá»ƒ gá»i K8s API Ä‘á»ƒ táº¡o Deployment, Service, v.v.

---

## Pháº§n 4: Luá»“ng Hoáº¡t Äá»™ng (Flow) â€” Pháº£i giáº£i thĂ­ch Ä‘Æ°á»£c!

### 4.1. Luá»“ng Triá»ƒn Khai (Apply â€” Chiá»u xuĂ´i)
```
terraform apply
    â†“
[1] Táº¡o VPC + Subnet + IGW + Route Table (Máº¡ng)
    â†“
[2] Táº¡o Security Groups (TÆ°á»ng lá»­a)
    â†“
[3] Sinh SSH Key (TLS Provider) + Ghi file .pem (Local Provider)
    â†“
[4] Táº¡o EC2 Instance â†’ Cháº¡y user_data.sh (Docker â†’ Kind â†’ kubectl proxy)
    â†“
[5] null_resource kiá»ƒm tra proxy 8081 sáºµn sĂ ng
    â†“
[6] Kubernetes Provider káº¿t ná»‘i qua proxy â†’ Táº¡o Namespace â†’ ConfigMap â†’ Deployment â†’ Service
    â†“
[7] Táº¡o ALB + Target Group + Listener (song song vá»›i bÆ°á»›c 4-6)
    â†“
âœ… HoĂ n táº¥t! Truy cáº­p http://<alb-dns-name>
```

### 4.2. Luá»“ng Request cá»§a NgÆ°á»i DĂ¹ng
```
TrĂ¬nh duyá»‡t â†’ http://<alb-dns-name>:80
    â†“
Internet Gateway (IGW)
    â†“
Application Load Balancer (ALB) â€” Port 80
    â†“
Target Group â†’ Forward tá»›i EC2:30080
    â†“
EC2 (Node) nháº­n traffic á»Ÿ port 30080
    â†“
Kind Cluster â†’ Service (NodePort 30080) â†’ Pod (Nginx:80)
    â†“
Nginx Ä‘á»c file index.html tá»« ConfigMap â†’ Tráº£ vá» trang web
```

### 4.3. Luá»“ng Há»§y Bá» (Destroy â€” Chiá»u ngÆ°á»£c, nhá» depends_on)
```
terraform destroy
    â†“
[1] XĂ³a Service â†’ Deployment â†’ ConfigMap â†’ Namespace (K8s)
    â†“  â† LĂºc nĂ y máº¡ng AWS váº«n sá»‘ng, proxy 8081 váº«n thĂ´ng
[2] XĂ³a null_resource, EC2 Instance
    â†“  â† EC2 táº¯t â†’ Kind Cluster biáº¿n máº¥t
[3] XĂ³a Route Table Associations
    â†“
[4] XĂ³a Route Table, Internet Gateway
    â†“
[5] XĂ³a Subnet, ALB, Security Groups
    â†“
[6] XĂ³a VPC
    â†“
âœ… Dá»n sáº¡ch! KhĂ´ng bá»‹ treo!
```

---

## Pháº§n 5: Váº¥n Äá» `depends_on` â€” CĂ¢u há»i nĂ¢ng cao hay gáº·p

### 5.1. Váº¥n Ä‘á» gá»‘c (Deadlock khi Destroy)
- Khi khĂ´ng cĂ³ `depends_on`, Terraform xĂ³a tĂ i nguyĂªn theo thá»© tá»± tĂ¹y Ă½.
- NĂ³ cĂ³ thá»ƒ xĂ³a Internet Gateway vĂ  Route Table **trÆ°á»›c** khi xĂ³a xong Namespace K8s.
- Háº­u quáº£: ÄÆ°á»ng máº¡ng bá»‹ ngáº¯t â†’ Terraform khĂ´ng thá»ƒ káº¿t ná»‘i proxy 8081 Ä‘á»ƒ gá»i API xĂ³a Namespace â†’ Bá»‹ treo vĂ´ háº¡n.

### 5.2. Giáº£i phĂ¡p
```hcl
resource "kubernetes_namespace_v1" "web" {
  depends_on = [
    null_resource.wait_for_minikube,
    aws_route_table_association.public_a,
    aws_route_table_association.public_b,
    aws_route_table.public,
    aws_internet_gateway.gw
  ]
}
```
- `depends_on` Ă©p Terraform **táº¡o** Namespace **sau** khi máº¡ng sáºµn sĂ ng.
- NgÆ°á»£c láº¡i khi destroy, Terraform **xĂ³a** Namespace **trÆ°á»›c** khi ngáº¯t máº¡ng.
- Káº¿t quáº£: QuĂ¡ trĂ¬nh xĂ³a K8s diá»…n ra khi proxy váº«n hoáº¡t Ä‘á»™ng â†’ Destroy hoĂ n táº¥t trong vĂ²ng 1 phĂºt.

---

## Pháº§n 6: CĂ¢u Há»i ThÆ°á»ng Gáº·p Khi Thuyáº¿t TrĂ¬nh (Q&A)

### CĂ¢u há»i vá» Terraform
> **Q: Táº¡i sao dĂ¹ng Terraform mĂ  khĂ´ng dĂ¹ng AWS Console (giao diá»‡n web)?**
> A: Terraform cho phĂ©p tá»± Ä‘á»™ng hĂ³a 100%, cĂ³ thá»ƒ tĂ¡i sá»­ dá»¥ng code, version control báº±ng Git, vĂ  Ä‘áº£m báº£o tĂ­nh nháº¥t quĂ¡n (má»—i láº§n cháº¡y Ä‘á»u cho ra káº¿t quáº£ giá»‘ng nhau). DĂ¹ng Console thĂ¬ pháº£i click thá»§ cĂ´ng tá»«ng bÆ°á»›c, dá»… sai sĂ³t vĂ  khĂ´ng láº·p láº¡i Ä‘Æ°á»£c.

> **Q: `terraform plan` khĂ¡c `terraform apply` tháº¿ nĂ o?**
> A: `plan` chá»‰ xem trÆ°á»›c (dry-run), khĂ´ng thay Ä‘á»•i gĂ¬ trĂªn cloud. `apply` má»›i thá»±c sá»± táº¡o/sá»­a/xĂ³a tĂ i nguyĂªn.

> **Q: Náº¿u xĂ³a file `terraform.tfstate` thĂ¬ sao?**
> A: Terraform sáº½ "máº¥t trĂ­ nhá»›", khĂ´ng biáº¿t háº¡ táº§ng nĂ o Ä‘ang cháº¡y trĂªn AWS. Láº§n cháº¡y `apply` tiáº¿p theo, nĂ³ sáº½ cá»‘ táº¡o má»›i táº¥t cáº£ â†’ Bá»‹ lá»—i trĂ¹ng tĂªn tĂ i nguyĂªn trĂªn AWS.

### CĂ¢u há»i vá» AWS
> **Q: Táº¡i sao cáº§n 2 Subnet?**
> A: AWS yĂªu cáº§u ALB pháº£i gáº¯n vĂ o Ă­t nháº¥t 2 Subnet thuá»™c 2 Availability Zone khĂ¡c nhau Ä‘á»ƒ Ä‘áº£m báº£o tĂ­nh sáºµn sĂ ng cao (High Availability). Náº¿u AZ-a bá»‹ sáº­p, ALB váº«n hoáº¡t Ä‘á»™ng á»Ÿ AZ-b.

> **Q: Security Group khĂ¡c gĂ¬ vá»›i Firewall truyá»n thá»‘ng?**
> A: Security Group lĂ  tÆ°á»ng lá»­a áº£o hoáº¡t Ä‘á»™ng á»Ÿ cáº¥p Ä‘á»™ instance (gáº¯n trá»±c tiáº¿p vĂ o EC2/ALB). NĂ³ lĂ  **stateful** â€” nghÄ©a lĂ  náº¿u cho phĂ©p traffic vĂ o, response tá»± Ä‘á»™ng Ä‘Æ°á»£c cho phĂ©p Ä‘i ra mĂ  khĂ´ng cáº§n khai bĂ¡o thĂªm rule outbound.

> **Q: ALB khĂ¡c gĂ¬ NLB?**
> A: ALB (Application Load Balancer) hoáº¡t Ä‘á»™ng á»Ÿ Layer 7 (HTTP/HTTPS), hiá»ƒu Ä‘Æ°á»£c URL, header, cookie. NLB (Network Load Balancer) hoáº¡t Ä‘á»™ng á»Ÿ Layer 4 (TCP/UDP), nhanh hÆ¡n nhÆ°ng khĂ´ng hiá»ƒu ná»™i dung HTTP.

### CĂ¢u há»i vá» Kubernetes
> **Q: Pod khĂ¡c gĂ¬ Container?**
> A: Container lĂ  tiáº¿n trĂ¬nh cháº¡y á»©ng dá»¥ng (vĂ­ dá»¥: Nginx). Pod lĂ  lá»›p bá»c bĂªn ngoĂ i Container, cung cáº¥p IP riĂªng vĂ  quáº£n lĂ½ vĂ²ng Ä‘á»i. Má»™t Pod cĂ³ thá»ƒ chá»©a nhiá»u Container chia sáº» cĂ¹ng network vĂ  storage.

> **Q: Táº¡i sao dĂ¹ng ConfigMap thay vĂ¬ build HTML vĂ o Docker Image?**
> A: Äá»ƒ tĂ¡ch biá»‡t code vĂ  cáº¥u hĂ¬nh. Khi cáº§n sá»­a giao diá»‡n, chá»‰ cáº§n cáº­p nháº­t ConfigMap mĂ  khĂ´ng pháº£i build láº¡i Docker Image (tiáº¿t kiá»‡m 2-3 phĂºt má»—i láº§n sá»­a).

> **Q: NodePort khĂ¡c gĂ¬ ClusterIP vĂ  LoadBalancer?**
> A: ClusterIP chá»‰ truy cáº­p Ä‘Æ°á»£c tá»« bĂªn trong cluster. NodePort má»Ÿ port trĂªn Node Ä‘á»ƒ truy cáº­p tá»« bĂªn ngoĂ i (dáº£i 30000-32767). LoadBalancer tá»± Ä‘á»™ng táº¡o Load Balancer trĂªn cloud provider (nhÆ°ng trong lab ta Ä‘Ă£ dĂ¹ng ALB riĂªng nĂªn chá»n NodePort).

### CĂ¢u há»i vá» Báº£o máº­t
> **Q: Hacker láº¥y Ä‘Æ°á»£c file SSH key .pem thĂ¬ cĂ³ vĂ o Ä‘Æ°á»£c EC2 khĂ´ng?**
> A: Náº¿u báº¡n Ä‘áº·t biáº¿n `my_ip` Ä‘Ăºng IP cá»§a mĂ¬nh (thay vĂ¬ `0.0.0.0/0`), thĂ¬ KHĂ”NG. Security Group cá»§a EC2 sáº½ cháº·n má»i káº¿t ná»‘i SSH tá»« IP khĂ´ng khá»›p, dĂ¹ cĂ³ Ä‘Ăºng key cÅ©ng khĂ´ng vĂ o Ä‘Æ°á»£c.

> **Q: Táº¡i sao khĂ´ng dĂ¹ng HTTPS?**
> A: HTTPS cáº§n chá»©ng chá»‰ SSL tá»« AWS ACM, mĂ  ACM yĂªu cáº§u pháº£i cĂ³ tĂªn miá»n riĂªng (domain). BĂ i lab dĂ¹ng URL máº·c Ä‘á»‹nh cá»§a ALB nĂªn khĂ´ng thá»ƒ cáº¥p SSL. Vá»›i má»¥c Ä‘Ă­ch há»c táº­p, HTTP lĂ  Ä‘á»§.

---

## Pháº§n 7: Cáº¥u TrĂºc File Dá»± Ăn (Pháº£i nhá»› má»—i file lĂ m gĂ¬!)

| File | Má»¥c Ä‘Ă­ch |
|---|---|
| `providers.tf` | Khai bĂ¡o 4 provider (AWS, TLS, Local, Kubernetes) vĂ  cáº¥u hĂ¬nh káº¿t ná»‘i |
| `variables.tf` | Khai bĂ¡o cĂ¡c biáº¿n Ä‘áº§u vĂ o (region, instance type, IP, port) |
| `locals.tf` | Äá»‹nh nghÄ©a giĂ¡ trá»‹ tĂ¡i sá»­ dá»¥ng (name prefix, common tags) |
| `data.tf` | Truy váº¥n AMI Ubuntu 22.04 má»›i nháº¥t tá»« AWS |
| `vpc.tf` | Táº¡o VPC, Subnet A/B, IGW, Route Table vĂ  liĂªn káº¿t |
| `security_groups.tf` | Táº¡o 2 Security Group cho ALB vĂ  EC2 |
| `key_pair.tf` | Sinh SSH key, Ä‘Äƒng kĂ½ lĂªn AWS, ghi file .pem |
| `ec2.tf` | Táº¡o EC2 Instance vĂ  null_resource kiá»ƒm tra proxy |
| `alb.tf` | Táº¡o ALB, Target Group, Listener vĂ  gáº¯n EC2 |
| `kubernetes.tf` | Táº¡o Namespace, ConfigMap, Deployment, Service (cĂ³ depends_on) |
| `outputs.tf` | Xuáº¥t URL ALB, IP EC2, lá»‡nh SSH, link proxy |
| `scripts/user_data.sh` | Script bootstrap cĂ i Docker, Kind, kubectl, táº¡o cluster, cháº¡y proxy |
| `scripts/index.html` | Trang giao diá»‡n web tĂ¹y chá»‰nh cá»§a báº¡n |

---

## Pháº§n 8: Code Thá»±c Táº¿ â€” Giáº£i ThĂ­ch Tá»«ng DĂ²ng

### 8.1. EC2 Instance (`ec2.tf`)
```hcl
resource "aws_instance" "minikube" {
  ami           = data.aws_ami.ubuntu.id        # AMI Ubuntu 22.04 (truy váº¥n tá»± Ä‘á»™ng tá»« data source)
  instance_type = var.instance_type             # t3.medium (2 vCPU, 4GB RAM)
  key_name      = aws_key_pair.deployer.key_name # Gáº¯n SSH public key vĂ o EC2
  subnet_id     = aws_subnet.public_a.id         # Äáº·t EC2 trong Subnet A (cĂ³ public IP)

  vpc_security_group_ids = [aws_security_group.ec2_sg.id] # Gáº¯n tÆ°á»ng lá»­a EC2-SG

  # Äá»c file user_data.sh vĂ  truyá»n biáº¿n proxy_port = 8081 vĂ o bĂªn trong script
  user_data = templatefile("${path.module}/scripts/user_data.sh", {
    proxy_port = var.proxy_port
  })

  root_block_device {
    volume_size           = 20    # á»” cá»©ng 20GB
    volume_type           = "gp3" # Loáº¡i á»• SSD hiá»‡u suáº¥t cao
    delete_on_termination = true  # Tá»± xĂ³a á»• cá»©ng khi EC2 bá»‹ há»§y
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-minikube"  # TĂªn hiá»ƒn thá»‹: "lab-cd9-minikube"
  })
}
```

**CĂ¡c Ä‘iá»ƒm cáº§n náº¯m:**
- `data.aws_ami.ubuntu.id` â€” Tham chiáº¿u Ä‘áº¿n káº¿t quáº£ cá»§a data source, tráº£ vá» ID cá»§a AMI Ubuntu má»›i nháº¥t.
- `templatefile()` â€” HĂ m Ä‘á»c file script vĂ  thay tháº¿ `${proxy_port}` bĂªn trong báº±ng giĂ¡ trá»‹ thá»±c (8081).
- `merge()` â€” HĂ m gá»™p 2 map láº¡i vá»›i nhau (gá»™p common_tags + tag Name riĂªng).
- `${path.module}` â€” Biáº¿n Ä‘áº·c biá»‡t cá»§a Terraform, tráº£ vá» Ä‘Æ°á»ng dáº«n tá»›i thÆ° má»¥c chá»©a file `.tf` hiá»‡n táº¡i.

### 8.2. null_resource (`ec2.tf`)
```hcl
resource "null_resource" "wait_for_minikube" {
  depends_on = [aws_instance.minikube]  # Chá»‰ cháº¡y SAU KHI EC2 Ä‘Ă£ Ä‘Æ°á»£c táº¡o

  connection {
    type        = "ssh"                              # Káº¿t ná»‘i báº±ng giao thá»©c SSH
    user        = "ubuntu"                           # User máº·c Ä‘á»‹nh cá»§a Ubuntu AMI
    private_key = tls_private_key.ssh.private_key_pem # DĂ¹ng key vá»«a sinh tá»« TLS provider
    host        = aws_instance.minikube.public_ip    # IP cĂ´ng khai cá»§a EC2
  }

  provisioner "remote-exec" {   # Cháº¡y lá»‡nh TRĂN MĂY EC2 (khĂ´ng pháº£i mĂ¡y local)
    inline = [
      "sudo cloud-init status --wait",   # Äá»£i user_data.sh cháº¡y xong
      "until curl -s http://localhost:${var.proxy_port}/api/v1/namespaces > /dev/null 2>&1; do sleep 5; done",
      # â†‘ LiĂªn tá»¥c thá»­ gá»i API proxy cho Ä‘áº¿n khi nĂ³ pháº£n há»“i thĂ nh cĂ´ng
    ]
  }
}
```

### 8.3. Kubernetes Deployment (`kubernetes.tf`)
```hcl
resource "kubernetes_deployment_v1" "web" {
  metadata {
    name      = "web-app"                                      # TĂªn cá»§a Deployment
    namespace = kubernetes_namespace_v1.web.metadata[0].name   # Thuá»™c namespace lab-cd9
    labels    = { app = "web-app" }                            # NhĂ£n Ä‘á»ƒ liĂªn káº¿t vá»›i Service
  }

  spec {
    replicas = 1  # Sá»‘ lÆ°á»£ng Pod cáº§n duy trĂ¬ (1 báº£n sao)

    selector {
      match_labels = { app = "web-app" }  # Deployment quáº£n lĂ½ cĂ¡c Pod cĂ³ label app=web-app
    }

    template {      # KhuĂ´n máº«u Ä‘á»ƒ táº¡o Pod
      metadata {
        labels = { app = "web-app" }   # Pod Ä‘Æ°á»£c gáº¯n label nĂ y
        annotations = {
          # Hash cá»§a file HTML â†’ Khi HTML thay Ä‘á»•i, hash Ä‘á»•i â†’ Terraform phĂ¡t hiá»‡n vĂ  redeploy Pod
          "configmap-hash" = sha256(file("${path.module}/scripts/index.html"))
        }
      }

      spec {
        container {
          name  = "nginx"          # TĂªn container bĂªn trong Pod
          image = "nginx:alpine"   # Docker Image: Nginx phiĂªn báº£n nháº¹ (chá»‰ ~40MB)

          port {
            container_port = 80    # Container láº¯ng nghe port 80
          }

          volume_mount {
            name       = "html-volume"                 # TĂªn volume cáº§n mount
            mount_path = "/usr/share/nginx/html"       # Ghi Ä‘Ă¨ thÆ° má»¥c HTML máº·c Ä‘á»‹nh cá»§a Nginx
            read_only  = true                          # Chá»‰ Ä‘á»c, khĂ´ng cho phĂ©p ghi
          }

          resources {
            limits   = { cpu = "500m", memory = "256Mi" }   # Giá»›i háº¡n tá»‘i Ä‘a: 0.5 CPU, 256MB RAM
            requests = { cpu = "100m", memory = "128Mi" }   # YĂªu cáº§u tá»‘i thiá»ƒu: 0.1 CPU, 128MB RAM
          }
        }

        volume {
          name = "html-volume"
          config_map {
            name = kubernetes_config_map_v1.web_html.metadata[0].name  # Gáº¯n ConfigMap web-html lĂ m volume
          }
        }
      }
    }
  }
}
```

**Má»‘i quan há»‡ giá»¯a cĂ¡c thĂ nh pháº§n:**
```
Deployment (web-app)
    â”‚
    â”œâ”€â”€ selector: app=web-app     â† Deployment tĂ¬m vĂ  quáº£n lĂ½ Pod theo label nĂ y
    â”‚
    â””â”€â”€ template (KhuĂ´n máº«u Pod)
         â”‚
         â”œâ”€â”€ labels: app=web-app  â† Pod Ä‘Æ°á»£c gáº¯n label khá»›p vá»›i selector
         â”‚
         â”œâ”€â”€ Container: nginx:alpine (port 80)
         â”‚       â”‚
         â”‚       â””â”€â”€ volume_mount: /usr/share/nginx/html â† Ghi Ä‘Ă¨ file HTML
         â”‚
         â””â”€â”€ Volume: html-volume
                 â”‚
                 â””â”€â”€ config_map: web-html â† Ná»™i dung file index.html
```

### 8.4. Service NodePort (`kubernetes.tf`)
```hcl
resource "kubernetes_service_v1" "web" {
  spec {
    type = "NodePort"                # Kiá»ƒu Service: má»Ÿ port trĂªn Node

    selector = { app = "web-app" }   # Forward traffic tá»›i Pod cĂ³ label app=web-app

    port {
      port        = 80               # Port cá»§a Service (bĂªn trong cluster)
      target_port = 80               # Port cá»§a Container Nginx
      node_port   = 30080            # Port má»Ÿ ra trĂªn Node (EC2) Ä‘á»ƒ nháº­n traffic tá»« bĂªn ngoĂ i
    }
  }
}
```

**Luá»“ng traffic qua Service:**
```
BĂªn ngoĂ i (ALB) â†’ EC2:30080 (node_port) â†’ Service:80 (port) â†’ Pod/Container:80 (target_port)
```

### 8.5. Security Group (`security_groups.tf`)
```hcl
resource "aws_security_group" "ec2_sg" {
  name   = "${local.name_prefix}-ec2-sg"
  vpc_id = aws_vpc.main.id

  # Inbound: Chá»‰ cho ALB gá»­i traffic vĂ o port 30080
  ingress {
    from_port       = var.app_port          # 30080
    to_port         = var.app_port          # 30080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]  # â† Chá»‰ cho phĂ©p tá»« ALB-SG (KHĂ”NG pháº£i IP)
  }

  # Inbound: SSH chá»‰ tá»« IP cá»§a báº¡n
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]               # â† "0.0.0.0/0" hoáº·c "123.45.67.89/32"
  }
}
```

**LÆ°u Ă½:** `security_groups = [...]` khĂ¡c vá»›i `cidr_blocks = [...]`:
- `security_groups`: Cho phĂ©p traffic tá»« **tĂ i nguyĂªn thuá»™c Security Group** khĂ¡c (khĂ´ng cáº§n biáº¿t IP).
- `cidr_blocks`: Cho phĂ©p traffic tá»« **dáº£i IP cá»¥ thá»ƒ**.

---

## Pháº§n 9: Ingress, Expose vĂ  CĂ¡c CĂ¡ch Truy Cáº­p á»¨ng Dá»¥ng K8s

### 9.1. "Expose" nghÄ©a lĂ  gĂ¬?
- **Expose** = "PhÆ¡i bĂ y" á»©ng dá»¥ng ra bĂªn ngoĂ i. Máº·c Ä‘á»‹nh, Pod chá»‰ cĂ³ IP ná»™i bá»™ trong cluster, khĂ´ng ai tá»« bĂªn ngoĂ i truy cáº­p Ä‘Æ°á»£c. Muá»‘n ngÆ°á»i dĂ¹ng truy cáº­p Ä‘Æ°á»£c, báº¡n pháº£i **expose** nĂ³ thĂ´ng qua Service.

### 9.2. So sĂ¡nh 3 loáº¡i Service trong K8s

| Loáº¡i Service | Pháº¡m vi truy cáº­p | Port | Khi nĂ o dĂ¹ng? | Trong lab? |
|---|---|---|---|---|
| **ClusterIP** | Chá»‰ bĂªn trong cluster | Ná»™i bá»™ | Giao tiáº¿p giá»¯a cĂ¡c á»©ng dá»¥ng trong cĂ¹ng cluster | âŒ KhĂ´ng dĂ¹ng |
| **NodePort** | Tá»« bĂªn ngoĂ i, qua IP cá»§a Node | 30000-32767 | Truy cáº­p trá»±c tiáº¿p qua IP mĂ¡y chá»§ + port | âœ… **Äang dĂ¹ng** (port 30080) |
| **LoadBalancer** | Tá»« Internet, qua Load Balancer cá»§a cloud | 80/443 | Tá»± Ä‘á»™ng táº¡o Cloud LB (ELB trĂªn AWS) | âŒ KhĂ´ng dĂ¹ng (ta tá»± táº¡o ALB riĂªng) |

### 9.3. Ingress lĂ  gĂ¬? Lab cĂ³ dĂ¹ng khĂ´ng?
- **Ingress** lĂ  tĂ i nguyĂªn K8s dĂ¹ng Ä‘á»ƒ **Ä‘á»‹nh tuyáº¿n HTTP/HTTPS** tá»« bĂªn ngoĂ i vĂ o cĂ¡c Service bĂªn trong cluster (giá»‘ng nhÆ° má»™t reverse proxy ná»™i bá»™).
- **Lab KHĂ”NG dĂ¹ng Ingress** vĂ¬ ta Ä‘Ă£ cĂ³ **AWS ALB** Ä‘Ă³ng vai trĂ² tÆ°Æ¡ng tá»± (nháº­n HTTP port 80 â†’ forward vĂ o NodePort 30080).
- Ingress thÆ°á»ng Ä‘Æ°á»£c dĂ¹ng khi báº¡n cĂ³ **nhiá»u á»©ng dá»¥ng** trong 1 cluster vĂ  muá»‘n phĂ¢n luá»“ng theo URL path (vĂ­ dá»¥: `/api` â†’ Service A, `/web` â†’ Service B).

### 9.4. TĂ³m táº¯t cĂ¡ch truy cáº­p á»©ng dá»¥ng trong Lab
```
Internet â†’ ALB (Port 80) â†’ EC2:30080 (NodePort) â†’ Pod:80 (Nginx)
            â†‘                    â†‘                      â†‘
     AWS ALB thay tháº¿       Service NodePort         Container
     vai trĂ² Ingress        expose ra Node          cháº¡y á»©ng dá»¥ng
```

---

## Pháº§n 10: `null_resource` vs `null` Provider â€” PhĂ¢n Biá»‡t RĂµ RĂ ng

### 10.1. `null` Provider lĂ  gĂ¬?
- LĂ  má»™t **Terraform Provider** (plugin) do HashiCorp phĂ¡t hĂ nh.
- ÄÆ°á»£c khai bĂ¡o ngáº§m Ä‘á»‹nh khi báº¡n sá»­ dá»¥ng `null_resource` (khĂ´ng cáº§n khai bĂ¡o tÆ°á»ng minh trong `required_providers`).
- NĂ³ cung cáº¥p duy nháº¥t má»™t loáº¡i resource: `null_resource`.

### 10.2. `null_resource` lĂ  gĂ¬?
- LĂ  má»™t **tĂ i nguyĂªn áº£o** (khĂ´ng táº¡o ra thá»© gĂ¬ trĂªn cloud).
- DĂ¹ng Ä‘á»ƒ **cháº¡y cĂ¡c tĂ¡c vá»¥ phá»¥ trá»£** mĂ  Terraform khĂ´ng há»— trá»£ sáºµn, vĂ­ dá»¥:
  - SSH vĂ o mĂ¡y chá»§ Ä‘á»ƒ cháº¡y lá»‡nh (provisioner `remote-exec`)
  - Cháº¡y script trĂªn mĂ¡y local (provisioner `local-exec`)
  - Äá»£i má»™t Ä‘iá»u kiá»‡n nĂ o Ä‘Ă³ hoĂ n táº¥t trÆ°á»›c khi tiáº¿p tá»¥c

### 10.3. Trong Lab, `null_resource` dĂ¹ng Ä‘á»ƒ lĂ m gĂ¬?
```hcl
resource "null_resource" "wait_for_minikube" {
  # Má»¥c Ä‘Ă­ch: SSH vĂ o EC2 Ä‘á»ƒ kiá»ƒm tra xem cloud-init vĂ  proxy Ä‘Ă£ sáºµn sĂ ng chÆ°a
  # Náº¿u khĂ´ng cĂ³ bÆ°á»›c nĂ y, Kubernetes Provider sáº½ cá»‘ káº¿t ná»‘i proxy 8081 ngay láº­p tá»©c
  # trong khi EC2 váº«n Ä‘ang cĂ i Docker/Kind â†’ Lá»—i "connection refused"
}
```

### 10.4. TĂ³m táº¯t má»‘i quan há»‡
```
null Provider (plugin)
    â”‚
    â””â”€â”€ cung cáº¥p â†’ null_resource (tĂ i nguyĂªn áº£o)
                        â”‚
                        â”œâ”€â”€ provisioner "remote-exec"  â†’ Cháº¡y lá»‡nh trĂªn mĂ¡y xa (EC2)
                        â””â”€â”€ provisioner "local-exec"   â†’ Cháº¡y lá»‡nh trĂªn mĂ¡y local
```

---

## Pháº§n 11: Provisioner â€” CĂ¡c Loáº¡i Provisioner Trong Terraform

### 11.1. Provisioner lĂ  gĂ¬?
- LĂ  khá»‘i code bĂªn trong `resource` dĂ¹ng Ä‘á»ƒ **thá»±c thi hĂ nh Ä‘á»™ng bá»• sung** sau khi tĂ i nguyĂªn Ä‘Æ°á»£c táº¡o.
- Terraform khĂ´ng khuyáº¿n khĂ­ch dĂ¹ng nhiá»u provisioner (vĂ¬ khĂ³ quáº£n lĂ½ state), nhÆ°ng trong má»™t sá»‘ trÆ°á»ng há»£p nhÆ° lab nĂ y thĂ¬ ráº¥t cáº§n thiáº¿t.

### 11.2. CĂ¡c loáº¡i Provisioner trong Lab

| Provisioner | Cháº¡y á»Ÿ Ä‘Ă¢u? | Má»¥c Ä‘Ă­ch trong lab | File |
|---|---|---|---|
| `remote-exec` | TrĂªn mĂ¡y **EC2** (qua SSH) | Äá»£i cloud-init cháº¡y xong, kiá»ƒm tra proxy 8081 | `ec2.tf` |
| `file` | Copy file tá»« local lĂªn **EC2** | (KhĂ´ng dĂ¹ng trong phiĂªn báº£n hiá»‡n táº¡i) | â€” |
| `local-exec` | TrĂªn mĂ¡y **local** cá»§a báº¡n | (KhĂ´ng dĂ¹ng trong lab nĂ y) | â€” |

### 11.3. `connection` block
- Provisioner cáº§n biáº¿t **cĂ¡ch káº¿t ná»‘i** vĂ o mĂ¡y chá»§ Ä‘Ă­ch. Block `connection` cung cáº¥p thĂ´ng tin nĂ y:
```hcl
connection {
  type        = "ssh"                                    # Giao thá»©c: SSH
  user        = "ubuntu"                                 # User trĂªn EC2
  private_key = tls_private_key.ssh.private_key_pem      # Key SSH (tá»« TLS provider)
  host        = aws_instance.minikube.public_ip          # IP cĂ´ng khai cá»§a EC2
}
```

---

## Pháº§n 12: HĂ m Terraform Sá»­ Dá»¥ng Trong Lab

| HĂ m | Giáº£i thĂ­ch | VĂ­ dá»¥ trong lab |
|---|---|---|
| `merge(map1, map2)` | Gá»™p 2 map/object láº¡i | `merge(local.common_tags, { Name = "..." })` â€” Gá»™p tags chung + tag Name riĂªng |
| `templatefile(path, vars)` | Äá»c file vĂ  thay tháº¿ biáº¿n `${...}` | `templatefile("scripts/user_data.sh", { proxy_port = 8081 })` |
| `file(path)` | Äá»c ná»™i dung file thĂ nh chuá»—i | `file("scripts/index.html")` â€” Äá»c HTML nhĂºng vĂ o ConfigMap |
| `sha256(string)` | TĂ­nh mĂ£ hash SHA-256 | `sha256(file("scripts/index.html"))` â€” Táº¡o hash Ä‘á»ƒ phĂ¡t hiá»‡n thay Ä‘á»•i |

### `templatefile()` vs `file()` â€” KhĂ¡c nhau tháº¿ nĂ o?
- `file()`: Äá»c file nguyĂªn báº£n, **khĂ´ng** thay tháº¿ biáº¿n. DĂ¹ng khi ná»™i dung file lĂ  tÄ©nh (vĂ­ dá»¥: HTML).
- `templatefile()`: Äá»c file vĂ  **thay tháº¿** cĂ¡c biáº¿n `${...}` bĂªn trong. DĂ¹ng khi file cáº§n tham sá»‘ hĂ³a (vĂ­ dá»¥: script shell cáº§n biáº¿t port).

---

## Pháº§n 13: Máº¡ng vĂ  CIDR â€” Giáº£i ThĂ­ch Dá»… Hiá»ƒu

### 13.1. CIDR lĂ  gĂ¬?
- **CIDR** (Classless Inter-Domain Routing) lĂ  cĂ¡ch viáº¿t táº¯t Ä‘á»ƒ biá»ƒu diá»…n má»™t dáº£i Ä‘á»‹a chá»‰ IP.
- KĂ½ hiá»‡u: `IP/sá»‘_bit_máº¡ng`. Sá»‘ sau dáº¥u `/` cĂ ng nhá» thĂ¬ dáº£i IP cĂ ng rá»™ng.

### 13.2. CIDR trong Lab
| CIDR | Ă nghÄ©a | Sá»‘ IP kháº£ dá»¥ng | DĂ¹ng cho |
|---|---|---|---|
| `10.0.0.0/16` | ToĂ n bá»™ máº¡ng VPC | 65,536 IP | VPC chĂ­nh |
| `10.0.1.0/24` | Máº¡ng con nhá» hÆ¡n | 256 IP | Subnet A (AZ-a) |
| `10.0.2.0/24` | Máº¡ng con nhá» hÆ¡n | 256 IP | Subnet B (AZ-b) |
| `0.0.0.0/0` | Táº¥t cáº£ IP trĂªn Internet | ToĂ n bá»™ | Route Table (default route), SG inbound |
| `123.45.67.89/32` | ChĂ­nh xĂ¡c 1 IP duy nháº¥t | 1 IP | Biáº¿n `my_ip` (khĂ³a SSH cháº·t) |

### 13.3. Táº¡i sao Subnet `/24` náº±m trong VPC `/16`?
```
VPC:      10.0. 0.0 /16  â†’ 10.0.x.x  (x cĂ³ thá»ƒ lĂ  0-255)
Subnet A: 10.0. 1.0 /24  â†’ 10.0.1.x  (x cĂ³ thá»ƒ lĂ  0-255)
Subnet B: 10.0. 2.0 /24  â†’ 10.0.2.x  (x cĂ³ thá»ƒ lĂ  0-255)
```
Subnet lĂ  **táº­p con** cá»§a VPC. VPC cĂ³ 65,536 IP, má»—i Subnet chiáº¿m 256 IP.

---

## Pháº§n 14: Báº£ng Thuáº­t Ngá»¯ Tá»•ng Há»£p (Glossary)

| Thuáº­t ngá»¯ | Viáº¿t táº¯t | Giáº£i thĂ­ch ngáº¯n gá»n |
|---|---|---|
| Infrastructure as Code | IaC | Viáº¿t code Ä‘á»ƒ quáº£n lĂ½ háº¡ táº§ng thay vĂ¬ click tay |
| HashiCorp Configuration Language | HCL | NgĂ´n ngá»¯ viáº¿t file `.tf` cá»§a Terraform |
| Virtual Private Cloud | VPC | Máº¡ng áº£o riĂªng cá»§a báº¡n trĂªn AWS |
| Availability Zone | AZ | Trung tĂ¢m dá»¯ liá»‡u váº­t lĂ½ trong 1 Region |
| Internet Gateway | IGW | Cá»•ng káº¿t ná»‘i VPC ra Internet |
| Application Load Balancer | ALB | Bá»™ cĂ¢n báº±ng táº£i HTTP/HTTPS (Layer 7) |
| Network Load Balancer | NLB | Bá»™ cĂ¢n báº±ng táº£i TCP/UDP (Layer 4) |
| Security Group | SG | TÆ°á»ng lá»­a áº£o gáº¯n vĂ o tĂ i nguyĂªn AWS |
| Amazon Machine Image | AMI | Báº£n snapshot há»‡ Ä‘iá»u hĂ nh Ä‘á»ƒ táº¡o EC2 |
| Elastic Compute Cloud | EC2 | Dá»‹ch vá»¥ mĂ¡y chá»§ áº£o cá»§a AWS |
| Kubernetes | K8s | Há»‡ thá»‘ng Ä‘iá»u phá»‘i container |
| Kubernetes in Docker | Kind | CĂ´ng cá»¥ cháº¡y cluster K8s bĂªn trong Docker |
| Container | â€” | Tiáº¿n trĂ¬nh á»©ng dá»¥ng cháº¡y cĂ¡ch ly (Docker) |
| Pod | â€” | ÄÆ¡n vá»‹ nhá» nháº¥t trong K8s, bá»c 1+ container |
| Node | â€” | MĂ¡y chá»§ cháº¡y Pod (EC2 trong lab) |
| Namespace | NS | KhĂ´ng gian tĂªn Ä‘á»ƒ phĂ¢n tĂ¡ch tĂ i nguyĂªn K8s |
| ConfigMap | CM | LÆ°u trá»¯ dá»¯ liá»‡u cáº¥u hĂ¬nh dáº¡ng key-value |
| Deployment | Deploy | Quáº£n lĂ½ Pod: táº¡o, scale, update, rollback |
| Service | SVC | Expose Pod ra ngoĂ i qua IP/Port á»•n Ä‘á»‹nh |
| NodePort | â€” | Loáº¡i Service má»Ÿ port 30000-32767 trĂªn Node |
| ClusterIP | â€” | Loáº¡i Service chá»‰ truy cáº­p ná»™i bá»™ cluster |
| Ingress | â€” | Äá»‹nh tuyáº¿n HTTP/HTTPS vĂ o cluster (lab khĂ´ng dĂ¹ng) |
| Provisioner | â€” | Cháº¡y script bá»• sung sau khi táº¡o tĂ i nguyĂªn |
| User Data | â€” | Script shell cháº¡y tá»± Ä‘á»™ng khi EC2 khá»Ÿi Ä‘á»™ng láº§n Ä‘áº§u |
| CIDR | â€” | CĂ¡ch biá»ƒu diá»…n dáº£i Ä‘á»‹a chá»‰ IP (vĂ­ dá»¥: `10.0.0.0/16`) |
| Health Check | â€” | Kiá»ƒm tra Ä‘á»‹nh ká»³ xem á»©ng dá»¥ng cĂ²n sá»‘ng khĂ´ng |
| Target Group | TG | NhĂ³m mĂ¡y chá»§ Ä‘Ă­ch mĂ  ALB forward traffic tá»›i |
| High Availability | HA | Kháº£ nÄƒng hoáº¡t Ä‘á»™ng liĂªn tá»¥c, khĂ´ng giĂ¡n Ä‘oáº¡n |
| Stateful (Security Group) | â€” | Cho phĂ©p response tá»± Ä‘á»™ng Ä‘i ra náº¿u request Ä‘Ă£ Ä‘Æ°á»£c cho vĂ o |
| `depends_on` | â€” | RĂ ng buá»™c thá»© tá»± táº¡o/xĂ³a tĂ i nguyĂªn trong Terraform |
| `terraform.tfstate` | State | File JSON lÆ°u tráº¡ng thĂ¡i háº¡ táº§ng hiá»‡n táº¡i |
