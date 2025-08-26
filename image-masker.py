# Dosya: image-masker.py
# Açıklama: Flask API sunucusu - SAM + YOLO ile gelişmiş maskeleme

from flask import Flask, request, jsonify
from flask_cors import CORS
import base64
import os
import logging
from datetime import datetime
import cv2
import numpy as np
import torch
from ultralytics import YOLO
from segment_anything import sam_model_registry, SamPredictor
import requests
from PIL import Image
import io

# Açıklama: Flask uygulamasını başlat
app = Flask(__name__)
CORS(app)

# Açıklama: Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Açıklama: Global model değişkenleri
yolo_model = None
sam_predictor = None
sam_model = None

# Açıklama: Model yükleme fonksiyonu
def load_models():
    """SAM ve YOLO modellerini yükle"""
    global yolo_model, sam_predictor, sam_model
    
    try:
        logger.info("Loading YOLO model...")
        yolo_model = YOLO('yolov8n.pt')
        
        logger.info("Loading SAM model...")
        # SAM model dosyasını indir (eğer yoksa)
        sam_checkpoint = "sam_vit_h_4b8939.pth"
        if not os.path.exists(sam_checkpoint):
            logger.info("Downloading SAM model...")
            url = "https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth"
            response = requests.get(url)
            with open(sam_checkpoint, "wb") as f:
                f.write(response.content)
        
        sam_model = sam_model_registry["vit_h"](checkpoint=sam_checkpoint)
        sam_predictor = SamPredictor(sam_model)
        
        logger.info("Models loaded successfully!")
        return True
        
    except Exception as e:
        logger.error(f"Model loading error: {e}")
        return False

# Açıklama: SAM + YOLO ile gelişmiş maskeleme fonksiyonu
def create_mask_with_sam_yolo(image_bytes):
    """SAM + YOLO ile araç maskeleme"""
    try:
        # Açıklama: Bytes'i PIL Image'e çevir
        image = Image.open(io.BytesIO(image_bytes))
        image_np = np.array(image)
        
        logger.info(f"Processing image with size: {image_np.shape}")
        
        # Açıklama: YOLO ile araç tespiti
        results = yolo_model(image_np, classes=[2, 3, 5, 7])  # car, motorcycle, bus, truck
        
        if not results or len(results[0].boxes) == 0:
            logger.warning("No vehicles detected, using fallback OpenCV method")
            return create_fallback_mask(image_bytes)
        
        # Açıklama: SAM predictor'ı ayarla
        sam_predictor.set_image(image_np)
        
        # Açıklama: En büyük araç için maskeleme
        largest_vehicle = None
        max_area = 0
        
        for result in results:
            boxes = result.boxes
            for box in boxes:
                # Açıklama: Bounding box koordinatları
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                area = (x2 - x1) * (y2 - y1)
                
                if area > max_area:
                    max_area = area
                    largest_vehicle = (x1, y1, x2, y2)
        
        if largest_vehicle:
            x1, y1, x2, y2 = largest_vehicle
            
            # Açıklama: SAM için input point (araç merkezi)
            center_x = int((x1 + x2) / 2)
            center_y = int((y1 + y2) / 2)
            
            # Açıklama: SAM ile maskeleme
            input_point = np.array([[center_x, center_y]])
            input_label = np.array([1])  # 1 = foreground
            
            masks, scores, logits = sam_predictor.predict(
                point_coords=input_point,
                point_labels=input_label,
                multimask_output=True
            )
            
            # Açıklama: En yüksek skorlu maskeyi seç
            best_mask_idx = np.argmax(scores)
            mask = masks[best_mask_idx]
            
            # Açıklama: Maskeyi 3 kanala genişlet
            mask_3channel = np.stack([mask, mask, mask], axis=2).astype(np.uint8) * 255
            
            logger.info(f"SAM+YOLO mask created successfully with shape: {mask_3channel.shape}")
            return mask_3channel
        else:
            logger.warning("No valid vehicle detected, using fallback")
            return create_fallback_mask(image_bytes)
            
    except Exception as e:
        logger.error(f"SAM+YOLO masking error: {e}")
        logger.info("Falling back to OpenCV method")
        return create_fallback_mask(image_bytes)

# Açıklama: Fallback OpenCV maskeleme fonksiyonu
def create_fallback_mask(image_bytes):
    """OpenCV ile basit maskeleme algoritması (fallback)"""
    try:
        # Açıklama: Bytes'i numpy array'e çevir
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if image is None:
            raise Exception("Could not decode image")

        # Açıklama: Gri tonlamaya çevir
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

        # Açıklama: Gürültü azaltma
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)

        # Açıklama: Canny kenar tespiti
        edges = cv2.Canny(blurred, 50, 150)

        # Açıklama: Morphological operations ile maskeyi iyileştir
        kernel = np.ones((3, 3), np.uint8)
        dilated = cv2.dilate(edges, kernel, iterations=2)
        eroded = cv2.erode(dilated, kernel, iterations=1)

        # Açıklama: Contour bulma ve en büyük alanı maskeleme
        contours, _ = cv2.findContours(eroded, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

        if contours:
            # Açıklama: En büyük contour'u bul
            largest_contour = max(contours, key=cv2.contourArea)

            # Açıklama: Boş maske oluştur
            mask = np.zeros_like(gray)

            # Açıklama: Contour'u doldur
            cv2.drawContours(mask, [largest_contour], 0, 255, -1)

            # Açıklama: Morphological closing ile maskeyi iyileştir
            mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)

            # Açıklama: Maskeyi 3 kanala genişlet
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)

            return mask_3channel
        else:
            # Açıklama: Contour bulunamazsa basit bir dikdörtgen maskesi oluştur
            height, width = gray.shape
            mask = np.zeros((height, width), dtype=np.uint8)
            cv2.rectangle(mask, (int(width*0.1), int(height*0.1)), (int(width*0.9), int(height*0.9)), 255, -1)
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            return mask_3channel

    except Exception as e:
        logger.error(f"Fallback OpenCV masking error: {e}")
        raise

# Açıklama: Sağlık kontrolü endpoint'i
@app.route('/health', methods=['GET'])
def health_check():
    try:
        return jsonify({
            'status': 'healthy',
            'timestamp': datetime.now().isoformat(),
            'message': 'AI Garage Masking API is running'
        })
    except Exception as e:
        logger.error(f"Health check error: {e}")
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

# Açıklama: Maskeleme endpoint'i
@app.route('/mask', methods=['POST'])
def mask_image():
    try:
        # Açıklama: JSON verisini al
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({'success': False, 'error': 'No image data provided'}), 400

        device_id = data.get('device_id', 'unknown_device')
        base64_image = data['image']

        logger.info(f"Processing mask request from device: {device_id}")

        # Açıklama: Base64 verisini kontrol et
        if not base64_image or len(base64_image) < 100:
            return jsonify({'success': False, 'error': 'Invalid image data'}), 400

        # Açıklama: Base64'ü decode et
        try:
            image_bytes = base64.b64decode(base64_image)
            logger.info(f"Decoded image size: {len(image_bytes)} bytes")
        except Exception as e:
            logger.error(f"Base64 decode error: {e}")
            return jsonify({'success': False, 'error': 'Invalid base64 data'}), 400

        # Açıklama: SAM + YOLO ile maskeleme yap
        try:
            mask_image = create_mask_with_sam_yolo(image_bytes)

            # Açıklama: Maskeyi base64'e çevir
            success, encoded_mask = cv2.imencode('.png', mask_image)
            if not success:
                raise Exception("Could not encode mask image")

            mask_base64 = base64.b64encode(encoded_mask.tobytes()).decode('utf-8')

            logger.info(f"Mask encoding completed, base64 length: {len(mask_base64)}")

            # Açıklama: Başarılı yanıt
            response = {
                'success': True,
                'mask': mask_base64,
                'message': f'SAM+YOLO vehicle masking completed for {device_id}',
                'processing_time': datetime.now().isoformat(),
                'mask_shape': mask_image.shape,
                'algorithm': 'SAM_YOLO_Vehicle_Detection'
            }

            logger.info(f"Masking completed successfully for device: {device_id}")
            return jsonify(response)

        except Exception as e:
            logger.error(f"SAM+YOLO processing error: {e}")
            return jsonify({'success': False, 'error': f'Processing error: {str(e)}'}), 500

    except Exception as e:
        logger.error(f"Masking error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# Açıklama: Durum endpoint'i
@app.route('/status', methods=['GET'])
def get_status():
    try:
        return jsonify({
            'status': 'running',
            'timestamp': datetime.now().isoformat(),
            'version': '1.0.0',
            'message': 'AI Garage Masking API is operational'
        })
    except Exception as e:
        logger.error(f"Status check error: {e}")
        return jsonify({'status': 'error', 'error': str(e)}), 500

# Açıklama: Ana endpoint
@app.route('/', methods=['GET'])
def home():
    return jsonify({
        'message': 'AI Garage - Image Masking API',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
            'health': '/health',
            'mask': '/mask',
            'status': '/status'
        },
        'note': 'SAM+YOLO-based vehicle masking with fallback to OpenCV'
    })

# Açıklama: Uygulama başlatma
if __name__ == '__main__':
    # Açıklama: Flask ayarları
    app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
    app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB

    # Açıklama: Modelleri yükle
    logger.info("Loading AI models...")
    if load_models():
        logger.info("Models loaded successfully!")
    else:
        logger.warning("Failed to load models, will use fallback OpenCV method")

    # Açıklama: Port ayarı
    port = int(os.environ.get('PORT', 5000))

    # Açıklama: Uygulamayı başlat
    logger.info(f"Starting AI Garage Masking API on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
