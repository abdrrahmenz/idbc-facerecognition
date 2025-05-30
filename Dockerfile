FROM ubuntu:22.04

WORKDIR /app

# Install Python dan dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    python3.11-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    libgtk-3-0 \
    libgdk-pixbuf2.0-0 \
    libxss1 \
    libgconf-2-4 \
    libxtst6 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libatk1.0-0 \
    libcairo-gobject2 \
    ffmpeg \
    libavcodec58 \
    libavformat58 \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set Python3 as default
RUN ln -s /usr/bin/python3 /usr/bin/python

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip3 install --no-cache-dir --upgrade pip
RUN pip3 install --no-cache-dir -r requirements.txt

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

# Environment variables
ENV DISPLAY=:99
ENV QT_X11_NO_MITSHM=1


EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]