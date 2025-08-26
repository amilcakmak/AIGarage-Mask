# 🚗 AI Garage - Image Masking API

DeepLabV3+ ile araba maskeleme Flask API sunucusu.

## 🚀 Özellikler

- ✅ **DeepLabV3+ Model** - Araba maskeleme
- ✅ **Flask API** - RESTful endpoint'ler
- ✅ **CORS Desteği** - Cross-origin requests
- ✅ **Gizlilik Koruması** - Otomatik dosya silme
- ✅ **Label/Color Desteği** - Cityscapes dataset
- ✅ **Health Check** - Sunucu durumu kontrolü

## 📋 API Endpoint'leri

### Health Check
```
GET /health
```

### Image Masking
```
POST /mask
Content-Type: application/json

{
  "device_id": "android_device",
  "image": "base64_encoded_image"
}
```

### Server Status
```
GET /status
```

### Statistics
```
GET /stats
```

## 🛠️ Kurulum

### Yerel Kurulum
```bash
pip install -r requirements.txt
python image-masker.py
```

### Render Deployment
1. GitHub'a kodunuzu push edin
2. Render.com'da yeni Web Service oluşturun
3. GitHub repository'nizi seçin
4. Build Command: `pip install -r requirements.txt`
5. Start Command: `gunicorn image-masker:app`

## 🔧 Gereksinimler

- Python 3.11+
- TensorFlow 2.13.0
- OpenCV 4.8.1
- Flask 2.3.3

## 📁 Dosya Yapısı

```
├── image-masker.py          # Ana Flask uygulaması
├── requirements.txt         # Python bağımlılıkları
├── Dockerfile              # Docker container
├── deeplabv3_labels.txt    # Label dosyası
├── deeplabv3_colors.txt    # Color dosyası
├── deeplabv3-xception65.tflite  # DeepLabV3 model
└── README.md               # Bu dosya
```

## 🔒 Güvenlik

- ✅ Kullanıcı fotoğrafları otomatik silinir
- ✅ Maskelenen resimler otomatik silinir
- ✅ Hiçbir kullanıcı verisi saklanmaz
- ✅ CORS koruması aktif

## 📊 Performans

- ✅ Model yükleme: ~0.3s
- ✅ Maskeleme işlemi: ~2-5s
- ✅ Memory optimizasyonu
- ✅ Thread-safe işlemler

## 🌐 Canlı Demo

Render'da yayınlandıktan sonra:
```
https://your-app-name.onrender.com/health
```

## 📞 Destek

Herhangi bir sorun için GitHub Issues kullanın.
