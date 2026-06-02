# 🛠️ Cẩm Nang Ôn Thi Tự Luận & Thực Hành Terraform - W8 Foundation

Tài liệu này được biên soạn chi tiết nhằm giúp bạn chuẩn bị tốt nhất cho **Bài test tự luận Terraform** sắp tới, đồng thời hướng dẫn bạn cách thực hành và commit minh chứng self-study chất lượng lên repository cá nhân để ghi điểm tuyệt đối với Mentor.

---

## 🎯 Phần 1: Lý Thuyết Trọng Tâm (Dành Cho Bài Test Tự Luận)

### 1. IaC (Infrastructure as Code) là gì?
*   **Định nghĩa:** Là phương pháp quản lý và cấp phát hạ tầng CNTT (máy chủ, mạng, cơ sở dữ liệu, v.v.) bằng các tệp cấu hình (mã nguồn) có thể đọc được bởi máy tính, thay vì thực hiện thủ công qua giao diện web (Console) hoặc các tập lệnh cấu hình ad-hoc.
*   **Lợi ích cốt lõi:**
    *   **Nhất quán (Consistency):** Loại bỏ tình trạng lệch cấu hình (configuration drift), đảm bảo các môi trường Dev, Staging, Production giống hệt nhau.
    *   **Tái sử dụng (Reusability):** Dễ dàng nhân bản hạ tầng sang các vùng (Region) hoặc dự án khác bằng cách tái sử dụng code.
    *   **Kiểm soát phiên bản (Version Control):** Code được lưu trên Git, giúp theo dõi lịch sử thay đổi (ai sửa cái gì, khi nào), dễ dàng rollback khi xảy ra lỗi.
    *   **Tự động hóa & Tốc độ (Speed & Automation):** Cấp phát hạ tầng nhanh chóng thông qua các pipeline CI/CD.
*   **Phân biệt Declarative (Khai báo) vs Imperative (Mệnh lệnh):**
    *   **Declarative (Terraform):** Bạn chỉ cần định nghĩa **trạng thái mong muốn** của hệ thống (ví dụ: *"Tôi muốn có 3 máy chủ"*). Terraform sẽ tự tính toán trạng thái hiện tại và thực hiện các bước cần thiết để đạt được trạng thái đó.
    *   **Imperative (Ansible, Bash script):** Bạn phải viết rõ **từng bước thực hiện** (ví dụ: *"Bước 1: Tạo VM1, Bước 2: Tạo VM2, Bước 3: Cấu hình IP"*). Nếu một bước lỗi hoặc chạy lại, bạn phải tự xử lý tính lũy đẳng (idempotency).

---

### 2. Cú pháp HCL (HashiCorp Configuration Language) & Resource Block
*   **Cấu trúc cú pháp cơ bản:** HCL sử dụng cấu trúc khối (block) rất trực quan:
    ```hcl
    <BLOCK TYPE> "<BLOCK LABEL 1>" "<BLOCK LABEL 2>" {
      # Các thuộc tính (Arguments) bên trong
      <IDENTIFIER> = <EXPRESSION>
    }
    ```
*   **Resource Block:** Dùng để khai báo một tài nguyên cụ thể sẽ được quản lý trên hạ tầng (ví dụ: máy chủ, VPC, file).
    ```hcl
    resource "aws_instance" "web_server" {
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.micro"
    }
    ```
    *   `aws_instance` (Label 1): Loại tài nguyên (Resource Type) được định nghĩa bởi Provider.
    *   `web_server` (Label 2): Tên cục bộ (Local Name) dùng để tham chiếu tới tài nguyên này ở các nơi khác trong code Terraform.
    *   **Lưu ý cực kỳ quan trọng:** Tên tài nguyên đầy đủ trong Terraform State là `<RESOURCE TYPE>.<LOCAL NAME>` (ví dụ: `aws_instance.web_server`). Tên này là duy nhất trong cùng một module.

---

### 3. Kiểu Dữ Liệu (Data Types) trong Terraform
Terraform hỗ trợ 3 nhóm kiểu dữ liệu chính:

| Nhóm kiểu dữ liệu | Kiểu cụ thể | Mô tả & Ví dụ |
| :--- | :--- | :--- |
| **Primitive (Cơ bản)** | `string` | Chuỗi ký tự đặt trong dấu ngoặc kép. Ví dụ: `"t2.micro"`, `"us-west-2"`. |
| | `number` | Số nguyên hoặc số thực. Ví dụ: `3`, `10.5`. |
| | `bool` | Giá trị logic. Ví dụ: `true`, `false`. |
| **Collection (Tập hợp)** | `list(<TYPE>)` | Danh sách các phần tử **cùng kiểu**, có thứ tự (index từ 0). Ví dụ: `["us-east-1a", "us-east-1b"]`. |
| | `set(<TYPE>)` | Tập hợp các phần tử **không trùng lặp**, không có thứ tự. Ví dụ: `set(["admin", "user"])`. |
| | `map(<TYPE>)` | Tập hợp cặp key-value, các value phải **cùng kiểu**. Ví dụ: `{ env = "dev", project = "x-brain" }`. |
| **Structural (Cấu trúc)** | `object({...})` | Cấu trúc phức tạp gồm các thuộc tính có tên cố định, mỗi thuộc tính có thể có **kiểu dữ liệu khác nhau**. |
| | `tuple([...])` | Danh sách có số lượng phần tử cố định và kiểu dữ liệu của mỗi phần tử **có thể khác nhau**. |

---

### 4. Biến (Input Variables), Local Values & Output Values
Đây là 3 thành phần cốt lõi giúp mã nguồn Terraform linh hoạt và có cấu trúc:

#### a. Input Variables (Biến đầu vào)
*   **Mục đích:** Truyền các giá trị từ bên ngoài vào để tham số hóa code, tránh việc fix cứng (hardcode) giá trị.
*   **Cú pháp:**
    ```hcl
    variable "instance_type" {
      type        = string
      default     = "t2.micro"
      description = "Loại EC2 Instance sử dụng cho môi trường"
      sensitive   = false # Đặt thành true nếu là mật khẩu, token để tránh in ra log console
    }
    ```
*   **Cách truyền giá trị:**
    1.  Qua file `terraform.tfvars` hoặc `*.auto.tfvars` (Khuyên dùng).
    2.  Qua biến môi trường hệ thống: `TF_VAR_instance_type="t3.medium"`.
    3.  Qua tham số dòng lệnh: `-var="instance_type=t3.medium"`.
    4.  Nhập tương tác (interactive prompt) nếu không truyền bằng 3 cách trên.

#### b. Local Values (Biến cục bộ)
*   **Mục đích:** Hoạt động giống như biến nội bộ (local variable) trong lập trình. Dùng để gom nhóm các biểu thức tính toán phức tạp hoặc lặp đi lặp lại nhằm giữ code luôn sạch sẽ (DRY - Don't Repeat Yourself).
*   **Cú pháp:**
    ```hcl
    locals {
      project_name = "xbrain-aws-accelerator"
      common_tags = {
        Project   = local.project_name
        ManagedBy = "Terraform"
      }
    }
    ```
*   **Cách tham chiếu:** Sử dụng `local.<NAME>` (ví dụ: `local.common_tags`). Lưu ý: Khai báo bằng từ khóa số nhiều `locals {}` nhưng khi gọi lại dùng số ít `local.<NAME>`.

#### c. Output Values (Kết quả đầu ra)
*   **Mục đích:** Xuất các thông tin cần thiết ra màn hình sau khi chạy `terraform apply`, hoặc cung cấp giá trị cho các module khác/hệ thống CI/CD sử dụng.
*   **Cú pháp:**
    ```hcl
    output "public_ip" {
      value       = aws_instance.web_server.public_ip
      description = "Địa chỉ IP công cộng của web server"
    }
    ```

---

### 5. Expressions (Biểu thức trong Terraform)
HCL hỗ trợ nhiều biểu thức mạnh mẽ để thao tác với dữ liệu:
*   **String Interpolation (Nội suy chuỗi):** Chèn giá trị biến vào chuỗi bằng cú pháp `"${...}"`.
    *   Ví dụ: `name = "${local.project_name}-vm"`
*   **Conditional Expression (Toán tử điều kiện 3 ngôi):** Quyết định giá trị dựa trên điều kiện logic.
    *   Cú pháp: `condition ? true_val : false_val`
    *   Ví dụ: `instance_type = var.env == "prod" ? "t3.large" : "t2.micro"`
*   **For Expressions (Duyệt vòng lặp):** Tạo một list hoặc map từ một collection khác.
    *   Biến đổi list: `[for s in var.subnets : upper(s)]` (Chuyển danh sách subnet sang chữ in hoa).
    *   Biến đổi map: `{for k, v in var.tags : k => upper(v)}`.

---

### 6. Meta-Arguments
Meta-arguments là các đối số đặc biệt do Terraform cung cấp để thay đổi hành vi mặc định của resource block:

1.  **`depends_on` (Tạo phụ thuộc tường minh):**
    *   Terraform tự động nhận biết thứ tự tạo tài nguyên thông qua các tham chiếu ngầm định (implicit dependency). Tuy nhiên, nếu có phụ thuộc ẩn (ví dụ: EC2 cần một IAM Role đã active hoàn toàn nhưng code không tham chiếu trực tiếp), ta dùng `depends_on` để bắt buộc tài nguyên này phải tạo sau tài nguyên kia.
    *   Ví dụ: `depends_on = [aws_iam_role_policy_attachment.example]`
2.  **`count` (Tạo nhiều bản sao dựa trên số lượng):**
    *   Tạo ra một danh sách tài nguyên giống nhau.
    *   Sử dụng biến đặc biệt `count.index` để phân biệt tên hoặc thứ tự (bắt đầu từ 0).
    *   Ví dụ: `count = 3` sẽ tạo ra 3 EC2.
3.  **`for_each` (Tạo nhiều bản sao dựa trên Set hoặc Map):**
    *   Linh hoạt và an toàn hơn `count`. Tạo tài nguyên dựa trên các key cụ thể.
    *   Sử dụng `each.key` và `each.value` để lấy thông tin phần tử hiện tại.
    *   > [!IMPORTANT]
    *   **Vì sao `for_each` tốt hơn `count` khi quản lý danh sách tài nguyên?**
    *   Nếu dùng `count` cho một list `["dev", "staging", "prod"]` và bạn xóa phần tử `"staging"` ở giữa, Terraform sẽ coi như index 1 thay đổi và phải xóa tài nguyên `"staging"`, rename tài nguyên `"prod"` từ index 2 về index 1. Điều này gây mất mát dữ liệu hoặc downtime không đáng có. Với `for_each`, các tài nguyên được định danh bằng key tĩnh (ví dụ: `aws_instance.web["prod"]`), việc xóa key này hoàn toàn không ảnh hưởng đến key khác.
4.  **`provider`:**
    *   Sử dụng khi một resource cần dùng provider cấu hình riêng biệt (ví dụ: tạo tài nguyên ở một AWS Region khác region mặc định).
    *   Ví dụ: `provider = aws.us_west`
5.  **`lifecycle` (Quản lý vòng đời tài nguyên):**
    *   Xem chi tiết ở mục bên dưới.

---

### 7. Vòng Đời Tài Nguyên & Khối `lifecycle`
Mặc định, khi một tài nguyên bị thay đổi các thuộc tính không thể cập nhật trực tiếp (in-place update), Terraform sẽ **xóa tài nguyên cũ trước rồi mới tạo tài nguyên mới**. Khối `lifecycle` dùng để thay đổi hành vi này:

*   **`create_before_destroy = true`:**
    *   **Hành vi:** Terraform sẽ tạo tài nguyên MỚI trước, kiểm tra xem nó có hoạt động thành công không, sau đó mới tiến hành xóa tài nguyên CŨ.
    *   **Mục đích:** Giảm thiểu tối đa downtime cho các dịch vụ quan trọng (ví dụ: Web Server, Load Balancer).
*   **`prevent_destroy = true`:**
    *   **Hành vi:** Ngăn chặn bất kỳ hành động `terraform destroy` hoặc thay đổi cấu hình nào dẫn đến việc xóa tài nguyên này. Nếu cố tình xóa, Terraform sẽ báo lỗi và dừng thực thi.
    *   **Mục đích:** Bảo vệ các tài nguyên cực kỳ quan trọng không được phép mất mát (ví dụ: Production Database, S3 Bucket chứa dữ liệu lịch sử).
*   **`ignore_changes = [ <ATTRIBUTES> ]`:**
    *   **Hành vi:** Terraform sẽ bỏ qua không theo dõi sự thay đổi của các thuộc tính được chỉ định nếu các thay đổi đó được thực hiện bên ngoài Terraform (ví dụ: Sysadmin đổi tag thủ công trên AWS Console, hoặc Auto Scaling Group tự động thay đổi số lượng instance).
    *   **Ví dụ:** `ignore_changes = [tags, instance_type]`
*   **`replace_triggered_by = [ <RESOURCE_REFERENCE> ]`:**
    *   **Hành vi:** Tài nguyên này sẽ tự động bị thay thế (replace/recreate) nếu một tài nguyên khác được cấu hình trong danh sách bị thay đổi.
    *   **Ví dụ:** Khi file cấu hình app (ConfigMap) thay đổi, ta muốn khởi động lại/thay thế EC2 instance chạy app đó.

---

### 8. Terraform Modules
*   **Khái niệm:** Module là một tập hợp các tệp cấu hình `.tf` nằm chung trong một thư mục. Module giúp đóng gói các thành phần hạ tầng có liên quan để dễ dàng tái sử dụng (như một hàm trong lập trình).
*   **Cấu trúc chuẩn của một Module cục bộ:**
    ```text
    modules/local_server/
    ├── main.tf        # Định nghĩa các tài nguyên chính của module
    ├── variables.tf   # Khai báo các input variables của module (tham số đầu vào)
    └── outputs.tf     # Định nghĩa đầu ra của module để tầng cha sử dụng
    ```
*   **Cách gọi/sử dụng Module từ file cấu hình gốc (Root Module):**
    ```hcl
    module "my_web_server" {
      source = "./modules/local_server" # Đường dẫn đến thư mục module
      
      # Truyền các biến đầu vào cho module
      server_name   = "production-web"
      instance_type = "t3.medium"
    }
    
    # Sử dụng output của module ở root
    resource "null_resource" "trigger" {
      provisioner "local-exec" {
        command = "echo IP của server là: ${module.my_web_server.server_ip}"
      }
    }
    ```

---

## 💻 Phần 2: Hướng Dẫn Thực Hành & Cấu Trúc Repo

Để chứng minh với Mentor rằng bạn đã tự học và nắm vững toàn bộ các kiến thức trên, chúng ta sẽ xây dựng một dự án Terraform hoàn chỉnh sử dụng **`local` provider** (không cần tài khoản AWS, chạy offline 100% cực kỳ an toàn và nhanh chóng trên máy tính của bạn). Dự án này sẽ tạo các file cấu hình và thư mục ngay trên máy local của bạn.

### 🌟 Cấu Trúc Repo Bạn Cần Tạo Trong `cloud/w8/day-a/`

```text
cloud/w8/day-a/
├── modules/
│   └── local_server/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── main.tf
├── variables.tf
├── locals.tf
├── outputs.tf
├── terraform.tfvars
└── TERRAFORM_STUDY_GUIDE.md  (File tài liệu ôn tập này!)
```

---

## 🚀 Các Bước Chạy Thử Trên Máy Tính Cá Nhân

Nếu bạn đã cài đặt `terraform` trên máy (hoặc muốn chạy thử ngay), hãy thực hiện các bước sau tại thư mục `cloud/w8/day-a/`:

1.  **Khởi tạo dự án (Download Provider & Cấu hình môi trường):**
    ```bash
    terraform init
    ```
2.  **Kiểm tra cú pháp và Xem trước các tài nguyên sẽ được tạo:**
    ```bash
    terraform plan
    ```
3.  **Tạo tài nguyên (Tạo các file cấu hình giả lập trên máy của bạn):**
    ```bash
    terraform apply -auto-approve
    ```
    *Sau khi apply thành công, bạn sẽ thấy các file cấu hình giả lập xuất hiện tại thư mục `cloud/w8/day-a/` và các thông tin output in ra màn hình!*
4.  **Dọn dẹp tài nguyên (Xóa các file giả lập đã tạo để giữ repo sạch):**
    ```bash
    terraform destroy -auto-approve
    ```

---

## 💾 Hướng Dẫn Commit & Push Lên Github Cá Nhân

Sau khi chúng ta tạo xong bộ code này, hãy chạy các lệnh Git sau để push lên repository cá nhân của bạn. Mentor sẽ chấm điểm dựa trên lịch sử commit này!

> [!IMPORTANT]
> Hãy đảm bảo bạn sử dụng đúng format commit message do BTC yêu cầu: `[W8-D1] <topic ngắn>`

```bash
# 1. Di chuyển vào thư mục repo cá nhân (nếu chưa ở đó)
cd e:/x-brain/W8/NguyenDinhThi-aws-accelerator-p2

# 2. Kiểm tra các file thay đổi
git status

# 3. Add toàn bộ các file ôn tập và thực hành Terraform
git add cloud/w8/day-a/

# 4. Commit với đúng format yêu cầu
git commit -m "[W8-D1] Study Terraform IaC basics, modules, lifecycle and variables"

# 5. Push lên Github
git push origin main
```

**Chúc bạn ôn tập thật tốt và đạt điểm tối đa trong bài thi tự luận ngày mai! 🚀🔥**
