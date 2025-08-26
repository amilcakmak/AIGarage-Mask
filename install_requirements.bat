@echo off
echo ========================================
echo    PYTHON KÜTÜPHANELERİ KURULUYOR
echo ========================================
echo.

echo Python versiyonu kontrol ediliyor...
python --version
if %errorlevel% neq 0 (
    echo HATA: Python kurulu değil!
    echo Lütfen Python'u https://python.org adresinden indirin ve kurun.
    pause
    exit /b 1
)

echo.
echo pip güncelleniyor...
python -m pip install --upgrade pip

echo.
echo Gerekli kütüphaneler kuruluyor...
echo Bu işlem birkaç dakika sürebilir...
echo.

pip install -r requirements.txt

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo    KURULUM BAŞARILI!
    echo ========================================
    echo.
    echo Kurulan kütüphaneler:
    echo - Flask (Web framework)
    echo - TensorFlow (Machine Learning)
    echo - OpenCV (Computer Vision)
    echo - NumPy (Matematik)
    echo - Pillow (Image processing)
    echo.
    echo API'yi başlatmak için: python image-masker.py
    echo.
) else (
    echo.
    echo ========================================
    echo    KURULUM HATASI!
    echo ========================================
    echo.
    echo Bazı kütüphaneler kurulamadı.
    echo Lütfen internet bağlantınızı kontrol edin.
    echo.
)

pause
