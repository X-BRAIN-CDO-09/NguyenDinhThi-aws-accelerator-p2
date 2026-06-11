# ============================================================
# Dockerfile — Flask API
# Từ slide buổi chiều Lab 2
# Build: docker build -t w9-api:1 app/
# Load:  minikube image load w9-api:1 -p w9
# ============================================================
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir \
    flask==3.0.3 \
    prometheus-flask-exporter==0.23.1

COPY app.py /app/app.py

ENV FLASK_APP=app.py
ENV FLASK_ENV=production

EXPOSE 8080

CMD ["flask", "run", "--host=0.0.0.0", "--port=8080"]
