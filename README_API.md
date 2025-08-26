# 🚀 GitHub Flask API - Maskeleme Servisi

Bu API, Android uygulamasından gelen resimleri alıp DeepLabV3+ modeli ile maskeleme işlemi yapar.

## 📋 Gereksinimler

- **Python 3.8+** (https://python.org)
  - Python 3.13 için `alternative_setup.bat` kullanın
- **Windows 10/11**
- **İnternet bağlantısı** (ilk kurulum için)

## 🛠️ Hızlı Kurulum

### Yöntem 1: Tek Tıkla Kurulum
```bash
# quick_setup.bat dosyasını çift tıklayın
quick_setup.bat
```

### Yöntem 1.5: Alternatif Kurulum (Python 3.13 için)
```bash
# alternative_setup.bat dosyasını çift tıklayın
alternative_setup.bat
```

### Yöntem 2: Manuel Kurulum
```bash
# 1. Python'u kontrol edin
python --version

# 2. Kütüphaneleri kurun
pip install -r requirements.txt

# 3. API'yi başlatın
python image-masker.py
```

## 🌐 API Endpoints

### Health Check
```http
GET http://192.168.1.41:5000/health
```

**Response:**
```json
{
  "status": "healthy",
  "model_loaded": true,
  "model_path": "deeplabv3-xception65.tflite",
  "available_classes": ["road", "sidewalk", "building", ...]
}
```

### Tek Nesne Maskeleme
```http
POST http://192.168.1.41:5000/mask
Content-Type: application/json

{
  "image": "base64_encoded_image",
  "class_index": 13
}
```

### Çoklu Nesne Maskeleme
```http
POST http://192.168.1.41:5000/mask_multiple
Content-Type: application/json

{
  "image": "base64_encoded_image",
  "class_indices": [13, 11, 2]
}
```

## 📱 Android Entegrasyonu

Android uygulaması otomatik olarak bu API'ye bağlanır:

```kotlin
val remoteMaskingService = RemoteMaskingApiService(context)
val result = remoteMaskingService.maskMultipleObjectsRemote(bitmap, classIndices)
```

## 🔧 Sorun Giderme

### Python Kurulu Değil
```bash
# Python'u indirin ve kurun
# https://python.org/downloads/
```

### Kütüphane Kurulum Hatası
```bash
# pip'i güncelleyin
python -m pip install --upgrade pip

# Python 3.13 için alternatif kurulum
alternative_setup.bat

# Veya tek tek kurun (en son versiyonlar)
pip install Flask
pip install tensorflow
pip install opencv-python
pip install numpy
```

### Port Kullanımda
```bash
# Farklı port kullanın
python image-masker.py --port 5001
```

### Model Dosyası Bulunamadı
```bash
# deeplabv3-xception65.tflite dosyasının aynı klasörde olduğundan emin olun
```

## 📊 Performans

- **Model Yükleme:** ~2-3 saniye
- **Tek Resim İşleme:** ~1-2 saniye
- **Çoklu Nesne:** ~2-5 saniye
- **Bellek Kullanımı:** ~500MB

## 🔒 Güvenlik

- API sadece yerel ağda çalışır (192.168.1.41)
- CORS desteği mevcut
- Base64 encoding ile güvenli veri transferi

## 📝 Loglar

API çalışırken konsol logları:
```
Loading DeepLabV3+ model...
Model loaded successfully!
Starting Flask server...
Server URL: http://192.168.1.41:5000
```

## 🆘 Destek

Sorun yaşarsanız:
1. Python versiyonunu kontrol edin
2. İnternet bağlantısını kontrol edin
3. Firewall ayarlarını kontrol edin
4. Port 5000'in açık olduğundan emin olun
