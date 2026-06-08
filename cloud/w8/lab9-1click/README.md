<p align="center">
  <img src="https://img.icons8.com/color/96/000000/kubernetes.png" alt="Kubernetes Logo" width="80"/>
</p>

# <p align="center">đŸ€ LAB CD9 â€” 1-Click Automation Platform</p>

### <p align="center">Terraform â” Custom VPC â” EC2 (Kind) â” K8s Provider â” ALB</p>

<p align="center">
  <a href="https://terraform.io"><img src="https://img.shields.io/badge/TERRAFORM-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/></a>
  <a href="https://kubernetes.io"><img src="https://img.shields.io/badge/KUBERNETES-KIND-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/></a>
  <a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/AWS-ALB-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS ALB"/></a>
  <a href="https://docker.com"><img src="https://img.shields.io/badge/DOCKER-KIND-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker Engine"/></a>
</p>

<p align="center">
  <a href="evidence.md"><img src="https://img.shields.io/badge/EVIDENCE%20PACK-VIEW%20NOW-4CAF50?style=for-the-badge&logo=google-docs&logoColor=white" alt="Evidence Pack"/></a>
  <a href="study_guide.md"><img src="https://img.shields.io/badge/STUDY%20GUIDE-OPEN-00bcd4?style=for-the-badge&logo=read-the-docs&logoColor=white" alt="Study Guide"/></a>
</p>

> An automated, single-command deployment pipeline that provisions a full AWS network infrastructure, boots a Kubernetes Kind cluster inside EC2, and deploys a secure Nginx application using the Kubernetes HCL provider.

---

<p align="center">
  <b>Nguyá»…n ÄĂ¬nh Thi</b> Â· <code>XB-DN26-103</code> Â· <b>W8 Submission</b> Â· Deadline: 05/06/2026
</p>

---

## đŸ—ï¸ SÆ¡ Ä‘á»“ kiáº¿n trĂºc (Architecture Diagram)

DÆ°á»›i Ä‘Ă¢y lĂ  sÆ¡ Ä‘á»“ chi tiáº¿t biá»ƒu diá»…n luá»“ng hoáº¡t Ä‘á»™ng, cáº¥u hĂ¬nh Ä‘á»‹nh tuyáº¿n báº£o máº­t vĂ  cÆ¡ cháº¿ triá»ƒn khai cá»§a bĂ i Lab:

![SÆ¡ Ä‘á»“ kiáº¿n trĂºc](image.png)

### CĂ¡c thĂ nh pháº§n chĂ­nh trong kiáº¿n trĂºc:
1. **Máº¡ng & Äá»‹nh tuyáº¿n (VPC & Subnets):** 
   - VPC (`10.0.0.0/16`) Ä‘Æ°á»£c chia thĂ nh 2 Public Subnet thuá»™c 2 Availability Zone khĂ¡c nhau: Subnet A (`10.0.1.0/24` - `ap-southeast-1a`) vĂ  Subnet B (`10.0.2.0/24` - `ap-southeast-1b`).
   - Cáº£ hai Subnet Ä‘á»u liĂªn káº¿t vá»›i Internet Gateway (IGW) thĂ´ng qua Route Table Ä‘á»ƒ cho phĂ©p Ä‘i ra Internet.
2. **Bá»™ cĂ¢n báº±ng táº£i (ALB):** 
   - AWS ALB láº¯ng nghe trĂªn cá»•ng `80` cĂ´ng cá»™ng (má»Ÿ cho `0.0.0.0/0`).
   - ALB báº¯t buá»™c pháº£i liĂªn káº¿t vá»›i cáº£ 2 Subnet A vĂ  B Ä‘á»ƒ Ä‘áº¡t tĂ­nh sáºµn sĂ ng cao (High Availability).
   - ALB forward traffic tá»« cá»•ng `80` vĂ o cá»•ng `30080` (NodePort) trĂªn mĂ¡y chá»§ EC2.
3. **MĂ¡y chá»§ á»©ng dá»¥ng (EC2 & Kind):**
   - MĂ¡y áº£o EC2 (cháº¡y Ubuntu 22.04, `t3.medium`) náº±m táº¡i Subnet A.
   - EC2 cháº¡y script `user_data.sh` cĂ i Ä‘áº·t Docker, Kind, kubectl vĂ  khá»Ÿi táº¡o cá»¥m Kubernetes Kind Cluster.
   - á»¨ng dá»¥ng Nginx Ä‘Æ°á»£c Ä‘Ă³ng gĂ³i cháº¡y dÆ°á»›i dáº¡ng Pod trong namespace `lab-cd9` vĂ  Ä‘Æ°á»£c expose ra ngoĂ i qua Service NodePort `30080`.
   - Lá»‡nh `kubectl proxy --port=8081` cháº¡y ná»n giĂºp má»Ÿ cá»•ng káº¿t ná»‘i API Kubernetes cho Terraform.

---

## đŸ”— Giáº£i thĂ­ch cÆ¡ cháº¿ "Wire" cĂ¡c Provider vá»›i nhau

Dá»± Ă¡n nĂ y thá»ƒ hiá»‡n sá»± phá»‘i há»£p nhá»‹p nhĂ ng giá»¯a 4 Providers trong cĂ¹ng 1 cáº¥u hĂ¬nh:
1. **AWS Provider**: Táº¡o toĂ n bá»™ háº¡ táº§ng cÆ¡ báº£n (VPC, Subnet, Route Table, Security Group, EC2, ALB).
2. **TLS Provider**: Táº¡o SSH Key Ä‘á»™ng vĂ  truyá»n sang AWS Key Pair.
3. **Local Provider**: Ghi file private key `lab-cd9-key.pem` xuá»‘ng mĂ¡y local Ä‘á»ƒ phá»¥c vá»¥ viá»‡c SSH.
4. **Kubernetes Provider**: Káº¿t ná»‘i trá»±c tiáº¿p vĂ o API Server cá»§a cá»¥m Kind Cluster vĂ  deploy cĂ¡c tĂ i nguyĂªn K8s dÆ°á»›i dáº¡ng code HCL.

### ThĂ¡ch thá»©c Bootstrapping vĂ  Giáº£i phĂ¡p Proxy (`providers.tf` & `kubernetes.tf`):
Má»™t váº¥n Ä‘á» kinh Ä‘iá»ƒn cá»§a Terraform khi deploy á»©ng dá»¥ng vĂ o cá»¥m K8s má»›i tinh trong 1 láº§n apply: **LĂ m sao Ä‘á»ƒ Kubernetes Provider káº¿t ná»‘i vĂ  xĂ¡c thá»±c khi cá»¥m K8s vá»«a má»›i Ä‘Æ°á»£c dá»±ng vĂ  náº±m trong máº¡ng cĂ´ láº­p?**
* **Báº«y lá»—i**: Náº¿u copy file kubeconfig hay Certificate vá» mĂ¡y local Ä‘á»ƒ xĂ¡c thá»±c, Terraform sáº½ bá»‹ lá»—i ngay tá»« bÆ°á»›c `plan` vĂ¬ file chÆ°a tá»“n táº¡i hoáº·c bá»‹ lá»—i náº¡p cáº¥u hĂ¬nh (provider reload) giá»¯a chá»«ng.
* **Giáº£i phĂ¡p Ä‘á»™t phĂ¡**:
  1. Trong script `user_data.sh`, ta cháº¡y ngáº§m lá»‡nh `kubectl proxy --port=8081 --address='0.0.0.0'` trĂªn EC2 Ä‘á»ƒ biáº¿n API Server thĂ nh HTTP khĂ´ng cáº§n xĂ¡c thá»±c (chá»‰ cho phĂ©p IP cá»§a báº¡n truy cáº­p qua Security Group Ä‘á»ƒ báº£o máº­t).
  2. Cáº¥u hĂ¬nh Kubernetes Provider trá» Ä‘á»™ng vĂ o IP Public cá»§a EC2 qua port 8081:
     ```hcl
     provider "kubernetes" {
       host = "http://${aws_instance.minikube.public_ip}:8081"
     }
     ```
  3. Sá»­ dá»¥ng `depends_on = [null_resource.wait_for_minikube]` trĂªn cĂ¡c tĂ i nguyĂªn K8s Ä‘á»ƒ báº¯t Terraform pháº£i Ä‘á»£i mĂ¡y chá»§ EC2 hoĂ n táº¥t cĂ i Ä‘áº·t Kind Cluster vĂ  Proxy khá»Ÿi Ä‘á»™ng hoĂ n chá»‰nh rá»“i má»›i thá»±c hiá»‡n káº¿t ná»‘i.

### Táº¡i sao láº¡i chá»n Kind thay vĂ¬ Minikube `--driver=none`?
* **Minikube `--driver=none`** cháº¡y trá»±c tiáº¿p cĂ¡c tiáº¿n trĂ¬nh K8s lĂªn há»‡ Ä‘iá»u hĂ nh cá»§a EC2 mĂ  khĂ´ng cĂ³ lá»›p áº£o hĂ³a cĂ¡ch ly. Viá»‡c nĂ y yĂªu cáº§u quyá»n root tá»‘i cao, dá»… gĂ¢y rĂ¡c há»‡ thá»‘ng vĂ  Ä‘áº·c biá»‡t lĂ  cá»±c ká»³ báº¥t á»•n Ä‘á»‹nh trĂªn Ubuntu 22.04 (lá»—i cgroups v2/systemd).
* **Kind (Kubernetes in Docker)** cháº¡y cá»¥m Kubernetes dÆ°á»›i dáº¡ng cĂ¡c Docker Container nháº¹, sáº¡ch sáº½, khá»Ÿi Ä‘á»™ng nhanh hÆ¡n vĂ  cá»±c ká»³ á»•n Ä‘á»‹nh trĂªn mĂ´i trÆ°á»ng EC2.

---

## đŸ“– HÆ°á»›ng dáº«n cháº¡y (Execution Steps - 1-Click)

### BÆ°á»›c 1: Cáº¥u hĂ¬nh Credentials AWS
Äáº£m báº£o báº¡n Ä‘Ă£ cáº¥u hĂ¬nh AWS Credentials trĂªn mĂ¡y cá»§a báº¡n:
```bash
aws configure
# Nháº­p Access Key, Secret Key, Region: ap-southeast-1
```

### BÆ°á»›c 2: Khá»Ÿi táº¡o vĂ  táº£i Providers
Di chuyá»ƒn vĂ o thÆ° má»¥c dá»± Ă¡n vĂ  cháº¡y init:
```bash
cd NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9
terraform init
```

### BÆ°á»›c 3: Xem káº¿ hoáº¡ch (Plan)
```bash
terraform plan
```

### BÆ°á»›c 4: Triá»ƒn khai 1-Click (Apply)
```bash
terraform apply -auto-approve
```
*(QuĂ¡ trĂ¬nh nĂ y máº¥t khoáº£ng 3 - 5 phĂºt vĂ¬ Terraform pháº£i Ä‘á»£i mĂ¡y áº£o EC2 khá»Ÿi táº¡o, cĂ i Docker, dá»±ng cá»¥m Kind K8s, khá»Ÿi Ä‘á»™ng proxy, rá»“i má»›i báº¯t Ä‘áº§u táº¡o cĂ¡c tĂ i nguyĂªn Kubernetes).*

### BÆ°á»›c 5: Dá»n dáº¹p sáº¡ch háº¡ táº§ng (Destroy)
Sau khi kiá»ƒm tra xong, báº¡n cháº¡y lá»‡nh sau Ä‘á»ƒ xĂ³a sáº¡ch tĂ i nguyĂªn trĂ¡nh phĂ¡t sinh chi phĂ­:
```bash
terraform destroy -auto-approve
```

---

## đŸ” Báº±ng chá»©ng nghiá»‡m thu (Acceptance & Screenshots)

DÆ°á»›i Ä‘Ă¢y lĂ  hĂ¬nh áº£nh minh chá»©ng thá»±c táº¿ cho tá»«ng bÆ°á»›c cháº¡y cá»§a dá»± Ă¡n:

### 1. Khá»Ÿi táº¡o thĂ nh cĂ´ng (`terraform init`)
Táº£i thĂ nh cĂ´ng cáº£ 4 providers (`aws`, `tls`, `local`, `kubernetes`).

![Init](assets/tf_init.png)

### 2. Káº¿ hoáº¡ch triá»‡t Ä‘á»ƒ (`terraform plan`)
XĂ¢y dá»±ng thĂ nh cĂ´ng Ä‘á»“ thá»‹ phá»¥ thuá»™c Ä‘á»ƒ táº¡o má»›i 22 tĂ i nguyĂªn.

![Plan](assets/tf_plan.png)

### 3. Apply hoĂ n thĂ nh (`terraform apply`)
Terraform cháº¡y xong vĂ  xuáº¥t ra cĂ¡c thĂ´ng sá»‘ Outputs quan trá»ng.

![Apply](assets/tf_apply.png)

### 4. Tráº¡ng thĂ¡i háº¡ táº§ng hoáº¡t Ä‘á»™ng trĂªn AWS
* **MĂ¡y chá»§ EC2 Instance:**
![EC2 Console](assets/ec2.png)
* **Application Load Balancer (ALB):**
![ALB Console](assets/alb.png)

### 5. XĂ¡c minh á»©ng dá»¥ng cháº¡y trong cá»¥m K8s (KhĂ´ng cĂ i tháº³ng EC2)
SSH vĂ o mĂ¡y EC2, kiá»ƒm tra tráº¡ng thĂ¡i Pods vĂ  Services trong namespace `lab-cd9`. á»¨ng dá»¥ng cháº¡y an toĂ n bĂªn trong Container Pod.

![K8s Verify](assets/k8s_verify.png)

### 6. Truy cáº­p thĂ nh cĂ´ng qua Load Balancer trĂªn TrĂ¬nh duyá»‡t
DĂ¡n URL cá»§a `alb_dns_name` vĂ o trĂ¬nh duyá»‡t vĂ  nháº­n vá» trang web tĂ¹y chá»‰nh cháº¡y tá»« Kind Cluster.

![Browser](assets/brower.png)

### 7. Dá»n dáº¹p sáº¡ch sáº½ tĂ i nguyĂªn (`terraform destroy`)
Há»§y bá» toĂ n bá»™ 22 tĂ i nguyĂªn trĂªn AWS thĂ nh cĂ´ng.

![Destroy](assets/tf_destroy.png)