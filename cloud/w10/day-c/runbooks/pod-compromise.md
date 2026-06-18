# Runbook: Pod Compromised — 5-Minute Response

> **Scenario:** GuardDuty hoặc alert báo một pod đang chạy crypto-mining / reverse shell / kết nối ra ngoài bất thường.
> **SLA:** Contain trong 5 phút.

---

## Quyết định nhanh trong 60 giây đầu

```
Pod bị compromise?
      │
      ├─ Active exfil / C2 traffic?  → NGAY LẬP TỨC: Delete pod + cordon node
      │
      ├─ Chỉ 1 pod nghi ngờ?         → Delete pod (K8s tự reschedule ở node sạch)
      │
      ├─ Cả namespace nghi ngờ?      → NetworkPolicy deny-all + escalate
      │
      └─ Không chắc?                 → Cordon node + preserve evidence + investigate
```

---

## Bước 1 — Identify (30 giây)

```bash
# Tìm pod nghi ngờ (lookup từ GuardDuty finding hoặc alert)
POD="<pod-name>"
NS="<namespace>"

# Xem pod đang dùng image gì, từ đâu
kubectl get pod "${POD}" -n "${NS}" -o json | jq '{
  node: .spec.nodeName,
  image: [.spec.containers[].image],
  startTime: .status.startTime,
  serviceAccount: .spec.serviceAccountName
}'

# Check network connections từ pod
kubectl exec -n "${NS}" "${POD}" -- ss -tnp 2>/dev/null || \
kubectl exec -n "${NS}" "${POD}" -- netstat -tnp 2>/dev/null
```

---

## Bước 2 — Preserve Evidence (1 phút)

```bash
# Lấy logs trước khi xóa pod
kubectl logs -n "${NS}" "${POD}" --all-containers > "/tmp/ir-${POD}-$(date +%Y%m%d-%H%M%S).log"

# Describe pod (events, env vars, mounts)
kubectl describe pod -n "${NS}" "${POD}" >> "/tmp/ir-${POD}-$(date +%Y%m%d-%H%M%S).log"

# Ghi lại node
NODE=$(kubectl get pod "${POD}" -n "${NS}" -o jsonpath='{.spec.nodeName}')
echo "Compromised node: ${NODE}"
```

---

## Bước 3 — Contain (2 phút)

```bash
# Cordon node — không schedule pod mới lên đây
kubectl cordon "${NODE}"

# Option A: Xóa pod (K8s reschedule lên node sạch, Deployment tự heal)
kubectl delete pod "${POD}" -n "${NS}"

# Option B: Nếu cần giữ pod để forensics (KHÔNG DÙNG nếu đang exfil data)
# kubectl cordon "${NODE}" && kubectl taint nodes "${NODE}" incident=true:NoExecute

# Isolate namespace nếu toàn namespace bị ảnh hưởng
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: emergency-isolate
  namespace: ${NS}
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
EOF
```

---

## Bước 4 — Rotate Credentials (2 phút)

```bash
# Xác định ServiceAccount của pod bị compromise
SA=$(kubectl get pod "${POD}" -n "${NS}" -o jsonpath='{.spec.serviceAccountName}')

# Tìm IAM Role bound qua IRSA
kubectl get sa "${SA}" -n "${NS}" -o jsonpath='{.metadata.annotations.eks\.amazonaws\.com/role-arn}'

# Rotate tất cả secrets trong namespace
kubectl get externalsecret -n "${NS}" -o name | \
  xargs -I{} kubectl annotate {} -n "${NS}" force-sync=$(date +%s)

# Nếu pod có AWS credentials (không dùng IRSA): revoke access key ngay
aws iam update-access-key --access-key-id <KEY_ID> --status Inactive --user-name <USERNAME>
```

---

## Bước 5 — Verify & Escalate

```bash
# Xác nhận pod mới lên từ image sạch (không phải image đã bị tamper)
kubectl get pods -n "${NS}" -o wide
kubectl get pod -n "${NS}" -l app=<service> -o jsonpath='{.items[*].spec.containers[*].image}'

# Kiểm tra GuardDuty findings còn active không
aws guardduty list-findings --detector-id $(aws guardduty list-detectors --output text) \
  --finding-criteria '{"Criterion":{"updatedAt":{"Gte":'$(date -d '10 minutes ago' +%s000)'}}}' \
  | jq '.FindingIds | length'
```

**Escalate nếu:**
- Nhiều hơn 1 pod bị ảnh hưởng
- Data exfiltration confirmed
- Attacker vẫn còn access sau khi xóa pod
- Không tìm được root cause trong 15 phút

→ Chuyển sang [IR Playbook 6-step](./ir-playbook-6step.md) Step 4 (Eradicate).

---

## Checklist sau 5 phút

- [ ] Pod đã bị xóa / isolated
- [ ] Node đã cordon
- [ ] Logs đã preserve
- [ ] Credentials đã rotate
- [ ] GuardDuty không còn active finding mới
- [ ] Team lead / mentor đã được thông báo
- [ ] Ticket đã tạo (ghi timestamp + action taken)
