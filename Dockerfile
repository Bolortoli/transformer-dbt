FROM python:3.12-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Install dbt and Flask
RUN pip install dbt-core dbt-bigquery flask gunicorn

# Copy dbt project files
COPY . .

# Make scripts executable
RUN chmod +x deploy.sh

# Set environment variables
ENV DBT_PROFILES_DIR=/app
ENV PYTHONPATH=/app
ENV PORT=8080

# Expose port
EXPOSE 8080

# Run web service with Python directly
CMD ["python", "web_service.py"]
