# W8 Reflection - Foundation: IaC + K8s

## 📝 Nhật ký học tập & Thực hành

### 1. Terraform (Day A - Thứ 2 & Thứ 3)
*   **Kiến thức đã học:**
    *   IaC Overview & HCL Syntax: Hiểu mô hình Declarative vs Imperative, cấu trúc HCL block.
    *   Terraform Workflow: Quy trình chuẩn Init -> Plan -> Apply -> Destroy.
    *   State Management: Hiểu cách Terraform lưu trạng thái tài nguyên thực tế để so sánh với mong muốn.
    *   Kiểu dữ liệu & Biến: Định nghĩa primitive (string, number, bool), collection (list, set, map), structural (object, tuple), và cách truyền tfvars.
    *   Locals & Outputs: Tối ưu hóa biểu thức lặp lại bằng locals và trích xuất dữ liệu đầu ra bằng outputs.
    *   Meta-arguments & Lifecycle: Sử dụng depends_on, count, for_each (ưu việt hơn count) và cấu hình lifecycle (create_before_destroy, prevent_destroy, ignore_changes).
    *   Modules: Đóng gói và tái sử dụng cấu hình với module cục bộ (variables, outputs, main).
*   **Thực hành:** Đã xây dựng hoàn chỉnh dự án Terraform cục bộ (sử dụng local provider) mô phỏng server ảo tại thư mục `day-a` và đính kèm cẩm nang ôn thi tự luận.
*   **Kết quả Online Test 1:** [Điền điểm sau khi hoàn thành bài test ở đây]
*   **Những khó khăn gặp phải & Cách giải quyết:**
    *   *Khó khăn:* Phân biệt khi nào nên dùng `count` vs `for_each`.
    *   *Giải quyết:* Nhận ra `for_each` an toàn hơn `count` khi chỉnh sửa danh sách tài nguyên ở giữa vì nó sử dụng key tĩnh, tránh việc dịch chuyển index gây recreate các tài nguyên khác.


### 2. Kubernetes (Day B & Day C - Thứ 4 & Thứ 5)
*   **Kiến thức đã học:**
    *   Kiến trúc Control Plane (api-server, etcd, scheduler, controller-manager) và Worker Node (kubelet, kube-proxy, container runtime).
    *   Pod: Đơn vị cơ bản, vòng đời (Pending, Running, Succeeded, Failed, Unknown) và phối hợp container.
    *   Probes: Liveness Probe (kiểm tra sống/treo), Readiness Probe (kiểm tra sẵn sàng nhận traffic), và Startup Probe (bảo vệ khi app khởi động chậm).
    *   Service: ClusterIP (nội bộ), NodePort (mở port Node tĩnh), LoadBalancer (tích hợp Cloud) để định tuyến.
    *   ConfigMap & Secret: Tách cấu hình và dữ liệu nhạy cảm mã hóa Base64 khỏi container image qua Env và Volume Mount.
    *   NetworkPolicy: Thiết lập chính sách bảo mật mạng cho Pod (Ingress/Egress).
*   **Thực hành:** Thiết lập các file YAML chuẩn (`pod-demo.yaml`, `service-demo.yaml`, `configmap-secret-demo.yaml`, `network-policy-demo.yaml`) và hoàn thành tài liệu cẩm nang tự học K8s cho Day B.
*   **Những khó khăn gặp phải & Cách giải quyết:**
    *   *Khó khăn:* Hiểu cách thức hoạt động của NetworkPolicy và tại sao nó không có hiệu lực mặc định trên một số môi trường local.
    *   *Giải quyết:* Biết rằng NetworkPolicy cần có một CNI plugin hỗ trợ (như Calico hoặc Cilium) được cài đặt và cấu hình trong Cluster (khi dùng Minikube cần start với flag `--cni=calico`).


### 3. Lab "Mini K8s platform trên Minikube" (Day C & Lab - Thứ 5 & Thứ 6)
*   **Mô tả Lab:**
    *   Xây dựng nền tảng K8s tối giản trên minikube local.
*   **Kết quả đạt được (Show-and-tell):**
    *   ...
*   **Kết quả Online Test 2:** [Điền điểm hoặc đánh giá ở đây]

---

## 💡 Bài học rút ra & Cải tiến cho tuần sau
*   ...
