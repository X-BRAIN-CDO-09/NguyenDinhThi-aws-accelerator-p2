# IR Playbook: Security Incident Response (6-Step)

> Dùng khi phát hiện: unauthorized access, data breach, crypto-mining, suspicious network traffic, GuardDuty finding HIGH/CRITICAL.
> **Mục tiêu:** Contain trong 15 phút. Eradicate trong 1 giờ. Recover trong 4 giờ. Post-mortem trong 48 giờ.

---

## Step 1 — DETECT (T+0)

**Trigger sources:**
- GuardDuty finding (Severity ≥ HIGH)
- CloudTrail anomaly alert
- Prometheus alert (`SecurityEventDetected`, `UnauthorizedAPICall`)
- Manual report from team member / user

**Actions:**
```bash
# Check GuardDuty findings
aws guardduty list-findings --detector-id $(aws guardduty list-detectors --query 'DetectorIds[0]' --output text) \
  --finding-criteria '{"Criterion":{"severity":{"Gte":7}}}'

# Check CloudTrail for recent suspicious calls
aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=ConsoleLogin \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%SZ)

# Check K8s audit log (if EKS)
kubectl get events --all-namespaces --sort-by='.lastTimestamp' | tail -30
```

**Record:** time of detection, source, affected resource, initial severity estimate.

---

## Step 2 — TRIAGE (T+5 min)

**Severity matrix:**

| Severity | Indicator | Response |
|---|---|---|
| P1 — Critical | Active data exfiltration / root compromise / prod data at risk | Contain immediately, wake everyone |
| P2 — High | Unauthorized access confirmed, no active exfil | Contain within 15 min, notify lead |
| P3 — Medium | Suspicious activity, unconfirmed | Investigate, monitor, log for 1h |
| P4 — Low | Anomaly, likely false positive | Track ticket, review in business hours |

**Questions to answer in triage:**
- What resource is affected? (EC2, pod, S3 bucket, IAM role?)
- Is the attacker still active?
- Is data being exfiltrated right now?
- What blast radius? (one pod / one namespace / entire account)

---

## Step 3 — CONTAIN (T+10–15 min)

**K8s: isolate compromised pod**
```bash
# Cordon the node (no new pods scheduled here)
kubectl cordon <node-name>

# Delete the pod (K8s will reschedule on clean node)
kubectl delete pod <pod-name> -n <namespace>

# If namespace-wide: apply restrictive NetworkPolicy (deny all ingress/egress)
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: isolate-all
  namespace: <namespace>
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
EOF
```

**AWS EC2: isolate compromised instance**
```bash
# Swap security group to isolation SG (no inbound, no outbound except SSM)
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --groups <isolation-sg-id>

# Take EBS snapshot before any changes (preserve evidence)
aws ec2 create-snapshot \
  --volume-id <volume-id> \
  --description "IR evidence snapshot $(date +%Y%m%d-%H%M%S)"
```

**AWS IAM: disable compromised credentials**
```bash
# Disable access key immediately
aws iam update-access-key --access-key-id <key-id> --status Inactive --user-name <user>

# Detach all policies from compromised role
aws iam list-attached-role-policies --role-name <role> \
  | jq -r '.AttachedPolicies[].PolicyArn' \
  | xargs -I{} aws iam detach-role-policy --role-name <role> --policy-arn {}
```

---

## Step 4 — ERADICATE (T+30–60 min)

1. Identify root cause: how did attacker get in? (leaked creds, CVE, misconfigured RBAC?)
2. Remove malicious artifacts:
   - Delete compromised pods/deployments
   - Remove unauthorized IAM users/keys/roles
   - Revoke all active sessions for affected users
3. Rotate all secrets that may have been exposed:
   ```bash
   # Rotate Secrets Manager secret
   aws secretsmanager rotate-secret --secret-id <secret-id>
   # Update ESO to force re-sync
   kubectl annotate externalsecret <name> -n <ns> force-sync=$(date +%s)
   ```
4. Patch the vulnerability or misconfiguration that was exploited.
5. Verify attacker no longer has access (re-check GuardDuty, CloudTrail).

---

## Step 5 — RECOVER (T+1–4 hours)

1. Redeploy from clean Git state:
   ```bash
   git log --oneline -10   # Identify last known-good commit
   # Force ArgoCD to sync from that commit
   argocd app sync <app-name> --revision <commit-sha>
   ```
2. Verify application health:
   ```bash
   kubectl get pods -n app
   kubectl rollout status deployment/<name> -n app
   curl -sf http://<service>/health
   ```
3. Restore from backup if data was corrupted (not deleted — verify integrity first).
4. Gradually restore network policies (remove isolation, re-enable traffic).
5. Monitor closely for 2 hours — watch GuardDuty + Prometheus alerts.

---

## Step 6 — POST-MORTEM (T+48 hours)

**Blameless format** — tìm nguyên nhân hệ thống, không tìm người có lỗi.

Template:
```
Tiêu đề: [Service] Incident — [Date] — [Brief description]
Thời gian: Detection [T+0] → Contain [T+X] → Resolve [T+Y] → Post-mortem [T+48h]
Tóm tắt: [2–3 câu: gì xảy ra, impact, resolved how]

Timeline chi tiết:
  HH:MM — [event]

Root cause: [kỹ thuật, không dùng "human error"]

Contributing factors:
  - [factor 1]
  - [factor 2]

Action items:
  | Action | Owner | Due |
  | Fix CVE in base image | @engineer | 2026-07-01 |
  | Add GuardDuty alert for this pattern | @sre | 2026-06-30 |
  | Update runbook step 3 | @sre | 2026-06-25 |
```

---

## Quick Reference Commands

```bash
# Cluster-wide: who has ClusterAdmin?
kubectl get clusterrolebindings -o json | jq '.items[] | select(.roleRef.name=="cluster-admin") | .subjects'

# What images are running right now?
kubectl get pods --all-namespaces -o jsonpath='{range .items[*]}{.spec.containers[*].image}{"\n"}{end}' | sort -u

# Check pod security context
kubectl get pods -n app -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[*].securityContext}{"\n"}{end}'
```
