"""
Flask API với prometheus_flask_exporter
Từ Lab 2 buổi chiều slide W9-chieu-obs-canary

Biến môi trường:
  ERROR_RATE : tỉ lệ lỗi giả (0.0 → 0.0%, 0.2 → 20%)
  VERSION    : version string để distinguish canary vs stable
"""
import os
import random
from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics

app = Flask(__name__)
# PrometheusMetrics tự thêm endpoint /metrics
# Tự track: flask_http_request_total, flask_http_request_duration_seconds
metrics = PrometheusMetrics(app)

ERROR_RATE = float(os.getenv("ERROR_RATE", "0"))
VERSION    = os.getenv("VERSION", "v1")


@app.get("/")
def index():
    """Main API endpoint — inject lỗi theo ERROR_RATE"""
    if random.random() < ERROR_RATE:
        return jsonify(
            error="injected_error",
            version=VERSION,
            error_rate=ERROR_RATE
        ), 500
    return jsonify(
        ok=True,
        version=VERSION,
        message=f"Backend API {VERSION} running"
    ), 200


@app.get("/healthz")
def healthz():
    """Readiness/Liveness probe — luôn trả 200"""
    return "ok", 200


@app.get("/api/status")
def status():
    """Status endpoint cho frontend dashboard"""
    return jsonify(
        status="healthy",
        version=VERSION,
        error_rate=ERROR_RATE
    ), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
