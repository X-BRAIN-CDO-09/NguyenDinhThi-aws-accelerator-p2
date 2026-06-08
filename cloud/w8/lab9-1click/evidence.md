# BĂO CĂO NGHIá»†M THU (EVIDENCE REPORT)
## Äá»€ BĂ€I: K8s on AWS â€” Terraform 1-Click

* **Há»c viĂªn:** Nguyá»…n ÄĂ¬nh Thi  
* **Dá»± Ă¡n:** LAB CD9 â€” 1-Click Automation  
* **Nguá»“n Repo:** [X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2](https://github.com/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2.git)  

---

## I. Báº¢NG Äá»I CHIáº¾U TIĂU CHĂ Äáº T (ACCEPTANCE CHECKLIST)

DÆ°á»›i Ä‘Ă¢y lĂ  báº£ng Ä‘á»‘i chiáº¿u cĂ¡c yĂªu cáº§u báº¯t buá»™c cá»§a Ä‘á» bĂ i so vá»›i káº¿t quáº£ thá»±c táº¿ cá»§a giáº£i phĂ¡p:

| STT | YĂªu cáº§u báº¯t buá»™c cá»§a Äá» bĂ i | Tráº¡ng thĂ¡i | Giáº£i phĂ¡p ká»¹ thuáº­t thá»±c táº¿ trong Dá»± Ă¡n |
| :--- | :--- | :---: | :--- |
| **1** | Háº¡ táº§ng (EC2 + máº¡ng) dá»±ng báº±ng **Terraform** | **Äáº T** | Tá»± Ä‘á»™ng táº¡o Custom VPC, 2 Subnets, Internet Gateway, Route Tables, Security Groups, EC2 vĂ  ALB. |
| **2** | Cá»¥m K8s cháº¡y báº±ng **minikube hoáº·c kind** trĂªn EC2 | **Äáº T** | Sá»­ dá»¥ng **Kind** cháº¡y trĂªn Docker Engine cá»§a EC2. |
| **3** | App cháº¡y **trong K8s** (khĂ´ng cĂ i tháº³ng lĂªn EC2) | **Äáº T** | á»¨ng dá»¥ng cháº¡y dÆ°á»›i dáº¡ng Pod trong Namespace `lab-cd9` cá»§a cá»¥m Kind K8s. |
| **4** | App truy cáº­p Ä‘Æ°á»£c tá»« **Internet qua ALB** | **Äáº T** | ALB láº¯ng nghe cá»•ng 80 cĂ´ng cá»™ng vĂ  forward traffic vĂ o cá»•ng NodePort `30080` cá»§a EC2 Ä‘Æ°á»£c Ă¡nh xáº¡ tá»« Pod. |
| **5** | **Má»™t lá»‡nh** Ä‘á»ƒ dá»±ng táº¥t cáº£ (1-click) | **Äáº T** | Chá»‰ cháº¡y duy nháº¥t lá»‡nh `terraform apply -auto-approve` Ä‘á»ƒ khá»Ÿi táº¡o tá»± Ä‘á»™ng toĂ n bá»™ tá»« Ä‘áº§u Ä‘áº¿n cuá»‘i. |
| **6** | CĂ³ dĂ¹ng **$\ge 2$ provider** (wire provider khĂ¡c) | **Äáº T** | Sá»­ dá»¥ng **4 providers**: `aws`, `tls` (sinh SSH Key), `local` (ghi file `.pem`), vĂ  `kubernetes` (triá»ƒn khai app). |
| **7** | Dá»n Ä‘Æ°á»£c sáº¡ch (**destroy**) sau khi xong | **Äáº T** | Cháº¡y lá»‡nh `terraform destroy -auto-approve` Ä‘á»ƒ xĂ³a sáº¡ch toĂ n bá»™ 22 tĂ i nguyĂªn trĂ¡nh tá»‘n phĂ­. |

---

## II. GIáº¢I THĂCH KIáº¾N TRĂC & QUYáº¾T Äá»NH THIáº¾T Káº¾ (TRAINER ORAL PREPARATION)

### SÆ¡ Ä‘á»“ Kiáº¿n trĂºc Há»‡ thá»‘ng (Architecture Diagram)
![SÆ¡ Ä‘á»“ Kiáº¿n trĂºc Há»‡ thá»‘ng](image.png)

### 1. CÆ¡ cháº¿ "Wire" cĂ¡c Provider trong dá»± Ă¡n
Dá»± Ă¡n thá»±c hiá»‡n liĂªn káº¿t (wire) cháº·t cháº½ giá»¯a cĂ¡c Provider Ä‘á»™c láº­p:
* **TLS Provider â” AWS Provider**: TĂ i nguyĂªn `tls_private_key.ssh` sinh khĂ³a Public Key trá»±c tiáº¿p trong bá»™ nhá»› RAM, sau Ä‘Ă³ truyá»n káº¿t quáº£ sang lĂ m tham sá»‘ Ä‘áº§u vĂ o cho `aws_key_pair.deployer` Ä‘á»ƒ náº¡p lĂªn AWS. KhĂ³a Private Key Ä‘Æ°á»£c `local_file` ghi xuá»‘ng á»• cá»©ng dáº¡ng `.pem` Ä‘á»ƒ Dev sá»­ dá»¥ng káº¿t ná»‘i SSH.
* **AWS Provider â” Kubernetes Provider**: 
  - Khá»‘i `provider "kubernetes"` sá»­ dá»¥ng Ä‘á»‹a chá»‰ Host cáº¥u hĂ¬nh Ä‘á»™ng: `http://${aws_instance.minikube.public_ip}:8081`.
  - IP cá»§a EC2 Ä‘Æ°á»£c sinh ra bá»Ÿi AWS Provider sáº½ tá»± Ä‘á»™ng Ä‘Æ°á»£c truyá»n vĂ o lĂ m tham sá»‘ Ä‘áº§u cuá»‘i cho Kubernetes Provider káº¿t ná»‘i.

### 2. CĂ¡ch káº¿t ná»‘i Kubernetes vá»›i ALB (Expose Network ra Host)
* **ThĂ¡ch thá»©c**: Cluster cháº¡y báº±ng Kind náº±m trong máº¡ng cĂ´ láº­p cá»§a Docker. ALB ngoĂ i Internet khĂ´ng thá»ƒ trá» trá»±c tiáº¿p vĂ o IP ná»™i bá»™ cá»§a Container Pod.
* **Giáº£i phĂ¡p**: 
  1. Trong `user_data.sh`, cá»¥m Kind Ä‘Æ°á»£c khá»Ÿi táº¡o vá»›i cáº¥u hĂ¬nh `extraPortMappings` Ă¡nh xáº¡ cá»•ng NodePort `30080` cá»§a container control-plane ra cá»•ng `30080` cá»§a mĂ¡y chá»§ EC2.
  2. Báº£ng má»¥c tiĂªu cá»§a Load Balancer (`aws_lb_target_group`) Ä‘Æ°á»£c cáº¥u hĂ¬nh trá» vĂ o cá»•ng `30080` cá»§a mĂ¡y chá»§ EC2.
  3. Khi User truy cáº­p ALB (Port 80) â” ALB chuyá»ƒn tiáº¿p tá»›i EC2 (Port 30080) â” Host EC2 Ä‘á»‹nh tuyáº¿n tiáº¿p vĂ o Service NodePort (Port 30080) â” Äi tá»›i Pod á»©ng dá»¥ng (Port 80).

### 3. Giáº£i quyáº¿t bĂ i toĂ¡n phá»¥ thuá»™c thá»i gian (Dependency & Bootstrapping)
* Náº¿u gá»i Kubernetes Provider ngay tá»« Ä‘áº§u, Terraform sáº½ bĂ¡o lá»—i do cá»¥m K8s chÆ°a tá»“n táº¡i trĂªn mĂ¡y áº£o EC2.
* **Giáº£i phĂ¡p**: Sá»­ dá»¥ng tĂ i nguyĂªn Ä‘á»“ng bá»™ trung gian `null_resource.wait_for_minikube`. TĂ i nguyĂªn nĂ y báº¯t buá»™c pháº£i Ä‘á»£i EC2 khá»Ÿi táº¡o xong (`depends_on = [aws_instance.minikube]`), sau Ä‘Ă³ thá»±c hiá»‡n SSH vĂ o cháº¡y lá»‡nh `sudo cloud-init status --wait` Ä‘á»ƒ chá» script `user_data.sh` cĂ i Ä‘áº·t K8s hoĂ n táº¥t.
* CĂ¡c tĂ i nguyĂªn Kubernetes trong file `kubernetes.tf` Ä‘á»u khai bĂ¡o `depends_on = [null_resource.wait_for_minikube]` Ä‘á»ƒ Ä‘áº£m báº£o chĂºng chá»‰ cháº¡y sau khi cá»¥m K8s Ä‘Ă£ sáºµn sĂ ng tiáº¿p nháº­n káº¿t ná»‘i.

---

## III. Báº°NG CHá»¨NG THá»°C THI (DELIVERABLES & SCREENSHOTS)

### 1. Khá»Ÿi táº¡o Dá»± Ă¡n (`terraform init`)
Lá»‡nh khá»Ÿi táº¡o táº£i thĂ nh cĂ´ng cáº£ 4 providers cáº§n thiáº¿t vá» local.

* **Minh chá»©ng thá»±c táº¿**:

![Screenshot 1: Káº¿t quáº£ cháº¡y lá»‡nh terraform init thĂ nh cĂ´ng](assets/tf_init.png)

---

### 2. Xem Káº¿ hoáº¡ch Triá»ƒn khai (`terraform plan`)
Terraform xĂ¢y dá»±ng thĂ nh cĂ´ng Ä‘á»“ thá»‹ phá»¥ thuá»™c vĂ  bĂ¡o cĂ¡o sáº½ táº¡o má»›i 22 tĂ i nguyĂªn.

* **Minh chá»©ng thá»±c táº¿**:

![Screenshot 2: Káº¿t quáº£ cháº¡y lá»‡nh terraform plan hiá»ƒn thá»‹ 22 tĂ i nguyĂªn cáº§n táº¡o](assets/tf_plan.png)

---

### 3. Triá»ƒn khai 1-Click (`terraform apply`)
QuĂ¡ trĂ¬nh cĂ i Ä‘áº·t tá»± Ä‘á»™ng tá»« háº¡ táº§ng Ä‘áº¿n á»©ng dá»¥ng cháº¡y hoĂ n táº¥t sau khoáº£ng 3-5 phĂºt.

* **Minh chá»©ng thá»±c táº¿**:

![Screenshot 3: Káº¿t quáº£ lá»‡nh terraform apply hoĂ n táº¥t thĂ nh cĂ´ng](assets/tf_apply.png)

---

### 4. MĂ¡y chá»§ EC2 vĂ  Load Balancer tráº¡ng thĂ¡i Running/Active trĂªn AWS Console
XĂ¡c minh trá»±c quan trĂªn giao diá»‡n AWS Web Console Ä‘á»ƒ chá»©ng minh tĂ i nguyĂªn thá»±c táº¿ Ä‘Ă£ cháº¡y.

* **Minh chá»©ng EC2**:

![Screenshot 4.1: MĂ¡y chá»§ EC2 Instance á»Ÿ tráº¡ng thĂ¡i Running trĂªn AWS Console](assets/ec2.png)

* **Minh chá»©ng ALB**:

![Screenshot 4.2: Application Load Balancer á»Ÿ tráº¡ng thĂ¡i Active trĂªn AWS Console](assets/alb.png)

---

### 5. á»¨ng dá»¥ng thá»±c sá»± cháº¡y trong cá»¥m K8s (KhĂ´ng cĂ i tháº³ng EC2)
SSH vĂ o EC2 kiá»ƒm tra tráº¡ng thĂ¡i Pods vĂ  Services Ä‘á»ƒ chá»©ng minh á»©ng dá»¥ng Ä‘Æ°á»£c cĂ´ láº­p an toĂ n trong Kubernetes.

* **Minh chá»©ng thá»±c táº¿**:

![Screenshot 5: SSH vĂ o EC2 vĂ  kiá»ƒm tra tráº¡ng thĂ¡i Pods/Services cá»§a Kubernetes](assets/k8s_verify.png)

---

### 6. Truy cáº­p á»©ng dá»¥ng qua Load Balancer trĂªn TrĂ¬nh duyá»‡t
Má»Ÿ Ä‘á»‹a chá»‰ URL xuáº¥t ra tá»« output `alb_dns_name` trĂªn trĂ¬nh duyá»‡t web.

* **Minh chá»©ng thá»±c táº¿**:

![Screenshot 6: Truy cáº­p giao diá»‡n á»©ng dá»¥ng thĂ nh cĂ´ng qua ALB DNS trĂªn trĂ¬nh duyá»‡t](assets/brower.png)

---

### 7. Nghiá»‡m thu cÆ¡ cháº¿ tá»± Ä‘á»™ng co giĂ£n Horizontal Pod Autoscaler (HPA)
Tá»± Ä‘á»™ng tÄƒng sá»‘ lÆ°á»£ng Pod khi CPU quĂ¡ táº£i vĂ  giáº£m Pod khi táº£i háº¡ nhiá»‡t.

*   **Minh chá»©ng Metrics Server & HPA hoáº¡t Ä‘á»™ng á»•n Ä‘á»‹nh:**
    Kiá»ƒm tra má»©c tiĂªu thá»¥ CPU/RAM thá»±c táº¿ cá»§a cá»¥m:
    ```bash
    ubuntu@ip-10-0-1-191:~$ kubectl top nodes
    NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
    lab-cd9-control-plane   111m         5%       657Mi           17%

    ubuntu@ip-10-0-1-191:~$ kubectl top pods -n lab-cd9
    NAME                       CPU(cores)   MEMORY(bytes)   
    web-app-66dff685f9-489w2   1m           3Mi
    web-app-66dff685f9-d579k   1m           3Mi
    ```
    Tráº¡ng thĂ¡i HPA ban Ä‘áº§u (nháº­n diá»‡n thĂ nh cĂ´ng `cpu: 0%/50%`):
    ```bash
    ubuntu@ip-10-0-1-191:~$ kubectl get hpa -n lab-cd9
    NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
    web-hpa   Deployment/web-app   cpu: 0%/50%   2         10        2          6m49s
    ```

*   **Minh chá»©ng tá»± Ä‘á»™ng Co giĂ£n Pod (Scale Out) khi stress test:**
    Cháº¡y Pod táº¡o táº£i vĂ´ háº¡n Ä‘á»ƒ Ä‘áº©y CPU vÆ°á»£t ngÆ°á»¡ng:
    ```bash
    kubectl run -it --rm load-generator --image=busybox --restart=Never -n lab-cd9 -- /bin/sh -c "while true; do wget -q -O- http://web-service > /dev/null; done"
    ```
    *Minh chá»©ng thá»±c thi lá»‡nh cháº¡y vĂ²ng láº·p vĂ´ háº¡n táº¡o táº£i:*
    
    ![Spam Request](assets/spam_request.png)
    
    GiĂ¡m sĂ¡t Ä‘á»™ng (`kubectl get hpa -n lab-cd9 -w`), CPU tÄƒng lĂªn **69%** vĂ  sá»‘ lÆ°á»£ng báº£n sao nĂ¢ng lĂªn **3 Pods** thĂ nh cĂ´ng:
    ```bash
    ubuntu@ip-10-0-1-191:~$ kubectl get hpa -n lab-cd9 -w
    NAME      REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
    web-hpa   Deployment/web-app   cpu: 0%/50%   2         10        2          6m54s
    web-hpa   Deployment/web-app   cpu: 13%/50%  2         10        2          17m
    web-hpa   Deployment/web-app   cpu: 69%/50%  2         10        2          17m
    web-hpa   Deployment/web-app   cpu: 69%/50%  2         10        3          17m  # đŸ€ Scale out lĂªn 3 Pods thĂ nh cĂ´ng!
    web-hpa   Deployment/web-app   cpu: 33%/50%  2         10        3          18m  # Táº£i háº¡ vá» 33% nhá» chia sáº» táº£i
    ```
    *Minh chá»©ng HPA nháº­n diá»‡n CPU Ä‘áº¡t 69% vĂ  tá»± Ä‘á»™ng kĂ­ch hoáº¡t Scale Out lĂªn 3 Pods:*
    
    ![Scale Out Replicas](assets/scale_out_replicas.png)
    
    *Minh chá»©ng HPA tá»± Ä‘á»™ng háº¡ sá»‘ lÆ°á»£ng Pod vá» 2 (Scale In) sau khi káº¿t thĂºc táº¡o táº£i:*
    
    ![Scale In Cooldown](assets/scale_in.png)

---

### 8. Dá»n dáº¹p sáº¡ch sáº½ tĂ i nguyĂªn (`terraform destroy`)
Há»§y bá» toĂ n bá»™ háº¡ táº§ng Ä‘á»ƒ trĂ¡nh tá»‘n phĂ­.

* **Minh chá»©ng thá»±c táº¿**:

![Screenshot 7: Káº¿t quáº£ cháº¡y lá»‡nh terraform destroy dá»n dáº¹p tĂ i nguyĂªn thĂ nh cĂ´ng](assets/tf_destroy.png)