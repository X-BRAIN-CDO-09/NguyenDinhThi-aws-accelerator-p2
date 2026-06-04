# BÁO CÁO KẾT QUẢ THỰC HÀNH - LAB CD9
**Học viên:** Nguyễn Đình Thi  
**Dự án:** 1-Click Automation: Terraform ➔ Custom VPC ➔ EC2 (Kind K8s) ➔ K8s Provider ➔ ALB  
**Chương trình:** AWS Accelerator Program  

---

## 1. Khởi tạo Thư mục Dự án (`terraform init`)
Chạy lệnh `terraform init` để tải về các Providers (`aws`, `tls`, `local`, `kubernetes`) được khai báo trong tệp cấu hình `providers.tf`.

### Lệnh thực thi:
```bash
terraform init
```

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình Terminal sau khi chạy xong lệnh `terraform init`, hiển thị thông báo thành công `Terraform has been successfully initialized!`.*

![Screenshot 1: Kết quả chạy lệnh terraform init thành công](images/screenshot_1_init.png)
*(Hướng dẫn: Thay thế đường dẫn trên bằng đường dẫn ảnh chụp màn hình của bạn)*

---

## 2. Lập Kế hoạch Triển khai (`terraform plan`)
Chạy lệnh `terraform plan` để kiểm tra kế hoạch triển khai. Đầu ra phải hiển thị thông tin tạo mới **14 tài nguyên** (bao gồm cả hạ tầng AWS lẫn tài nguyên Kubernetes).

### Lệnh thực thi:
```bash
terraform plan
```

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình Terminal hiển thị phần tóm tắt kế hoạch tạo tài nguyên ở cuối đầu ra: `Plan: 14 to add, 0 to change, 0 to destroy.`.*

![Screenshot 2: Kết quả chạy lệnh terraform plan hiển thị 14 tài nguyên cần tạo](images/screenshot_2_plan.png)

---

## 3. Thực thi Triển khai tự động (`terraform apply`)
Chạy lệnh `terraform apply -auto-approve` để kích hoạt toàn bộ luồng tự động hóa. Terraform sẽ tự động dựng hạ tầng AWS, chạy script bootstrap trên EC2 cài Kind K8s, chờ K8s API Proxy sẵn sàng, và triển khai Nginx Deployment lên Cluster.

### Lệnh thực thi:
```bash
terraform apply -auto-approve
```

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình Terminal hiển thị thông báo hoàn tất triển khai thành công `Apply complete! Resources: 14 added, 0 changed, 0 destroyed.` và danh sách các giá trị `Outputs` ở cuối.*

![Screenshot 3: Kết quả lệnh terraform apply hoàn tất thành công](images/screenshot_3_apply.png)

---

## 4. Xác minh Hạ tầng trên AWS Console
Kiểm tra các tài nguyên vừa được tạo tự động trên giao diện điều khiển AWS.

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình giao diện danh sách EC2 Instance trên AWS Console hiển thị instance `lab-cd9-minikube` ở trạng thái `Running`.*

![Screenshot 4.1: Máy chủ EC2 Instance ở trạng thái Running trên AWS Console](images/screenshot_4_1_ec2.png)

> [!IMPORTANT]
> *Chụp ảnh màn hình giao diện Load Balancer trên AWS Console hiển thị Application Load Balancer `lab-cd9-alb` ở trạng thái `Active`.*

![Screenshot 4.2: Application Load Balancer ở trạng thái Active trên AWS Console](images/screenshot_4_2_alb.png)

---

## 5. SSH và Kiểm tra trạng thái Tài nguyên Kubernetes
Sử dụng khóa Private Key `.pem` được ghi tự động ở local để SSH vào máy chủ EC2, kiểm tra các Pod và Service chạy trong Namespace `lab-cd9`.

### Lệnh thực thi:
```bash
# SSH vào máy chủ EC2 sử dụng file key sinh động
ssh -i ./lab-cd9-key.pem ubuntu@<IP-Public-EC2>

# Kiểm tra danh sách Pods và Services trong Cluster
kubectl get pods -n lab-cd9
kubectl get svc -n lab-cd9
```

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình Terminal sau khi SSH vào EC2 và chạy lệnh `kubectl get pods,svc -n lab-cd9` hiển thị Pod `web-app` ở trạng thái `Running` và Service `web-service` loại `NodePort` đã được expose.*

![Screenshot 5: SSH vào EC2 và kiểm tra trạng thái Pods/Services của Kubernetes](images/screenshot_5_k8s_verify.png)

---

## 6. Truy cập Ứng dụng qua Load Balancer DNS
Sử dụng địa chỉ DNS được cung cấp ở output `alb_dns_name` để truy cập vào ứng dụng từ trình duyệt Web. Trình duyệt sẽ hiển thị trang giao diện báo cáo kèm theo bảng điều khiển trực quan 1-Click mô phỏng kiến trúc hệ thống.

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình trình duyệt Web khi truy cập bằng URL Load Balancer DNS, hiển thị đầy đủ tiêu đề "LAB CD9 — Hệ Thống Tự Động Hóa 1-Click", các sơ đồ dọc, và bảng điều khiển mô phỏng 1-Click.*

![Screenshot 6: Truy cập giao diện ứng dụng thành công qua ALB DNS trên trình duyệt](images/screenshot_6_browser.png)

---

## 7. Dọn dẹp Tài nguyên (`terraform destroy`)
Hủy toàn bộ hạ tầng đã tạo để tránh phát sinh chi phí không mong muốn trên AWS tài khoản của bạn.

### Lệnh thực thi:
```bash
terraform destroy -auto-approve
```

### Minh chứng kết quả:
> [!IMPORTANT]
> *Chụp ảnh màn hình Terminal hiển thị thông báo phá hủy hạ tầng hoàn tất `Destroy complete! Resources: 14 destroyed.`.*

![Screenshot 7: Kết quả chạy lệnh terraform destroy dọn dẹp tài nguyên thành công](images/screenshot_7_destroy.png)
