@echo off
title GitHub Flask API - Alternatif Kurulum
color 0B

echo ========================================
echo    GITHUB FLASK API - ALTERNATİF KURULUM
echo ========================================
echo.
echo 🔧 Python 3.13 için en son uyumlu versiyonlar
echo.

echo [1/4] Python kontrol ediliyor...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Python kurulu değil!
    echo 📥 https://python.org adresinden Python 3.8+ indirin
    pause
    exit /b 1
)
echo ✅ Python kurulu

echo.
echo [2/4] pip güncelleniyor...
python -m pip install --upgrade pip --quiet
echo ✅ pip güncellendi

echo.
echo [3/4] Kütüphaneler kuruluyor (en son versiyonlar)...
echo ⏳ Bu işlem 5-10 dakika sürebilir...
echo 📦 En son uyumlu versiyonlar otomatik seçiliyor...
echo.

echo 🔄 Flask kuruluyor...
pip install Flask --quiet
echo ✅ Flask kuruldu

echo 🔄 TensorFlow kuruluyor...
pip install tensorflow --quiet
echo ✅ TensorFlow kuruldu

echo 🔄 OpenCV kuruluyor...
pip install opencv-python --quiet
echo ✅ OpenCV kuruldu

echo 🔄 NumPy kuruluyor...
pip install numpy --quiet
echo ✅ NumPy kuruldu

echo 🔄 Pillow kuruluyor...
pip install Pillow --quiet
echo ✅ Pillow kuruldu

echo.
echo [4/4] API başlatılıyor...
echo 🌐 Sunucu URL: http://192.168.1.41:5000
echo 📱 Android uygulaması bu adrese bağlanacak
echo.
echo ⚠️  API'yi durdurmak için Ctrl+C tuşlayın
echo.

python image-masker.py

pause
