# Dosya: image-masker.py
# Açıklama: Flask API sunucusu - Gunicorn için optimize edilmiş model yükleme ve stabil Telegram bildirimleri

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
import requests # Telegram için 'requests' kullanacağız
from PIL import Image
import io
import signal
import sys

# --- TEMEL AYARLAR ---

app = Flask(__name__)
CORS(app)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- GLOBAL DEĞİŞKENLER ---

yolo_model = None
TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN', '')
TELEGRAM_CHAT_ID = os.environ.get('TELEGRAM_CHAT_ID', '')
request_count = 0
start_time = datetime.now()

# --- MODEL YÜKLEME FONKSİYONU ---

def load_models():
    """Sadece YOLO modelini yükle (RAM sınırı nedeniyle)"""
    global yolo_model
    try:
        logger.info("YOLO modeli yükleniyor (RAM limiti: 512MB)...")
        # Önbellek için yazılabilir bir dizin kullan
        cache_dir = '/tmp/ultralytics_cache'
        os.makedirs(cache_dir, exist_ok=True)
        os.environ['YOLO_CONFIG_DIR'] = cache_dir
        
        yolo_model = YOLO('yolov8n-seg.pt') # Segmentasyon modelini kullan
        # Başarılı bir çıkarım yaparak modelin gerçekten çalıştığını doğrula
        _ = yolo_model(np.zeros((64, 64, 3), dtype=np.uint8))
        logger.info("YOLO segmentasyon modeli başarıyla yüklendi ve test edildi!")
        return True
    except Exception as e:
        logger.error(f"YOLO modeli yüklenirken hata oluştu: {e}")
        yolo_model = None
        return False

# --- TELEGRAM BİLDİRİM FONKSİYONLARI (STABİL VERSİYON) ---

def send_telegram_message(message):
    """Telegram'a senkron ve stabil bir şekilde mesaj gönderir."""
    if TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID:
        url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
        payload = {'chat_id': TELEGRAM_CHAT_ID, 'text': message}
        try:
            # Sunucuyu kilitlememek için 5 saniyelik bir timeout ayarla
            response = requests.post(url, json=payload, timeout=5)
            response.raise_for_status()  # HTTP hataları için exception fırlat
            logger.info("Telegram bildirimi başarıyla gönderildi.")
            return True
        except requests.exceptions.RequestException as e:
            logger.error(f"Telegram bildirimi gönderilemedi: {e}")
            return False
    return False

def notify_server_start(models_loaded_successfully):
    """Sunucu başlangıç bildirimi"""
    hostname = os.environ.get('RENDER_EXTERNAL_URL', 'Bilinmiyor')
    status_icon = "✅" if models_loaded_successfully else "⚠️"
    status_text = "AI Modeli Aktif" if models_loaded_successfully else "Sadece Fallback Modu"
    
    message = (
        f"🚀 AI Garage Masking API Başlatıldı!\n"
        f"⏰ {start_time.strftime('%Y-%m-%d %H:%M:%S')}\n"
        f"🌐 {hostname}\n"
        f"💡 Durum: {status_icon} {status_text}"
    )
    send_telegram_message(message)

def notify_user_activity(device_id, success=True, algorithm='Unknown'):
    """Kullanıcı aktivitesi bildirimi"""
    global request_count
    request_count += 1
    status = "✅ Başarılı" if success else "❌ Başarısız"
    uptime = datetime.now() - start_time
    uptime_str = str(uptime).split('.')[0]
    message = (
        f"👤 Kullanıcı Aktivitesi ({device_id})\n"
        f"{status} - Algoritma: {algorithm}\n"
        f"📊 Toplam İstek: {request_count}\n"
        f"⏱️ Çalışma Süresi: {uptime_str}"
    )
    send_telegram_message(message)

# --- GUNICORN İÇİN MODEL YÜKLEME ---
# Bu kod bloğu, 'if __name__ == "__main__"' dışında olmalı ki Gunicorn uygulamayı
# import ettiğinde çalışsın.
models_loaded = load_models()
notify_server_start(models_loaded)

# --- SİNYAL YÖNETİMİ ---
def signal_handler(signum, frame):
    """Sunucu kapanırken bildirim gönder"""
    message = f"🛑 AI Garage Masking API Kapatılıyor!\n⏰ {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
    send_telegram_message(message)
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_handler)
signal.signal(signal.SIGINT, signal_handler)

# --- MASKELEME ALGORİTMALARI ---

def create_mask_with_yolo_opencv(image_bytes):
    """YOLOv8-seg ile segmentasyon tabanlı maskeleme"""
    try:
        if yolo_model is None:
            logger.error("YOLO modeli yüklü değil! Fallback metoduna geçiliyor.")
            return create_fallback_mask(image_bytes), 'Fallback_OpenCV'

        image = Image.open(io.BytesIO(image_bytes))
        image_np = np.array(image)
        
        results = yolo_model(image_np, classes=[2, 3, 5, 7], verbose=False) # car, motorcycle, bus, truck
        
        if not results or results[0].masks is None or len(results[0].masks) == 0:
            logger.warning("YOLO araç segmenti bulamadı, fallback metoduna geçiliyor.")
            return create_fallback_mask(image_bytes), 'Fallback_OpenCV'

        # En büyük alanı kaplayan aracın maskesini al
        largest_mask_np = None
        max_area = 0
        for mask_tensor in results[0].masks.data:
            mask_np = mask_tensor.cpu().numpy().astype(np.uint8)
            area = np.sum(mask_np)
            if area > max_area:
                max_area = area
                largest_mask_np = mask_np * 255 # Maskeyi 0-255 aralığına getir
        
        if largest_mask_np is not None:
            mask_3channel = cv2.cvtColor(largest_mask_np, cv2.COLOR_GRAY2BGR)
            logger.info("YOLO segmentasyon maskesi başarıyla oluşturuldu.")
            return mask_3channel, 'YOLOv8_Segmentation'
        else:
            logger.warning("Geçerli bir segmentasyon maskesi bulunamadı, fallback'e geçiliyor.")
            return create_fallback_mask(image_bytes), 'Fallback_OpenCV'
            
    except Exception as e:
        logger.error(f"YOLO ile maskeleme hatası: {e}")
        return create_fallback_mask(image_bytes), 'Fallback_OpenCV_Error'

def create_fallback_mask(image_bytes):
    """OpenCV ile basit yedek maskeleme algoritması"""
    try:
        nparr = np.frombuffer(image_bytes, np.uint8)
        image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if image is None: raise Exception("Görüntü çözülemedi")
        
        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        blurred = cv2.GaussianBlur(gray, (5, 5), 0)
        edges = cv2.Canny(blurred, 50, 150)
        
        kernel = np.ones((5, 5), np.uint8)
        dilated = cv2.dilate(edges, kernel, iterations=2)
        
        contours, _ = cv2.findContours(dilated, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
        if contours:
            largest_contour = max(contours, key=cv2.contourArea)
            mask = np.zeros_like(gray)
            cv2.drawContours(mask, [largest_contour], 0, 255, -1)
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            return mask_3channel
        else:
            height, width, _ = image.shape
            mask = np.zeros((height, width), dtype=np.uint8)
            cv2.rectangle(mask, (int(width*0.1), int(height*0.1)), (int(width*0.9), int(height*0.9)), 255, -1)
            mask_3channel = cv2.cvtColor(mask, cv2.COLOR_GRAY2BGR)
            return mask_3channel
    except Exception as e:
        logger.error(f"Fallback OpenCV maskeleme hatası: {e}")
        height, width = (256, 256) # Varsayılan boyut
        try:
            nparr = np.frombuffer(image_bytes, np.uint8)
            img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
            if img is not None:
                height, width, _ = img.shape
        except:
            pass
        return np.zeros((height, width, 3), dtype=np.uint8)

# --- API ENDPOINTS ---

@app.route('/mask', methods=['POST'])
def mask_image():
    try:
        data = request.get_json()
        device_id = data.get('device_id', 'unknown')
        base64_image = data.get('image')

        if not base64_image:
            return jsonify({'success': False, 'error': 'Resim verisi bulunamadı'}), 400

        image_bytes = base64.b64decode(base64_image)
        
        if models_loaded and yolo_model:
            mask_image, algorithm = create_mask_with_yolo_opencv(image_bytes)
        else:
            mask_image, algorithm = create_fallback_mask(image_bytes), 'Fallback_OpenCV_Only'

        _, encoded_mask = cv2.imencode('.png', mask_image)
        mask_base64 = base64.b64encode(encoded_mask.tobytes()).decode('utf-8')
        
        notify_user_activity(device_id, success=True, algorithm=algorithm)
        
        return jsonify({
            'success': True,
            'mask': mask_base64,
            'algorithm': algorithm
        })

    except Exception as e:
        logger.error(f"Genel maskeleme hatası: {e}")
        notify_user_activity(data.get('device_id', 'unknown'), success=False, algorithm='Error')
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'models_loaded': models_loaded,
        'yolo_ready': yolo_model is not None
    })

@app.route('/', methods=['GET'])
def home():
    return jsonify({'message': 'AI Garage - Image Masking API (v1.2 Stable)'})

# --- YEREL ÇALIŞTIRMA İÇİN ---
if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
