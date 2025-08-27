# Dosya: image-masker.py
# Açıklama: Flask API sunucusu - YOLO + OpenCV ile optimize edilmiş maskeleme + Telegram Bot

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
import requests
from PIL import Image
import io
import telegram
import asyncio
import signal
import sys

# Açıklama: Flask uygulamasını başlat
app = Flask(__name__)
CORS(app)

# Açıklama: Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Açıklama: Global model değişkeni
yolo_model = None

# Açıklama: Telegram bot ayarları
TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN', '')
TELEGRAM_CHAT_ID = os.environ.get('TELEGRAM_CHAT_ID', '')
bot = None

# Açıklama: Telegram bot durumunu logla
logger.info(f"Telegram bot token: {'SET' if TELEGRAM_BOT_TOKEN else 'NOT SET'}")
logger.info(f"Telegram chat ID: {'SET' if TELEGRAM_CHAT_ID else 'NOT SET'}")

if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
    try:
        bot = telegram.Bot(token=TELEGRAM_BOT_TOKEN)
        logger.info("Telegram bot initialized successfully!")
    except Exception as e:
        logger.error(f"Telegram bot initialization error: {e}")
        bot = None
else:
    logger.warning("Telegram bot not configured - notifications disabled")

# Açıklama: İstatistik değişkenleri
request_count = 0
start_time = datetime.now()
heartbeat_count = 0

# Açıklama: Model yükleme fonksiyonu
def load_models():
    """Sadece YOLO modelini yükle (RAM sınırı nedeniyle)"""
    global yolo_model
    try:
        logger.info("Loading YOLO model only (RAM limit: 512MB)...")
        yolo_model = YOLO('yolov8n.pt')
        logger.info("YOLO model loaded successfully!")
        return True
    except Exception as e:
        logger.error(f"Error loading YOLO model: {e}")
        return False

# --- Telegram Bildirim Fonksiyonları ---
def send_telegram_message(message):
    """Telegram'a asenkron mesaj gönder"""
    if bot:
        try:
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(bot.send_message(chat_id=TELEGRAM_CHAT_ID, text=message))
            loop.close()
            return True
        except Exception as e:
            logger.error(f"Telegram message failed: {e}")
            return False
    return False

def notify_server_start():
    """Sunucu başlangıç bildirimi"""
    hostname = os.environ.get('RENDER_EXTERNAL_URL', 'Not available')
    message = f"🚀 AI Garage Masking API başlatıldı!\n⏰ {start_time.strftime('%Y-%m-%d %H:%M:%S')}\n🌐 {hostname}"
    send_telegram_message(message)

def notify_server_error(error_msg):
    """Sunucu hatası bildirimi"""
    message = f"❌ AI Garage Masking API Hatası!\n⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n🔍 Hata: {error_msg}"
    send_telegram_message(message)

def notify_user_activity(device_id, success=True):
    """Kullanıcı aktivitesi bildirimi"""
    global request_count
    request_count += 1
    status = "✅ Başarılı" if success else "❌ Başarısız"
    uptime = datetime.now() - start_time
    uptime_str = str(uptime).split('.')[0]
    message = f"👤 Kullanıcı Aktivitesi\n{status} - {device_id}\n📊 Toplam İstek: {request_count}\n⏱️ Uptime: {uptime_str}"
    send_telegram_message(message)

# Açıklama: Signal handler - sunucu kapanırken
def signal_handler(signum, frame):
    """Sunucu kapanırken bildirim gönder"""
    message = f"🛑 AI Garage Masking API kapatılıyor!\n⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n📊 Toplam İstek: {request_count}"
    send_telegram_message(message)
    sys.exit(0)

# Açıklama: Signal handler'ları kaydet
signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

# Açıklama: YOLO + OpenCV ile maskeleme fonksiyonu
def create_mask_with_yolo_opencv(image_bytes):
    """YOLO + OpenCV ile araç maskeleme (RAM optimizasyonlu)"""
    try:
        if yolo_model is None:
            logger.error("YOLO model is not loaded!")
            return create_fallback_mask(image_bytes)

        image = Image.open(io.BytesIO(image_bytes))
        image_np = np.array(image)
        logger.info(f"Processing image with size: {image_np.shape}")

        results = yolo_model(image_np, classes=[2, 3, 5, 7]) # car, motorcycle, bus, truck
        if not results or len(results[0].boxes) == 0:
            logger.warning("No vehicles detected, using fallback OpenCV method")
            return create_fallback_mask(image_bytes)

        largest_vehicle = None
        max_area = 0
        for result in results:
            for box in result.boxes:
                x1, y1, x2, y2 = box.xyxy[0].cpu().numpy()
                area = (x2 - x1) * (y2 - y1)
                if area > max_area:
                    max_area = area
                    largest_vehicle = (x1, y1, x2, y2)

        if largest_vehicle:
            x1, y1, x2, y2 = largest_vehicle
            height, width = image_np.shape[:2]
            mask = np.zeros((height, width), dtype=np.uint8)
            cv2.rectangle(mask, (int(x1), int(y1)), (int(x2), int(y2)), 255, -1)
            
            kernel = np.ones((5, 5), np.uint8)
            mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
            mask = cv2.morphologyEx(mask, cv2.MORPH_OPEN, kernel, iterations=1)
            
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            logger.info(f"YOLO+OpenCV mask created successfully with shape: {mask_3channel.shape}")
            return mask_3channel
        else:
            logger.warning("No valid vehicle detected, using fallback")
            return create_fallback_mask(image_bytes)
            
    except Exception as e:
        logger.error(f"YOLO+OpenCV masking error: {e}")
        logger.info("Falling back to OpenCV method")
        return create_fallback_mask(image_bytes)

# Açıklama: Fallback OpenCV maskeleme fonksiyonu
def create_fallback_mask(image_bytes):
    """OpenCV ile basit maskeleme algoritması (fallback)"""
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if image is None: raise Exception("Could not decode image")
        
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(blurred, 50, 150)
        
        kernel = np.ones((3, 3), np.uint8)
        dilated = cv2.dilate(edges, kernel, iterations=2)
        eroded = cv2.erode(dilated, kernel, iterations=1)
        
        contours, _ = cv2.findContours(eroded, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            mask = np.zeros_like(gray)
            cv2.drawContours(mask, [largest_contour], 0, 255, -1)
            mask = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel, iterations=2)
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            return mask_3channel
        else:
            height, width = gray.shape
            mask = np.zeros((height, width), dtype=np.uint8)
            cv2.rectangle(mask, (int(width*0.1), int(height*0.1)), (int(width*0.9), int(height*0.9)), 255, -1)
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            return mask_3channel
    except Exception as e:
        logger.error(f"Fallback OpenCV masking error: {e}")
        raise

# Açıklama: Maskeleme endpoint'i
@app.route('/mask', methods=['POST'])
def mask_image():
    try:
        data = request.get_json()
        if not data or 'image' not in data:
            return jsonify({'success': False, 'error': 'No image data provided'}), 400
        
        device_id = data.get('device_id', 'unknown_device')
        base64_image = data['image']
        logger.info(f"Processing mask request from device: {device_id}")

        if not base64_image or len(base64_image) < 100:
            return jsonify({'success': False, 'error': 'Invalid image data'}), 400

        try:
            image_bytes = base64.b64decode(base64_image)
            logger.info(f"Decoded image size: {len(image_bytes)} bytes")
        except Exception as e:
            logger.error(f"Base64 decode error: {e}")
            notify_server_error(f"Base64 decode error: {e}")
            return jsonify({'success': False, 'error': 'Invalid base64 data'}), 400

        try:
            # Optimize edilmiş fonksiyonu çağır
            mask_image = create_mask_with_yolo_opencv(image_bytes)
            
            success, encoded_mask = cv2.imencode('.png', mask_image)
            if not success:
                raise Exception("Could not encode mask image")
            
            mask_base64 = base64.b64encode(encoded_mask.tobytes()).decode('utf-8')
            logger.info(f"Mask encoding completed, base64 length: {len(mask_base64)}")
            
            response = {
                'success': True,
                'mask': mask_base64,
                'message': f'YOLO+OpenCV vehicle masking completed for {device_id}',
                'processing_time': datetime.now().isoformat(),
                'mask_shape': mask_image.shape,
                'algorithm': 'YOLO_OpenCV_Vehicle_Detection'
            }
            logger.info(f"Masking completed successfully for device: {device_id}")
            notify_user_activity(device_id, success=True)
            return jsonify(response)
        
        except Exception as e:
            logger.error(f"Processing error: {e}")
            notify_server_error(f"Processing error: {e}")
            return jsonify({'success': False, 'error': f'Processing error: {str(e)}'}), 500

    except Exception as e:
        logger.error(f"Masking error: {e}")
        notify_server_error(f"General masking error: {e}")
        return jsonify({'success': False, 'error': str(e)}), 500

# Açıklama: Diğer endpoint'ler
@app.route('/health', methods=['GET'])
def health_check():
    yolo_status = "loaded" if yolo_model is not None else "not_loaded"
    return jsonify({
        'status': 'healthy' if yolo_model else 'loading',
        'timestamp': datetime.now().isoformat(),
        'message': 'AI Garage Masking API is running',
        'yolo_ready': yolo_model is not None,
        'fallback_available': True
    })

@app.route('/', methods=['GET'])
def home():
    return jsonify({
        'message': 'AI Garage - Image Masking API (Optimized)',
        'version': '1.1.0',
        'status': 'running',
        'endpoints': {
            'health': '/health',
            'mask': '/mask',
        }
    })

# Açıklama: Uygulama başlatma
if __name__ == '__main__':
    app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
    app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024 # 50MB
    
    logger.info("Loading AI models...")
    if load_models():
        logger.info("Models loaded successfully!")
        notify_server_start()
    else:
        logger.warning("Failed to load models, will use fallback OpenCV method")
        notify_server_error("Failed to load AI models")
        
    port = int(os.environ.get('PORT', 5000))
    logger.info(f"Starting AI Garage Masking API on port {port}")
    app.run(host='0.0.0.0', port=port, debug=False)
