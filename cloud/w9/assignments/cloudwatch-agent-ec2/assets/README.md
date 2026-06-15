# assets/ — Evidence Screenshots

Đặt ảnh chụp màn hình vào đây khi chạy lab thật.

## Danh sách ảnh cần chụp (SS-01 → SS-14)

| File | Nội dung | Bước liên quan |
|------|---------|---------------|
| `SS-01_ec2_running_with_iam_role.png` | EC2 đang running + IAM Role = `w9-cw-agent-lab-ec2-role` gắn đúng | Prerequisite |
| `SS-02_agent_status_running.png` | Terminal EC2: `./verify-agent.sh` → status = **running** | Bước 3 + 4 |
| `SS-03_cloudwatch_custom_namespace.png` | CloudWatch Console → Metrics → Custom Namespaces → `W9Lab/CustomMetrics` xuất hiện | Bước 4 |
| `SS-04_memory_metric_visible.png` | CloudWatch Metrics: `mem_used_percent` có giá trị thực | Bước 4 |
| `SS-05_disk_metric_visible.png` | CloudWatch Metrics: `disk_used_percent` (path=/) có giá trị | Bước 4 |
| `SS-06_dashboard_overview.png` | CloudWatch Dashboard — tổng quan 5 widget (Memory, Disk, CPU, Network, Compare) | Dashboard |
| `SS-07_dashboard_memory_widget.png` | Widget Memory Used % — đường biểu đồ bình thường | Dashboard |
| `SS-08_memory_load_running.png` | Terminal EC2: `./generate-memory-load.sh` đang chạy | Memory load test |
| `SS-09_dashboard_memory_spike.png` | Dashboard → mem_used_percent tăng vọt trong lúc load test | Memory load test |
| `SS-10_iam_role_policy_attached.png` | AWS Console IAM → Role `w9-cw-agent-lab-ec2-role` → Permissions = `CloudWatchAgentServerPolicy` | Prerequisite |
| `SS-11_ssm_parameter_config.png` | AWS SSM Parameter Store → `/w9-lab/cloudwatch-agent/config` — nội dung JSON | Bước 2 |
| `SS-12_agent_log_output.png` | Agent log file: `/opt/aws/amazon-cloudwatch-agent/logs/` — không có lỗi | Bước 4 |
