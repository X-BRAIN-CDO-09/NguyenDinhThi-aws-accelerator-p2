# Ghi Chú Học Tập — W9 Session 02: Installing the CloudWatch Agent on EC2

## 1. Vấn Đề Cốt Lõi: EC2 Built-in Metrics vs Custom Metrics

### EC2 Metrics có sẵn (Namespace: AWS/EC2)

| Metric | Mô tả | Có sẵn không? |
|--------|-------|:-------------:|
| `CPUUtilization` | % CPU đang dùng | ✅ |
| `NetworkIn` / `NetworkOut` | Bytes nhận/gửi qua network | ✅ |
| `DiskReadOps` / `DiskWriteOps` | Số lần đọc/ghi disk (EBS) | ✅ |
| `StatusCheckFailed` | EC2 health check | ✅ |
| **`mem_used_percent`** | **% RAM đang dùng** | **❌ Cần Agent** |
| **`disk_used_percent`** | **% Disk đang dùng** | **❌ Cần Agent** |
| **`swap_used_percent`** | **% Swap đang dùng** | **❌ Cần Agent** |

> **Lý do:** AWS chỉ thu thập metrics từ **hypervisor level** (bên ngoài VM). Memory và Disk usage là thông tin nội bộ của OS — chỉ có thể đọc từ bên trong VM bằng CloudWatch Agent.

---

## 2. CloudWatch Agent là gì?

```
                    ┌─────────────────────────────────────────────┐
                    │              EC2 Instance                    │
                    │                                             │
                    │   ┌──────────────────────────────────────┐  │
                    │   │      CloudWatch Agent (daemon)        │  │
                    │   │                                      │  │
                    │   │  Reads:                              │  │
                    │   │    /proc/meminfo  → mem_used_percent │  │
                    │   │    /proc/diskstats → disk_used       │  │
                    │   │    /proc/cpuinfo  → cpu_usage_user   │  │
                    │   │    /proc/net/dev  → bytes_sent/recv  │  │
                    │   │    /var/log/*     → Log files        │  │
                    │   └──────────────────┬───────────────────┘  │
                    │   IAM Role:          │ PutMetricData API     │
                    │   CloudWatchAgent    │ PutLogEvents API      │
                    │   ServerPolicy       │                       │
                    └─────────────────────┼─────────────────────┘
                                          │
                                          ▼
                    ┌─────────────────────────────────────────────┐
                    │          CloudWatch Service (AWS)            │
                    │  Namespace: W9Lab/CustomMetrics              │
                    │  Metrics: mem_used_percent, disk_used%, ... │
                    │  Logs: /w9-lab/ec2/system                   │
                    └─────────────────────────────────────────────┘
```

### Các tính năng chính

| Tính năng | Mô tả |
|-----------|-------|
| **Custom Metrics** | Thu thập Memory, Disk, Process không có sẵn trong AWS/EC2 |
| **Log Collection** | Đẩy log files từ OS lên CloudWatch Logs |
| **StatsD / collectd** | Nhận metrics từ ứng dụng qua UDP (statsd protocol) |
| **Custom Namespace** | Gom metrics vào namespace riêng (e.g., `W9Lab/CustomMetrics`) |

---

## 3. IAM Prerequisite — CloudWatchAgentServerPolicy

Đây là **điều kiện tiên quyết** được nhấn mạnh trong slide:

```
EC2 IAM Role
└── Must have: CloudWatchAgentServerPolicy
    ├── cloudwatch:PutMetricData      → Gửi custom metrics
    ├── cloudwatch:GetMetricStatistics → Đọc metrics
    ├── logs:CreateLogGroup            → Tạo log group
    ├── logs:CreateLogStream           → Tạo log stream
    ├── logs:PutLogEvents              → Gửi logs
    └── ssm:GetParameter               → Đọc config từ SSM
```

> **Best practice:** Attach `CloudWatchAgentServerPolicy` AWS managed policy thay vì tạo policy thủ công — đảm bảo luôn up-to-date với permissions cần thiết.

---

## 4. Cấu trúc File Config JSON

```json
{
  "agent": {
    "metrics_collection_interval": 60,   // Thu thập mỗi 60 giây
    "logfile": "/opt/aws/amazon-cloudwatch-agent/logs/..."
  },
  "metrics": {
    "namespace": "W9Lab/CustomMetrics",  // Custom namespace
    "append_dimensions": {
      "InstanceId": "${aws:InstanceId}"   // Gắn tag EC2 ID vào từng metric
    },
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent", ...] },
      "disk": { "resources": ["/"], "measurement": ["disk_used_percent", ...] },
      "cpu": { "measurement": ["cpu_usage_user", ...], "totalcpu": true }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          { "file_path": "/var/log/messages", "log_group_name": "/w9-lab/ec2/system" }
        ]
      }
    }
  }
}
```

---

## 5. Cách Cài Đặt Agent (4 bước từ slide)

### Bước 1: Install the Agent Package

```bash
# Amazon Linux 2023 / RHEL:
sudo dnf install -y amazon-cloudwatch-agent

# Ubuntu / Debian:
sudo apt-get install -y amazon-cloudwatch-agent
```

### Bước 2: Run Configuration Wizard hoặc dùng JSON Config

**Cách A — Wizard tương tác:**
```bash
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-config-wizard
```
Wizard sẽ hỏi từng bước: namespace, metrics muốn collect, log files...

**Cách B — JSON config file (Best practice trong IaC):**
```bash
# Lưu config vào SSM Parameter Store trước, rồi:
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c ssm:/tên-parameter
```

### Bước 3: Start the Agent

```bash
sudo systemctl enable amazon-cloudwatch-agent
sudo systemctl start amazon-cloudwatch-agent
```

### Bước 4: Verify & Check Status

```bash
# Cách 1: Dùng agent control tool (từ slide)
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -m ec2 \
  -a status

# Kết quả mong đợi:
# {
#   "status": "running",
#   "starttime": "2026-06-12T...",
#   "version": "1.x.x"
# }

# Cách 2: Systemctl
sudo systemctl status amazon-cloudwatch-agent

# Cách 3: Xem log
tail -f /opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log
```

---

## 6. SSM Parameter Store vs Local Config File

| Phương pháp | Ưu điểm | Nhược điểm |
|-------------|---------|-----------|
| **SSM Parameter** (Best practice) | Cập nhật config mà không cần SSH, centralized, audit trail | Cần thêm `ssm:GetParameter` permission |
| **Local JSON file** | Đơn giản, không cần SSM | Phải SSH vào EC2 để thay đổi |
| **Wizard interactive** | Thân thiện, hướng dẫn từng bước | Không dùng được trong automation/IaC |

---

## 7. Custom Namespace vs Built-in Namespace

```
CloudWatch Metrics
├── AWS/EC2                    ← Built-in (hypervisor metrics)
│   ├── CPUUtilization
│   ├── NetworkIn / NetworkOut
│   └── DiskReadOps / DiskWriteOps
│
└── W9Lab/CustomMetrics        ← Custom (Agent metrics từ OS)
    ├── mem_used_percent       ← Không có trong AWS/EC2!
    ├── disk_used_percent      ← Không có trong AWS/EC2!
    ├── cpu_usage_user         ← Chi tiết hơn CPUUtilization
    ├── cpu_usage_system
    └── bytes_sent / bytes_recv
```

> **Lưu ý:** Custom metrics tính phí `$0.30/metric/tháng` (sau 10 metrics đầu Free Tier).  
> Built-in EC2 metrics với Basic Monitoring: **miễn phí**.

---

## 8. Vị trí các file quan trọng của Agent

| File | Mô tả |
|------|-------|
| `/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl` | Tool điều khiển agent (start/stop/status/fetch-config) |
| `/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json` | Config file đang được áp dụng |
| `/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log` | Log file của agent |
| `/opt/aws/amazon-cloudwatch-agent/etc/common-config.toml` | Cấu hình chung (proxy, credentials) |

---

## 9. So sánh Monitoring Scenarios

| Scenario | Built-in Metrics | CloudWatch Agent |
|----------|:---------------:|:----------------:|
| CPU > 80% alarm | ✅ | ✅ (chi tiết hơn) |
| Memory > 80% alarm | ❌ | ✅ |
| Disk Full alert | ❌ | ✅ |
| Application log monitoring | ❌ | ✅ |
| Custom app metrics (StatsD) | ❌ | ✅ |
| Giá | Miễn phí | Tính phí per metric |

---

## 10. Câu hỏi thường gặp

**Q: Tại sao metrics không xuất hiện trong CloudWatch sau khi apply?**  
A: Đợi 3–5 phút để user_data script hoàn tất, agent start và gửi dữ liệu lần đầu.

**Q: Tại sao dùng SSM Parameter Store thay vì bỏ config vào S3?**  
A: SSM rẻ hơn (1 parameter miễn phí/tháng), tích hợp sẵn với `fetch-config`, và có IAM access control chi tiết hơn.

**Q: Khác biệt giữa `mem_used_percent` của Agent và `MemoryUtilization` trong AWS/EC2?**  
A: `MemoryUtilization` **không tồn tại** trong namespace `AWS/EC2`. Bạn phải cài Agent mới có `mem_used_percent`.
