FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies dengan error handling
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgthread-2.0-0 \
    wget \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first (untuk Docker layer caching)
COPY requirements.txt .

# Install Python dependencies dengan timeout yang lebih panjang
RUN pip install --no-cache-dir --timeout 300 -r requirements.txt

# Copy application files
COPY app.py .

# Download model file dengan retry dan error handling
RUN echo "Downloading model file..." && \
    wget --timeout=300 --tries=3 -L -O r100.onnx "https://github.com/username/repo/releases/download/v1.0/r100.onnx" || \
    (echo "Failed to download model file" && exit 1)

# Verify file downloaded successfully
RUN ls -la r100.onnx && \
    echo "Model file size: $(du -h r100.onnx)"

# Create non-root user for security
RUN useradd -m -u 1000 appuser && chown -R appuser:appuser /app
USER appuser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Start the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]