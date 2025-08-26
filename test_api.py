import requests
import base64
import json
import numpy as np
import cv2

def create_test_image():
    # Basit bir test resmi oluştur (10x10 piksel, gri)
    test_image = np.ones((100, 100, 3), dtype=np.uint8) * 128
    # Ortaya bir dikdörtgen çiz (araba simülasyonu)
    cv2.rectangle(test_image, (30, 30), (70, 70), (255, 255, 255), -1)
    
    # Resmi JPEG'e çevir
    _, buffer = cv2.imencode('.jpg', test_image)
    # Base64'e çevir
    image_base64 = base64.b64encode(buffer).decode('utf-8')
    return image_base64

def test_mask_endpoint():
    # Açıklama: localhost kullanarak yerel test
    url = "http://localhost:5000/mask"
    
    # Test resmi oluştur
    test_image = create_test_image()
    
    # JSON payload hazırla
    payload = {
        "device_id": "test_device",
        "image": test_image
    }
    
    headers = {
        'Content-Type': 'application/json'
    }
    
    try:
        print("API'ye test isteği gönderiliyor...")
        response = requests.post(url, json=payload, headers=headers)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response Headers: {response.headers}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ Başarılı!")
            print(f"Success: {result.get('success')}")
            print(f"Message: {result.get('message')}")
            if result.get('mask'):
                print(f"Mask length: {len(result['mask'])} characters")
        else:
            print("❌ Hata!")
            print(f"Error Response: {response.text}")
            
    except Exception as e:
        print(f"❌ Exception: {e}")

def test_health_endpoint():
    # Açıklama: localhost kullanarak yerel test
    url = "http://localhost:5000/health"
    
    try:
        response = requests.get(url)
        print(f"Health Check Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"Model Loaded: {result.get('model_loaded')}")
            print(f"Status: {result.get('status')}")
        else:
            print(f"Health Check Error: {response.text}")
    except Exception as e:
        print(f"Health Check Exception: {e}")

if __name__ == "__main__":
    print("=== API Test Başlıyor ===")
    print()
    
    print("1. Health Check Test:")
    test_health_endpoint()
    print()
    
    print("2. Mask Endpoint Test:")
    test_mask_endpoint()
    print()
    
    print("=== Test Tamamlandı ===")
