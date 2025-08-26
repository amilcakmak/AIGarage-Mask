# Telegram Bot Kurulum Rehberi

## 1. Telegram Bot Oluşturma

### BotFather ile Bot Oluştur:
1. Telegram'da `@BotFather` ile konuşun
2. `/newbot` komutunu gönderin
3. Bot adını girin (örn: "AI Garage Monitor")
4. Bot kullanıcı adını girin (örn: "ai_garage_monitor_bot")
5. Bot token'ını kaydedin: `1234567890:ABCdefGHIjklMNOpqrsTUVwxyz`

## 2. Chat ID Alma

### Bot ile Konuşma Başlatın:
1. Oluşturduğunuz bot ile konuşma başlatın
2. `/start` komutunu gönderin
3. Web tarayıcıda şu URL'yi açın:
   ```
   https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
4. `chat_id` değerini bulun (örn: `123456789`)

## 3. Render Environment Variables

### Render Dashboard'da:
1. Projenizi açın
2. "Environment" sekmesine gidin
3. Şu değişkenleri ekleyin:

```
TELEGRAM_BOT_TOKEN=1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789
```

## 4. Bildirim Türleri

### Sunucu Başladığında:
🚀 AI Garage Masking API başlatıldı!
⏰ 2025-08-27 02:30:15
🌐 https://ai-garage-masking-api.onrender.com

### Kullanıcı Aktivitesi:
👤 Kullanıcı Aktivitesi
✅ Başarılı - device_123456
📊 Toplam İstek: 15
⏱️ Uptime: 0:45:30

### Sunucu Hatası:
❌ AI Garage Masking API Hatası!
⏰ 2025-08-27 02:35:20
🔍 Hata: Model loading failed

### Sunucu Kapandığında:
🛑 AI Garage Masking API kapatılıyor!
⏰ 2025-08-27 03:00:00
📊 Toplam İstek: 25

## 5. Test Etme

### Manuel Test:
1. Bot ile `/start` yazın
2. Sunucuyu yeniden başlatın
3. Bir maskeleme isteği gönderin
4. Bildirimleri kontrol edin

## 6. Güvenlik

### Önemli Notlar:
- Bot token'ını kimseyle paylaşmayın
- Chat ID'yi güvenli tutun
- Sadece güvendiğiniz kişileri bot'a ekleyin
