FROM python:3.11-slim

WORKDIR /app

# Copy files
COPY requirements.txt app.py ./

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# For testing - create dummy model file
RUN echo "dummy model file for testing" > r100.onnx

EXPOSE 8000

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]