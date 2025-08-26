@echo off
title GitHub Flask API - Hızlı Kurulum
color 0A

echo ========================================
echo    GITHUB FLASK API - HIZLI KURULUM
echo ========================================
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
echo [3/4] Kütüphaneler kuruluyor...
echo ⏳ Bu işlem 3-7 dakika sürebilir...
echo 📦 Python 3.13 uyumlu versiyonlar kullanılıyor...
pip install Flask==3.0.0 tensorflow==2.15.0 opencv-python==4.8.1.78 numpy==1.26.2 --quiet
if %errorlevel% neq 0 (
    echo ❌ Kurulum hatası!
    echo 🔧 Alternatif kurulum deneniyor...
    pip install Flask tensorflow opencv-python numpy --quiet
    if %errorlevel% neq 0 (
        echo ❌ Kurulum başarısız!
        pause
        exit /b 1
    )
)
echo ✅ Kütüphaneler kuruldu

echo.
echo [4/4] API başlatılıyor...
echo 🌐 Sunucu URL: http://192.168.1.41:5000
echo 📱 Android uygulaması bu adrese bağlanacak
echo.
echo ⚠️  API'yi durdurmak için Ctrl+C tuşlayın
echo.

python image-masker.py

pause
