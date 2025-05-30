import io
import numpy as np
from fastapi import FastAPI, UploadFile, File, HTTPException
from PIL import Image
import onnxruntime as ort
import mediapipe as mp

app = FastAPI()

# Load ONNX model sekali saja
session = ort.InferenceSession("r100.onnx")
input_name = session.get_inputs()[0].name

# Setup Mediapipe Face Detection
mp_face_detection = mp.solutions.face_detection
face_detector = mp_face_detection.FaceDetection(model_selection=1, min_detection_confidence=0.5)

def preprocess_image(image_bytes):
    # Buka image, detect wajah, crop wajah, resize 112x112, normalize
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB")
    img_np = np.array(img)

    # Deteksi wajah
    results = face_detector.process(img_np)
    if not results.detections:
        raise HTTPException(status_code=400, detail="No face detected in the image")

    # Ambil bounding box wajah pertama
    bbox = results.detections[0].location_data.relative_bounding_box
    ih, iw, _ = img_np.shape
    x_min = max(int(bbox.xmin * iw), 0)
    y_min = max(int(bbox.ymin * ih), 0)
    w = int(bbox.width * iw)
    h = int(bbox.height * ih)

    # Crop wajah
    face_img = img_np[y_min:y_min+h, x_min:x_min+w]
    face_pil = Image.fromarray(face_img).resize((112,112))

    # Preprocess pixel
    face_arr = np.array(face_pil).astype(np.float32)
    face_arr = (face_arr - 127.5) / 128.0
    face_arr = np.transpose(face_arr, (2,0,1))  # CHW
    face_arr = np.expand_dims(face_arr, axis=0)  # NCHW

    return face_arr

def cosine_similarity(vec1, vec2):
    vec1 = vec1 / np.linalg.norm(vec1)
    vec2 = vec2 / np.linalg.norm(vec2)
    return float(np.dot(vec1, vec2))

@app.post("/embedding")
async def get_embedding(file: UploadFile = File(...)):
    img_bytes = await file.read()
    input_tensor = preprocess_image(img_bytes)
    embedding = session.run(None, {input_name: input_tensor})[0][0]
    return {"embedding": embedding.tolist()}

@app.post("/compare")
async def compare(file1: UploadFile = File(...), file2: UploadFile = File(...)):
    img1 = await file1.read()
    img2 = await file2.read()

    emb1 = session.run(None, {input_name: preprocess_image(img1)})[0][0]
    emb2 = session.run(None, {input_name: preprocess_image(img2)})[0][0]

    similarity = cosine_similarity(emb1, emb2)
    threshold = 0.5

    return {"similarity": round(similarity,4), "match": similarity > threshold}
