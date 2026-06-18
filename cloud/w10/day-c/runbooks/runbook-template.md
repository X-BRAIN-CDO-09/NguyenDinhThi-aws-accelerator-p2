# Runbook: [SERVICE_NAME] — [ALERT_NAME]

> **Severity:** [P1 / P2 / P3]
> **Owner:** [team-name]
> **Last reviewed:** [YYYY-MM-DD]
> **Escalation contact:** [name / Slack handle]

---

## Overview

**Alert fires when:** [describe the trigger condition, e.g., "error rate > 5% for 5 minutes"]

**Likely impact:** [describe user-facing impact, e.g., "checkout fails for ~5% of users"]

**Time to resolve (typical):** [e.g., 15–30 minutes]

---

## Symptoms

- [ ] Alert: `[ALERT_NAME]` fires in Prometheus/Grafana
- [ ] Users report: [describe symptom]
- [ ] Logs show: `[example log line or error pattern]`

---

## Diagnosis

### 1. Check pod status
```bash
kubectl get pods -n app -l app=[SERVICE_NAME]
kubectl describe pod -n app -l app=[SERVICE_NAME]
```

### 2. Check recent logs
```bash
kubectl logs -n app -l app=[SERVICE_NAME] --tail=100 --since=10m
```

### 3. Check resource usage
```bash
kubectl top pods -n app
kubectl top nodes
```

### 4. Check upstream dependencies
```bash
# DB connectivity
kubectl exec -n app deploy/[SERVICE_NAME] -- nc -zv db-host 5432

# External service
curl -sf https://[dependency-endpoint]/health
```

### 5. Check recent deployments
```bash
kubectl rollout history deployment/[SERVICE_NAME] -n app
git log --oneline -10
```

---

## Remediation

### Option A: Rollback deployment (< 5 minutes)
```bash
# Via GitOps (preferred)
git revert HEAD && git push

# Direct rollback (emergency only)
kubectl rollout undo deployment/[SERVICE_NAME] -n app
```

### Option B: Scale up (if load spike)
```bash
kubectl scale deployment/[SERVICE_NAME] --replicas=5 -n app
# Remember to update HPA/manifest in Git after stabilizing
```

### Option C: Restart pods (if deadlock/memory leak suspected)
```bash
kubectl rollout restart deployment/[SERVICE_NAME] -n app
```

---

## Escalation

| Condition | Action |
|---|---|
| Not resolved in 30 min | Page [name] on [Slack/phone] |
| Data loss suspected | Stop service, preserve state, call [name] |
| Security incident suspected | Follow [IR Playbook](./ir-playbook-6step.md) |

---

## Post-mortem

After incident resolved: file post-mortem in [link to template].

Key questions:
1. What was the root cause?
2. How long was user impact?
3. What detection gap let this go unnoticed until alert?
4. What action item prevents recurrence?
