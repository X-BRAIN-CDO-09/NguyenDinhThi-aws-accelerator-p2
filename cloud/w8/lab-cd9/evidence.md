# BÁO CÁO NGHIỆM THU (EVIDENCE REPORT)
## ĐỀ BÀI: K8s on AWS — Terraform 1-Click

* **Học viên:** Nguyễn Đình Thi  
* **Dự án:** LAB CD9 — 1-Click Automation  
* **Nguồn Repo:** [X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2](https://github.com/X-BRAIN-CDO-09/NguyenDinhThi-aws-accelerator-p2.git)  

---

## I. BẢNG ĐỐI CHIẾU TIÊU CHÍ ĐẠT (ACCEPTANCE CHECKLIST)

Dưới đây là bảng đối chiếu các yêu cầu bắt buộc của đề bài so với kết quả thực tế của giải pháp:

| STT | Yêu cầu bắt buộc của Đề bài | Trạng thái | Giải pháp kỹ thuật thực tế trong Dự án |
| :--- | :--- | :---: | :--- |
| **1** | Hạ tầng (EC2 + mạng) dựng bằng **Terraform** | **ĐẠT** | Tự động tạo Custom VPC, 2 Subnets, Internet Gateway, Route Tables, Security Groups, EC2 và ALB. |
| **2** | Cụm K8s chạy bằng **minikube hoặc kind** trên EC2 | **ĐẠT** | Sử dụng **Kind** chạy trên Docker Engine của EC2. |
| **3** | App chạy **trong K8s** (không cài thẳng lên EC2) | **ĐẠT** | Ứng dụng chạy dưới dạng Pod trong Namespace `lab-cd9` của cụm Kind K8s. |
| **4** | App truy cập được từ **Internet qua ALB** | **ĐẠT** | ALB lắng nghe cổng 80 công cộng và forward traffic vào cổng NodePort `30080` của EC2 được ánh xạ từ Pod. |
| **5** | **Một lệnh** để dựng tất cả (1-click) | **ĐẠT** | Chỉ chạy duy nhất lệnh `terraform apply -auto-approve` để khởi tạo tự động toàn bộ từ đầu đến cuối. |
| **6** | Có dùng **$\ge 2$ provider** (wire provider khác) | **ĐẠT** | Sử dụng **4 providers**: `aws`, `tls` (sinh SSH Key), `local` (ghi file `.pem`), và `kubernetes` (triển khai app). |
| **7** | Dọn được sạch (**destroy**) sau khi xong | **ĐẠT** | Chạy lệnh `terraform destroy -auto-approve` để xóa sạch toàn bộ 14 tài nguyên tránh tốn phí. |

---

## II. GIẢI THÍCH KIẾN TRÚC & QUYẾT ĐỊNH THIẾT KẾ (TRAINER ORAL PREPARATION)

### 1. Cơ chế "Wire" các Provider trong dự án
Dự án thực hiện liên kết (wire) chặt chẽ giữa các Provider độc lập:
* **TLS Provider ➔ AWS Provider**: Tài nguyên `tls_private_key.ssh` sinh khóa Public Key trực tiếp trong bộ nhớ RAM, sau đó truyền kết quả sang làm tham số đầu vào cho `aws_key_pair.deployer` để nạp lên AWS. Khóa Private Key được `local_file` ghi xuống ổ cứng dạng `.pem` để Dev sử dụng kết nối SSH.
* **AWS Provider ➔ Kubernetes Provider**: 
  - Khối `provider "kubernetes"` sử dụng địa chỉ Host cấu hình động: `http://${aws_instance.minikube.public_ip}:8081`.
  - IP của EC2 được sinh ra bởi AWS Provider sẽ tự động được truyền vào làm tham số đầu cuối cho Kubernetes Provider kết nối.

### 2. Cách kết nối Kubernetes với ALB (Expose Network ra Host)
* **Thách thức**: Cluster chạy bằng Kind nằm trong mạng cô lập của Docker. ALB ngoài Internet không thể trỏ trực tiếp vào IP nội bộ của Container Pod.
* **Giải pháp**: 
  1. Trong `user_data.sh`, cụm Kind được khởi tạo với cấu hình `extraPortMappings` ánh xạ cổng NodePort `30080` của container control-plane ra cổng `30080` của máy chủ EC2.
  2. Bảng mục tiêu của Load Balancer (`aws_lb_target_group`) được cấu hình trỏ vào cổng `30080` của máy chủ EC2.
  3. Khi User truy cập ALB (Port 80) ➔ ALB chuyển tiếp tới EC2 (Port 30080) ➔ Host EC2 định tuyến tiếp vào Service NodePort (Port 30080) ➔ Đi tới Pod ứng dụng (Port 80).

### 3. Giải quyết bài toán phụ thuộc thời gian (Dependency & Bootstrapping)
* Nếu gọi Kubernetes Provider ngay từ đầu, Terraform sẽ báo lỗi do cụm K8s chưa tồn tại trên máy ảo EC2.
* **Giải pháp**: Sử dụng tài nguyên đồng bộ trung gian `null_resource.wait_for_minikube`. Tài nguyên này bắt buộc phải đợi EC2 khởi tạo xong (`depends_on = [aws_instance.minikube]`), sau đó thực hiện SSH vào chạy lệnh `sudo cloud-init status --wait` để chờ script `user_data.sh` cài đặt K8s hoàn tất.
* Các tài nguyên Kubernetes trong file `kubernetes.tf` đều khai báo `depends_on = [null_resource.wait_for_minikube]` để đảm bảo chúng chỉ chạy sau khi cụm K8s đã sẵn sàng tiếp nhận kết nối.

---

## III. BẰNG CHỨNG THỰC THI (DELIVERABLES & SCREENSHOTS)

> [!CAUTION]
> *Học viên chụp các hình ảnh thực tế từ Terminal và Trình duyệt của mình rồi lưu vào thư mục `images/` đúng theo tên file định nghĩa dưới đây.*

### 1. Khởi tạo Dự án (`terraform init`)
Lệnh khởi tạo tải thành công cả 4 providers cần thiết về local.

* **Hình chụp yêu cầu**: Terminal hiển thị thông báo `Terraform has been successfully initialized!` cùng danh sách các provider: `aws`, `tls`, `local`, `kubernetes`.

![Screenshot 1: Kết quả chạy lệnh terraform init thành công](images/screenshot_1_init.png)

---

### 2. Xem Kế hoạch Triển khai (`terraform plan`)
Terraform xây dựng thành công đồ thị phụ thuộc và báo cáo sẽ tạo mới 14 tài nguyên.

* **Hình chụp yêu cầu**: Terminal hiển thị phần tóm tắt kế hoạch ở cuối: `Plan: 14 to add, 0 to change, 0 to destroy.`

![Screenshot 2: Kết quả chạy lệnh terraform plan hiển thị 14 tài nguyên cần tạo](images/screenshot_2_plan.png)

---

### 3. Triển khai 1-Click (`terraform apply`)
Quá trình cài đặt tự động từ hạ tầng đến ứng dụng chạy hoàn tất sau khoảng 3-5 phút.

* **Hình chụp yêu cầu**: Terminal hiển thị thông báo `Apply complete! Resources: 14 added, 0 changed, 0 destroyed.` và in ra các outputs ở cuối (`alb_dns_name`, `instance_public_ip`, `ssh_command`).

![Screenshot 3: Kết quả lệnh terraform apply hoàn tất thành công](images/screenshot_3_apply.png)

---

### 4. Máy chủ EC2 và Load Balancer trạng thái Running/Active trên AWS Console
Xác minh trực quan trên giao diện AWS Web Console để chứng minh tài nguyên thực tế đã chạy.

* **Hình chụp EC2**: Danh sách EC2 Instance hiển thị máy ảo `lab-cd9-minikube` đang có trạng thái `Instance state: Running`.

![Screenshot 4.1: Máy chủ EC2 Instance ở trạng thái Running trên AWS Console](images/screenshot_4_1_ec2.png)

* **Hình chụp ALB**: Danh sách Load Balancer hiển thị `lab-cd9-alb` ở trạng thái `State: Active`.

![Screenshot 4.2: Application Load Balancer ở trạng thái Active trên AWS Console](images/screenshot_4_2_alb.png)

---

### 5. Ứng dụng thực sự chạy trong cụm K8s (Không cài thẳng EC2)
SSH vào EC2 kiểm tra trạng thái Pods và Services để chứng minh ứng dụng được cô lập an toàn trong Kubernetes.

* **Hình chụp yêu cầu**: Cửa sổ Terminal SSH hiển thị kết quả chạy lệnh `kubectl get pods,svc -n lab-cd9` hiển thị Pod `web-app` trạng thái `Running` và Service NodePort `web-service` mở cổng `30080`.

![Screenshot 5: SSH vào EC2 và kiểm tra trạng thái Pods/Services của Kubernetes](images/screenshot_5_k8s_verify.png)

---

### 6. Truy cập ứng dụng qua Load Balancer trên Trình duyệt
Mở địa chỉ URL xuất ra từ output `alb_dns_name` trên trình duyệt web.

* **Hình chụp yêu cầu**: Trình duyệt web hiển thị trang báo cáo kiến trúc hạ tầng và bảng mô phỏng trực quan 1-Click tự động hóa mà không có lỗi kết nối.

![Screenshot 6: Truy cập giao diện ứng dụng thành công qua ALB DNS trên trình duyệt](images/screenshot_6_browser.png)

---

### 7. Dọn dẹp sạch sẽ tài nguyên (`terraform destroy`)
Hủy bỏ toàn bộ hạ tầng để tránh tốn phí.

* **Hình chụp yêu cầu**: Terminal hiển thị thông báo dọn dẹp thành công: `Destroy complete! Resources: 14 destroyed.`

![Screenshot 7: Kết quả chạy lệnh terraform destroy dọn dẹp tài nguyên thành công](images/screenshot_7_destroy.png)
