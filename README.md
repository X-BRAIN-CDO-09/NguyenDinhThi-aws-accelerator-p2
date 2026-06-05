<p align="center">
  <img src="https://img.icons8.com/color/96/000000/cloud-systems.png" alt="AWS DevOps Logo" width="80"/>
</p>

# <p align="center">☁️ AWS DevOps & Cloud Accelerator</p>

### <p align="center">Phase 2 Project Portfolio — XBrain DevOps Engineering Bootcamp</p>

<p align="center">
  <a href="https://terraform.io"><img src="https://img.shields.io/badge/TERRAFORM-1.5+-7B42BC?style=for-the-badge&logo=terraform&logoColor=white" alt="Terraform"/></a>
  <a href="https://kubernetes.io"><img src="https://img.shields.io/badge/KUBERNETES-v1.30-326CE5?style=for-the-badge&logo=kubernetes&logoColor=white" alt="Kubernetes"/></a>
  <a href="https://aws.amazon.com"><img src="https://img.shields.io/badge/AWS-CLOUD-FF9900?style=for-the-badge&logo=amazon-aws&logoColor=white" alt="AWS"/></a>
  <a href="https://docker.com"><img src="https://img.shields.io/badge/DOCKER-ENGINE-2496ED?style=for-the-badge&logo=docker&logoColor=white" alt="Docker"/></a>
</p>

<p align="center">
  <a href="./cloud/w8/lab-cd9/evidence.md"><img src="https://img.shields.io/badge/EVIDENCE%20PACK-VIEW%20NOW-4CAF50?style=for-the-badge&logo=google-docs&logoColor=white" alt="Evidence Pack"/></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/LICENSE-MIT-607d8b?style=for-the-badge" alt="License"/></a>
</p>

> A comprehensive portfolio of cloud infrastructure and DevOps automation projects.
> Built using Infrastructure as Code (Terraform), Kubernetes container orchestration, and AWS cloud resources.

---

<p align="center">
  <b>Nguyễn Đình Thi</b> · <code>XB-DN26-103</code> · <b>Phase 2 Submission</b> · Deadline: 05/06/2026
</p>

---

## 📌 Lịch trình Tuần 8 — Foundation: IaC & K8s

Tuần này chúng ta tập trung xây dựng nền tảng vững chắc với Infrastructure as Code (Terraform) và Kubernetes container orchestration.

| Thứ / Ngày | Hoạt động self-study | Nội dung & Checkpoints |
| :--- | :--- | :--- |
| **Thứ 2 (01/06)** | **Self-study Terraform P1** | Tìm hiểu tổng quan về IaC, làm quen cú pháp HCL syntax. |
| **Thứ 3 (02/06)** | **Self-study Terraform P2** | <ul><li>Học về Terraform Workflow (Init/Plan/Apply/Destroy), State Management, Modules, Best Practices.</li><li>**15h00 – 17h00:** LIVE Terraform với mentor Minh (online).</li><li>**17h00 – 18h00:** **Online Test 1** (60 phút, phạm vi Terraform).</li></ul> |
| **Thứ 4 (03/06)** | **Self-study Kubernetes (K8s)** | <ul><li>Đọc trước kiến thức nền về Container/Orchestration (Pod, Service, probes, ConfigMap/Secret, NetworkPolicy).</li><li>Cài đặt sẵn **Docker Desktop + minikube + kubectl** trên máy cá nhân.</li></ul> |
| **Thứ 5 (04/06)** | **Onsite Đà Nẵng (Mentor Nghĩa)** | <ul><li>Học trực tiếp về K8s Container/Orchestration + scaling/networking/deploy trên minikube.</li><li>Bắt đầu làm **Lab "Mini K8s platform trên minikube"**.</li></ul> |
| **Thứ 6 (05/06)** | **Onsite Đà Nẵng & Test 2** | <ul><li>Hoàn thiện Lab trên minikube local.</li><li>**13h30 – 15h00:** Show-and-tell theo nhóm 5 người.</li><li>**15h00 – 16h00:** **Online Test 2** (60 phút, phạm vi K8s + Lab).</li></ul> |

---

## 📂 Cấu trúc thư mục Phase 2

Repo cá nhân chứa toàn bộ bài tập, lab và reflection được cấu trúc rõ ràng như sau:

```text
cloud/
  w8/
    day-a/              # Terraform (Lý thuyết & Bài tập ngày 1+2)
    day-b/              # K8s Container/Orchestration (Lý thuyết & Cài đặt ngày 3)
    day-c/              # K8s Scaling + Networking (Lab onsite ngày 4)
    lab-cd9/            # Dự án Lab: 1-Click Automation Platform (ngày 5)
    reflection.md       # Báo cáo thu hoạch & Nhật ký học tập Tuần 8
  w9/
  w10/
capstone/
  w11/
  w12/
```

---

## 🛠️ Quy định Commit (Commit Message Rules)

Để mentor dễ dàng theo dõi tiến độ học tập hàng ngày của bạn, hãy tuân thủ quy định commit sau:

### 1. Định dạng commit chuẩn:
```bash
[W<Week>-D<Day>] <topic ngắn gọn>
```
*   **Ví dụ:**
    *   `[W8-D1] study terraform basics and HCL syntax`
    *   `[W8-D2] complete terraform workflow exercises`
    *   `[W8-D3] install minikube and kubectl, study pod concepts`
    *   `[W8-D4] implement network policies on minikube`

### 2. Tần suất push:
*   Push code lên GitHub hằng ngày từ **Thứ 2 đến Thứ 4** và sau mỗi buổi lab onsite.

> [!IMPORTANT]
> **Hệ thống tự động kiểm tra Commit (Git Hook):**  
> Một git hook `commit-msg` đã được cài đặt tự động trong repo local của bạn (`.git/hooks/commit-msg`). Khi bạn thực hiện lệnh `git commit`, hệ thống sẽ tự động xác thực tin nhắn commit của bạn. Nếu không đúng định dạng `[W<Week>-D<Day>] <nội dung>`, commit sẽ bị từ chối kèm theo thông báo hướng dẫn. Điều này giúp bạn không bao giờ commit sai luật của khóa học!

---

## 📖 Tài liệu tham khảo & Công cụ hỗ trợ

### 1. Terraform
*   [HashiCorp Learn - Get Started AWS](https://developer.hashicorp.com/terraform/tutorials)
*   [Terraform Docs](https://developer.hashicorp.com/terraform/docs)
*   [Terraform Best Practices](https://www.terraform-best-practices.com)
*   [Series: Terraform from Basics to Production (Nghĩa Huỳnh)](https://kkloudtarus.net/en/blog/series/terraform-from-basics-to-production)

### 2. Docker & Kubernetes
*   [Docker Docs](https://docs.docker.com)
*   [Docker Curriculum](https://docker-curriculum.com)
*   [Kubernetes Docs](https://kubernetes.io/docs)
*   [minikube Get Started](https://minikube.sigs.k8s.io/docs/start)
*   [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet)

### 3. AWS (Phục vụ Lab)
*   [AWS Skill Builder](https://skillbuilder.aws)
*   [AWS Workshops](https://workshops.aws)
