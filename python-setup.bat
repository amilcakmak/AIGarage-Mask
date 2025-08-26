@echo off
echo Setting up Python and Image Processing Tools...

:: Python kurulumu (sessiz mod)
echo Installing Python...
cd /d "%~dp0Downloaded"
if exist "python-3.11.8-amd64.exe" (
    echo Installing Python 3.11.8...
    python-3.11.8-amd64.exe /quiet InstallAllUsers=1 PrependPath=1 Include_test=0
    echo Python installed successfully
)

:: PATH'i güncelle
echo Updating PATH...
setx PATH "%PATH%;C:\Python311;C:\Python311\Scripts" /M

:: pip'i hızlandır
echo Configuring pip for faster downloads...
C:\Python311\python.exe -m pip install --upgrade pip
C:\Python311\python.exe -m pip config set global.index-url https://pypi.org/simple/
C:\Python311\python.exe -m pip config set global.timeout 60

:: Sadece gerekli paketleri yükle (minimal)
echo Installing minimal required packages...
echo Installing Flask (web server)...
C:\Python311\python.exe -m pip install flask --no-deps
echo Installing NumPy (math library)...
C:\Python311\python.exe -m pip install numpy --no-deps
echo Installing OpenCV (image processing)...
C:\Python311\python.exe -m pip install opencv-python --no-deps
echo Installing TensorFlow Lite (AI model)...
C:\Python311\python.exe -m pip install tensorflow-lite --no-deps

:: Model dosyasını indir (DeepLabV3+ Xception65)
echo Downloading DeepLabV3+ model...
C:\Python311\python.exe -c "import urllib.request; print('Downloading model...'); urllib.request.urlretrieve('https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/image_segmentation/windows/lite-model_deeplabv3-xception65_ade20k_1.tflite', 'deeplabv3-xception65.tflite'); print('Model downloaded!')"

:: Flask server'ı başlatma scripti oluştur
echo Creating Flask server startup script...
echo @echo off > "%USERPROFILE%\Desktop\Start Image Masker.bat"
echo cd /d "%~dp0" >> "%USERPROFILE%\Desktop\Start Image Masker.bat"
echo C:\Python311\python.exe image-masker.py >> "%USERPROFILE%\Desktop\Start Image Masker.bat"

:: Test scripti oluştur
echo Creating test script...
echo @echo off > "%USERPROFILE%\Desktop\Test Masker.bat"
echo echo Testing Image Masker Server... >> "%USERPROFILE%\Desktop\Test Masker.bat"
echo powershell -Command "Invoke-RestMethod -Uri 'http://localhost:5000/health'" >> "%USERPROFILE%\Desktop\Test Masker.bat"
echo pause >> "%USERPROFILE%\Desktop\Test Masker.bat"

echo.
echo ========================================
echo    PYTHON SETUP COMPLETED!
echo ========================================
echo.
echo Installed:
echo - Python 3.11.8
echo - Flask (web server)
echo - NumPy (math library)
echo - OpenCV (image processing)
echo - TensorFlow Lite (AI model)
echo - DeepLabV3+ Xception65 model
echo.
echo Desktop shortcuts created:
echo - Start Image Masker.bat
echo - Test Masker.bat
echo.
echo Server will run on: http://localhost:5000
echo API Endpoint: POST /mask
echo Health Check: GET /health
echo.
echo Setup completed in minimal time!
pause
