FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgthread-2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files (exclude large model)
COPY app.py requirements.txt ./

# Download model file (ganti dengan URL model Anda)
RUN apt-get update && apt-get install -y wget
RUN wget -O r100.onnx "https://www.dropbox.com/scl/fi/y7di4yblqpkwjdz6b3bd3/r100.onnx?rlkey=94gtgav1r2sixv3i7u1lc3am8&e=1&st=bifmigmv&dl=1"

# Expose port
EXPOSE 8000

# Start the application
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]