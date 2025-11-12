FROM python:3.11-slim

WORKDIR /app

COPY exhaust.py .

RUN chmod +x exhaust.py

# Reduce FD limit to make the scenario trigger faster
# Set via docker run --ulimit nofile=256:256
CMD ["python3", "-u", "exhaust.py"]
