FROM python:3.11-slim

WORKDIR /app

COPY leak.py .

# Set memory limit via docker run --memory flag
# This ensures OOM will eventually happen

RUN chmod +x leak.py

CMD ["python3", "-u", "leak.py"]
