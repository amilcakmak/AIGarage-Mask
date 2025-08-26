# Dosya: auto-install-software-main/image-masker.py
# Açıklama: DeepLabV3+ ile resim maskeleme Flask API sunucusu - Optimize edilmiş versiyon

import flask
import os
import cv2
import numpy as np
import tensorflow as tf
from flask import request, jsonify
from flask_cors import CORS
import base64
from datetime import datetime
import logging
import time
import threading

# Logging ayarları
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = flask.Flask(__name__)
CORS(app)  # Açıklama: CORS desteği ekle

# Açıklama: Timeout ayarları
app.config['SEND_FILE_MAX_AGE_DEFAULT'] = 0
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB max

# Açıklama: Global değişkenler
interpreter = None
model_load_time = 0
labels = []
colors = []
processing_stats = {
    'total_requests': 0,
    'successful_requests': 0,
    'failed_requests': 0,
    'average_processing_time': 0
}

# Açıklama: Thread-safe counter
stats_lock = threading.Lock()

def update_stats(success: bool, processing_time: float):
    """İstatistikleri güncelle"""
    with stats_lock:
        processing_stats['total_requests'] += 1
        if success:
            processing_stats['successful_requests'] += 1
        else:
            processing_stats['failed_requests'] += 1
        
        # Açıklama: Ortalama işlem süresini güncelle
        current_avg = processing_stats['average_processing_time']
        total_successful = processing_stats['successful_requests']
        if total_successful > 0:
            processing_stats['average_processing_time'] = (
                (current_avg * (total_successful - 1) + processing_time) / total_successful
            )

# Klasörleri oluştur
os.makedirs('Desktop/incoming', exist_ok=True)
os.makedirs('Desktop/processed', exist_ok=True)

def load_labels_and_colors():
    """Label ve color dosyalarını yükle"""
    global labels, colors
    
    try:
        # Label dosyasını yükle
        with open('deeplabv3_labels.txt', 'r') as f:
            labels = [line.strip() for line in f.readlines() if line.strip()]
        
        # Color dosyasını yükle
        with open('deeplabv3_colors.txt', 'r') as f:
            colors = []
            for line in f.readlines():
                if line.strip():
                    r, g, b = map(int, line.strip().split(','))
                    colors.append((r, g, b))
        
        logger.info(f'Loaded {len(labels)} labels and {len(colors)} colors')
        return True
    except Exception as e:
        logger.error(f'Error loading labels/colors: {e}')
        return False

def load_model():
    """Model yükleme fonksiyonu"""
    global interpreter, model_load_time
    start_time = time.time()
    
    try:
        interpreter = tf.lite.Interpreter(model_path='deeplabv3-xception65.tflite')
        interpreter.allocate_tensors()
        
        # Açıklama: Model input boyutlarını al
        input_details = interpreter.get_input_details()
        input_shape = input_details[0]['shape']
        model_load_time = time.time() - start_time
        
        logger.info(f'DeepLabV3 model loaded successfully in {model_load_time:.2f}s. Input shape: {input_shape}')
        return True
    except Exception as e:
        logger.error(f'Model loading error: {e}')
        interpreter = None
        return False

# Açıklama: Label ve color dosyalarını yükle
load_labels_and_colors()

# Açıklama: Model yükle
load_model()

@app.route('/health')
def health():
    """API sağlık kontrolü - Geliştirilmiş"""
    return jsonify({
        'status': 'ok', 
        'model_loaded': interpreter is not None,
        'model_load_time': model_load_time,
        'labels_loaded': len(labels) > 0,
        'colors_loaded': len(colors) > 0,
        'available_classes': labels,
        'server_uptime': time.time(),
        'processing_stats': processing_stats,
        'timestamp': datetime.now().isoformat()
    })

@app.route('/mask', methods=['POST'])
def mask_image():
    """Resim maskeleme endpoint'i - Optimize edilmiş"""
    start_time = time.time()
    success = False
    incoming_path = None
    
    try:
        data = request.get_json()
        device_id = data.get('device_id', 'unknown')
        image_data = data.get('image')
        
        if not image_data:
            return jsonify({'error': 'No image data provided'}), 400
        
        # Açıklama: Base64'ten resmi decode et
        try:
            image_bytes = base64.b64decode(image_data)
            nparr = np.frombuffer(image_bytes, np.uint8)
            image = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        except Exception as e:
            logger.error(f'Image decode error: {e}')
            return jsonify({'error': 'Invalid image data format'}), 400
        
        if image is None:
            return jsonify({'error': 'Invalid image data'}), 400
        
        # Açıklama: Resim boyutunu kontrol et
        if image.shape[0] > 4096 or image.shape[1] > 4096:
            return jsonify({'error': 'Image too large. Max size: 4096x4096'}), 400
        
        # Gelen resmi geçici olarak kaydet
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        incoming_path = f'Desktop/incoming/{device_id}_{timestamp}.jpg'
        cv2.imwrite(incoming_path, image)
        logger.info(f'Image temporarily saved: {incoming_path} ({image.shape[1]}x{image.shape[0]})')
        
        # Maskeleme işlemi
        if interpreter:
            try:
                # Açıklama: Model input boyutlarını al
                input_details = interpreter.get_input_details()
                input_shape = input_details[0]['shape']
                input_height = input_shape[1]
                input_width = input_shape[2]
                
                # Resmi model için hazırla
                input_size = (input_width, input_height)
                resized = cv2.resize(image, input_size)
                input_data = resized.astype(np.float32) / 255.0
                input_data = np.expand_dims(input_data, axis=0)
                
                # Model çıktısını al
                interpreter.set_tensor(interpreter.get_input_details()[0]['index'], input_data)
                interpreter.invoke()
                output = interpreter.get_tensor(interpreter.get_output_details()[0]['index'])
                
                # Maske oluştur - sadece araba (car) sınıfını maskele
                output_mask = output[0]
                car_class_index = 13  # Cityscapes'te car sınıfının indeksi
                
                # Araba maskesi oluştur
                car_mask = (np.argmax(output_mask, axis=-1) == car_class_index).astype(np.uint8) * 255
                mask = cv2.resize(car_mask, (image.shape[1], image.shape[0]))
                
                # Maskelenmiş resmi geçici olarak kaydet
                processed_path = f'Desktop/processed/{device_id}_{timestamp}_mask.jpg'
                cv2.imwrite(processed_path, mask)
                logger.info(f'Mask temporarily saved: {processed_path}')
                
                # Maske'yi base64'e çevir
                _, buffer = cv2.imencode('.jpg', mask, [cv2.IMWRITE_JPEG_QUALITY, 90])
                mask_base64 = base64.b64encode(buffer).decode('utf-8')
                
                # Açıklama: Orijinal resmi ve maskelenen resmi gizlilik ve yer tasarrufu için sil
                try:
                    if os.path.exists(incoming_path):
                        os.remove(incoming_path)
                        logger.info(f'Original image deleted for privacy: {incoming_path}')
                except Exception as e:
                    logger.warning(f'Could not delete original image: {e}')
                
                try:
                    if os.path.exists(processed_path):
                        os.remove(processed_path)
                        logger.info(f'Masked image deleted for privacy and storage: {processed_path}')
                except Exception as e:
                    logger.warning(f'Could not delete masked image: {e}')
                
                processing_time = time.time() - start_time
                success = True
                update_stats(True, processing_time)
                
                return jsonify({
                    'success': True,
                    'device_id': device_id,
                    'mask': mask_base64,
                    'message': f'Image processed for device {device_id}',
                    'processing_time': processing_time,
                    'image_size': f"{image.shape[1]}x{image.shape[0]}",
                    'timestamp': timestamp
                })
                
            except Exception as e:
                logger.error(f'Model processing error: {e}')
                processing_time = time.time() - start_time
                update_stats(False, processing_time)
                
                # Açıklama: Hata durumunda da orijinal resmi ve maskelenen resmi sil
                try:
                    if os.path.exists(incoming_path):
                        os.remove(incoming_path)
                        logger.info(f'Original image deleted after error: {incoming_path}')
                except Exception as del_error:
                    logger.warning(f'Could not delete original image after error: {del_error}')
                
                try:
                    if 'processed_path' in locals() and os.path.exists(processed_path):
                        os.remove(processed_path)
                        logger.info(f'Masked image deleted after error: {processed_path}')
                except Exception as del_error:
                    logger.warning(f'Could not delete masked image after error: {del_error}')
                
                return jsonify({'error': f'Model processing failed: {str(e)}'}), 500
        else:
            processing_time = time.time() - start_time
            update_stats(False, processing_time)
            
            # Açıklama: Model yüklenmemiş durumunda da orijinal resmi ve maskelenen resmi sil
            try:
                if os.path.exists(incoming_path):
                    os.remove(incoming_path)
                    logger.info(f'Original image deleted (model not loaded): {incoming_path}')
            except Exception as del_error:
                logger.warning(f'Could not delete original image (model not loaded): {del_error}')
            
            try:
                if 'processed_path' in locals() and os.path.exists(processed_path):
                    os.remove(processed_path)
                    logger.info(f'Masked image deleted (model not loaded): {processed_path}')
            except Exception as del_error:
                logger.warning(f'Could not delete masked image (model not loaded): {del_error}')
            
            return jsonify({'error': 'Model not loaded'}), 500
            
    except Exception as e:
        processing_time = time.time() - start_time
        update_stats(False, processing_time)
        logger.error(f'Error processing image: {e}')
        
        # Açıklama: Genel hata durumunda da orijinal resmi ve maskelenen resmi sil
        try:
            if 'incoming_path' in locals() and os.path.exists(incoming_path):
                os.remove(incoming_path)
                logger.info(f'Original image deleted (general error): {incoming_path}')
        except Exception as del_error:
            logger.warning(f'Could not delete original image (general error): {del_error}')
        
        try:
            if 'processed_path' in locals() and os.path.exists(processed_path):
                os.remove(processed_path)
                logger.info(f'Masked image deleted (general error): {processed_path}')
        except Exception as del_error:
            logger.warning(f'Could not delete masked image (general error): {del_error}')
        
        return jsonify({'error': str(e)}), 500

@app.route('/status')
def status():
    """Sunucu durumu - Geliştirilmiş"""
    return jsonify({
        'server': 'running',
        'model_loaded': interpreter is not None,
        'model_load_time': model_load_time,
        'processing_stats': processing_stats,
        'folders': {
            'incoming': os.path.exists('Desktop/incoming'),
            'processed': os.path.exists('Desktop/processed')
        },
        'timestamp': datetime.now().isoformat()
    })

@app.route('/stats')
def get_stats():
    """Detaylı istatistikler"""
    return jsonify({
        'processing_stats': processing_stats,
        'model_info': {
            'loaded': interpreter is not None,
            'load_time': model_load_time
        },
        'server_info': {
            'uptime': time.time(),
            'timestamp': datetime.now().isoformat()
        }
    })

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    logger.info(f'Starting Image Masker Server on port {port}...')
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
