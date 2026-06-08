# GIáº¢I THĂCH CÆ  CHáº¾ K8S API PROXY TRONG Dá»° ĂN (LAB CD9)

TĂ i liá»‡u nĂ y giáº£i thĂ­ch chi tiáº¿t lĂ½ do táº¡i sao dá»± Ă¡n cá»§a **Nguyá»…n ÄĂ¬nh Thi** sá»­ dá»¥ng cÆ¡ cháº¿ **Kubernetes API Proxy (`kubectl proxy`)** Ä‘á»ƒ liĂªn káº¿t (wire) giá»¯a Terraform vĂ  cá»¥m Kind Cluster trĂªn EC2, cĂ¹ng vá»›i cĂ¡c Æ°u Ä‘iá»ƒm vĂ  nhÆ°á»£c Ä‘iá»ƒm cá»§a giáº£i phĂ¡p nĂ y.

---

## I. LĂ DO Sá»¬ Dá»¤NG K8S API PROXY TRONG Dá»° ĂN

Trong má»™t ká»‹ch báº£n triá»ƒn khai **1-Click Automation** báº±ng Terraform, chĂºng ta gáº·p pháº£i bĂ i toĂ¡n **phá»¥ thuá»™c vĂ²ng láº·p (Bootstrapping Dependency)**:
1. Terraform cáº§n khá»Ÿi táº¡o háº¡ táº§ng AWS (VPC, EC2) trÆ°á»›c.
2. Sau khi EC2 khá»Ÿi Ä‘á»™ng, cá»¥m Kubernetes (Kind) má»›i Ä‘Æ°á»£c táº¡o ra thĂ´ng qua script `user_data.sh`.
3. Khi cá»¥m K8s sáºµn sĂ ng, Terraform Kubernetes Provider cáº§n káº¿t ná»‘i vĂ o cá»¥m Ä‘á»ƒ táº¡o Namespace, Deployment, Service vĂ  HPA.

### Thá»­ thĂ¡ch:
ThĂ´ng thÆ°á»ng, Ä‘á»ƒ káº¿t ná»‘i vĂ o cá»¥m K8s, ta cáº§n file cáº¥u hĂ¬nh xĂ¡c thá»±c (`kubeconfig`), chá»©ng chá»‰ TLS (`client-certificate`, `client-key`) hoáº·c Token. Tuy nhiĂªn, cĂ¡c file nĂ y náº±m trĂªn mĂ¡y áº£o EC2 vá»«a táº¡o vĂ  **khĂ´ng tá»“n táº¡i á»Ÿ mĂ¡y local** cháº¡y lá»‡nh Terraform lĂºc báº¯t Ä‘áº§u.

### Giáº£i phĂ¡p:
Trong script [user_data.sh](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/scripts/user_data.sh#L69-L76), ta cháº¡y má»™t tiáº¿n trĂ¬nh ngáº§m (background process) Ä‘á»ƒ má»Ÿ cá»•ng Proxy:
```bash
nohup kubectl proxy --port=8081 --address='0.0.0.0' --accept-hosts='^.*$' > /var/log/kubectl-proxy.log 2>&1 &
```
Lá»‡nh nĂ y chuyá»ƒn Ä‘á»•i cá»•ng API Server báº£o máº­t cá»§a Kubernetes (yĂªu cáº§u chá»©ng chá»‰ phá»©c táº¡p) thĂ nh má»™t cá»•ng HTTP khĂ´ng cáº§n xĂ¡c thá»±c á»Ÿ cá»•ng `8081`. Nhá» váº­y, á»Ÿ file [providers.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/providers.tf#L33-L35), Terraform chá»‰ cáº§n káº¿t ná»‘i qua giao thá»©c HTTP Ä‘Æ¡n giáº£n:
```terraform
provider "kubernetes" {
  host = "http://${aws_instance.minikube.public_ip}:8081"
}
```

---

## II. PHĂ‚N TĂCH Æ¯U ÄIá»‚M & NHÆ¯á»¢C ÄIá»‚M

### 1. Æ¯u Ä‘iá»ƒm (Advantages)

* **Quáº£n lĂ½ Tráº¡ng thĂ¡i Táº­p trung (Terraform State Management) â€” Äiá»ƒm vÆ°á»£t trá»™i nháº¥t**:
  * **Sá»± khĂ¡c biá»‡t**: CĂ¡c thĂ nh viĂªn khĂ¡c chá»n giáº£i phĂ¡p "á»¦y quyá»n hoĂ n toĂ n" cho EC2 tá»± cĂ i vĂ  tá»± deploy (Terraform local táº¡o xong EC2 lĂ  ngáº¯t káº¿t ná»‘i). CĂ²n báº¡n chá»n cĂ¡ch **"Quáº£n lĂ½ táº­p trung"** (Terraform local vá»«a táº¡o háº¡ táº§ng AWS vá»«a trá»±c tiáº¿p káº¿t ná»‘i qua API Proxy Ä‘á»ƒ Ä‘iá»u khiá»ƒn vĂ  giĂ¡m sĂ¡t cá»¥m K8s).
  * **Lá»£i Ă­ch**: Khi sá»­ dá»¥ng Kubernetes Provider trong Terraform, toĂ n bá»™ tĂ i nguyĂªn K8s (Namespace, Deployment, ConfigMap, Service, HPA) Ä‘á»u Ä‘Æ°á»£c theo dĂµi cháº·t cháº½ trong file **`terraform.tfstate`**.
  * **PhĂ¡t hiá»‡n sai lá»‡ch (Drift Detection)**: Náº¿u cĂ³ ai Ä‘Ă³ vĂ´ tĂ¬nh hoáº·c cá»‘ Ă½ vĂ o cá»¥m K8s xĂ³a Ä‘i má»™t Pod hoáº·c thay Ä‘á»•i cáº¥u hĂ¬nh Service, lá»‡nh `terraform plan/apply` tiáº¿p theo á»Ÿ mĂ¡y local cá»§a báº¡n sáº½ láº­p tá»©c phĂ¡t hiá»‡n ra sá»± sai lá»‡ch (drift) nĂ y vĂ  tá»± Ä‘á»™ng khĂ´i phá»¥c (re-create/update) tĂ i nguyĂªn vá» Ä‘Ăºng tráº¡ng thĂ¡i mong muá»‘n. á» giáº£i phĂ¡p cháº¡y script cá»§a cĂ¡c báº¡n khĂ¡c, Terraform hoĂ n toĂ n "mĂ¹" trÆ°á»›c cĂ¡c tĂ i nguyĂªn K8s nĂ y vĂ  khĂ´ng thá»ƒ kiá»ƒm soĂ¡t hay sá»­a chá»¯a khi cĂ³ lá»—i xáº£y ra.
  * **VĂ²ng Ä‘á»i nháº¥t quĂ¡n (Unified Lifecycle)**: Khi báº¡n cháº¡y `terraform destroy`, Terraform sáº½ dá»n sáº¡ch sáº½ tá»« á»©ng dá»¥ng K8s cho Ä‘áº¿n máº¡ng lÆ°á»›i AWS theo Ä‘Ăºng thá»© tá»± Æ°u tiĂªn. Giáº£i phĂ¡p dĂ¹ng shell script cá»§a cĂ¡c báº¡n khĂ¡c sáº½ Ä‘á»ƒ láº¡i cĂ¡c tĂ i nguyĂªn K8s "má»“ cĂ´i" trong container cá»§a EC2, vĂ  chĂºng chá»‰ bá»‹ triá»‡t tiĂªu khi mĂ¡y áº£o EC2 bá»‹ táº¯t hoĂ n toĂ n.
* **Hiá»‡n thá»±c hĂ³a 1-Click Deployment**: Cho phĂ©p hoĂ n thĂ nh toĂ n bá»™ tiáº¿n trĂ¬nh tá»« táº¡o háº¡ táº§ng Cloud Ä‘áº¿n deploy á»©ng dá»¥ng K8s chá»‰ trong duy nháº¥t má»™t lá»‡nh `terraform apply` mĂ  khĂ´ng cáº§n ngáº¯t quĂ£ng giá»¯a chá»«ng Ä‘á»ƒ cáº¥u hĂ¬nh thá»§ cĂ´ng hoáº·c láº¥y file chá»©ng chá»‰.
* **ÄÆ¡n giáº£n hĂ³a cáº¥u hĂ¬nh cáº¥u trĂºc mĂ£ nguá»“n (HCL)**: Loáº¡i bá» sá»± phá»©c táº¡p khi pháº£i viáº¿t code Terraform Ä‘á»ƒ download file `kubeconfig` tá»« EC2 vá» mĂ¡y local báº±ng SSH, rá»“i náº¡p Certificate Ä‘á»™ng vĂ o Provider.
* **KhĂ´ng phá»¥ thuá»™c vĂ o cáº¥u hĂ¬nh client local**: Láº­p trĂ¬nh viĂªn cháº¡y lá»‡nh á»Ÿ báº¥t ká»³ mĂ¡y tĂ­nh nĂ o cÅ©ng cĂ³ thá»ƒ deploy Ä‘Æ°á»£c, khĂ´ng cáº§n cĂ³ sáºµn cĂ¡c cĂ´ng cá»¥ giáº£i mĂ£ hoáº·c phĂ¢n quyá»n file trĂªn há»‡ Ä‘iá»u hĂ nh local.

### 2. NhÆ°á»£c Ä‘iá»ƒm & Rá»§i ro (Disadvantages & Risks)

* **Rá»§i ro báº£o máº­t cá»±c ká»³ lá»›n (Security Risk)**: 
  * Cá»•ng proxy `8081` cháº¥p nháº­n má»i káº¿t ná»‘i khĂ´ng cáº§n xĂ¡c thá»±c (`--accept-hosts='^.*$'`) vĂ  cĂ³ toĂ n quyá»n tá»‘i cao (`cluster-admin`) trĂªn cá»¥m K8s.
  * Náº¿u hacker quĂ©t tháº¥y cá»•ng nĂ y Ä‘ang má»Ÿ cĂ´ng khai trĂªn Internet, há» cĂ³ thá»ƒ chiáº¿m quyá»n Ä‘iá»u khiá»ƒn hoĂ n toĂ n cá»¥m Kubernetes cá»§a báº¡n.
* **Truyá»n tin khĂ´ng mĂ£ hĂ³a (Plaintext Traffic)**: Dá»¯ liá»‡u giao tiáº¿p giá»¯a mĂ¡y local (cháº¡y Terraform) vĂ  EC2 truyá»n qua HTTP thay vĂ¬ HTTPS, dáº«n Ä‘áº¿n nguy cÆ¡ bá»‹ táº¥n cĂ´ng nghe lĂ©n (Man-in-the-Middle) Ä‘á»ƒ Ä‘Ă¡nh cáº¯p thĂ´ng tin nháº¡y cáº£m.
* **Rá»§i ro sáº­p tiáº¿n trĂ¬nh ná»n (Dependency on Background Process)**: Náº¿u tiáº¿n trĂ¬nh cháº¡y ná»n `kubectl proxy` trĂªn EC2 bá»‹ sáº­p (do thiáº¿u tĂ i nguyĂªn, crash...), Terraform á»Ÿ local sáº½ láº­p tá»©c máº¥t quyá»n quáº£n lĂ½ K8s dĂ¹ cá»¥m K8s bĂªn trong váº«n Ä‘ang hoáº¡t Ä‘á»™ng bĂ¬nh thÆ°á»ng.

---

## III. CĂCH KHáº®C PHá»¤C Rá»¦I RO TRONG Dá»° ĂN NĂ€Y

Äá»ƒ sá»­ dá»¥ng cÆ¡ cháº¿ nĂ y má»™t cĂ¡ch an toĂ n cho bĂ i Lab, dá»± Ă¡n Ä‘Ă£ triá»ƒn khai giáº£i phĂ¡p báº£o máº­t nhiá»u lá»›p:

1. **Giá»›i háº¡n IP nghiĂªm ngáº·t táº¡i Security Group (EC2-SG)**: 
   Táº¡i file [security_groups.tf](file:///e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2/cloud/w8/lab-cd9/security_groups.tf#L55-L61), cá»•ng `8081` chá»‰ Ä‘Æ°á»£c má»Ÿ Inbound duy nháº¥t cho IP cĂ¡ nhĂ¢n cá»§a Developer (`var.my_ip`). Táº¥t cáº£ cĂ¡c IP khĂ¡c trĂªn tháº¿ giá»›i quĂ©t cá»•ng nĂ y Ä‘á»u bá»‹ AWS drop traffic ngay láº­p tá»©c.
2. **Khuyáº¿n nghá»‹ mĂ´i trÆ°á»ng thá»±c táº¿ (Production)**:
   * KhĂ´ng sá»­ dá»¥ng `kubectl proxy` public.
   * Sá»­ dá»¥ng cÆ¡ cháº¿ xĂ¡c thá»±c **OIDC (OpenID Connect)** hoáº·c dĂ¹ng **VPN/Bastion Host** Ä‘á»ƒ káº¿t ná»‘i an toĂ n báº±ng HTTPS thĂ´ng qua file kubeconfig Ä‘Æ°á»£c mĂ£ hĂ³a báº£o máº­t.