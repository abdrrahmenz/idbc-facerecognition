FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY app.py .

# Download model with multiple fallback options
RUN echo "Downloading model..." && \
    (wget --timeout=600 --tries=3 -L -O r100.onnx \
     "https://github.com/abdrrahmenz/idbc-facerecognition/releases/download/v1.0/r100.onnx" || \
     curl -L -o r100.onnx --max-time 600 --retry 3 \
     "https://github.com/abdrrahmenz/idbc-facerecognition/releases/download/v1.0/r100.onnx") && \
    echo "Download completed. File info:" && \
    ls -la r100.onnx && \
    echo "File size: $(du -h r100.onnx | cut -f1)"

# Verify model file is not empty
RUN test -s r100.onnx || (echo "Model file is empty!" && exit 1)

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]