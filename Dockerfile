# Dosya: Dockerfile
# Açıklama: Render deployment için Docker container

FROM python:3.11-slim

# Açıklama: Sistem paketlerini güncelle
RUN apt-get update && apt-get install -y \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# Açıklama: Çalışma dizinini ayarla
WORKDIR /app

# Açıklama: Python bağımlılıklarını kopyala ve yükle
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Açıklama: Uygulama dosyalarını kopyala
COPY . .

# Açıklama: Port'u aç
EXPOSE 10000

# Açıklama: Uygulamayı başlat
CMD ["gunicorn", "--bind", "0.0.0.0:10000", "image-masker:app"]
