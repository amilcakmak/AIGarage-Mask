// Dosya: auto-install-software-main/android-api-example.java
// Açıklama: Android uygulamasından resim maskeleme API'sine istek gönderme örneği

import android.graphics.Bitmap;
import android.util.Base64;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import okhttp3.*;
import org.json.JSONObject;
import org.json.JSONException;

public class ImageMaskingAPI {
    
    private static final String API_BASE_URL = "https://your-ngrok-url.ngrok.io"; // Telegram'dan gelen URL
    private static final String MASK_ENDPOINT = "/mask";
    private static final String HEALTH_ENDPOINT = "/health";
    
    private final OkHttpClient client;
    private final String deviceId;
    
    public ImageMaskingAPI(String deviceId) {
        this.client = new OkHttpClient();
        this.deviceId = deviceId;
    }
    
    /**
     * API'nin çalışıp çalışmadığını kontrol et
     */
    public boolean checkHealth() {
        try {
            Request request = new Request.Builder()
                .url(API_BASE_URL + HEALTH_ENDPOINT)
                .get()
                .build();
                
            Response response = client.newCall(request).execute();
            return response.isSuccessful();
        } catch (IOException e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Resmi maskeleme API'sine gönder
     */
    public MaskingResult maskImage(Bitmap image) {
        try {
            // Resmi Base64'e çevir
            String base64Image = bitmapToBase64(image);
            
            // JSON request body oluştur
            JSONObject requestBody = new JSONObject();
            requestBody.put("device_id", deviceId);
            requestBody.put("image", base64Image);
            
            // HTTP request oluştur
            RequestBody body = RequestBody.create(
                MediaType.parse("application/json"), 
                requestBody.toString()
            );
            
            Request request = new Request.Builder()
                .url(API_BASE_URL + MASK_ENDPOINT)
                .post(body)
                .addHeader("Content-Type", "application/json")
                .build();
            
            // Request'i gönder
            Response response = client.newCall(request).execute();
            
            if (response.isSuccessful()) {
                String responseBody = response.body().string();
                JSONObject jsonResponse = new JSONObject(responseBody);
                
                if (jsonResponse.getBoolean("success")) {
                    String maskBase64 = jsonResponse.getString("mask");
                    String message = jsonResponse.getString("message");
                    
                    // Base64'ten Bitmap'e çevir
                    Bitmap maskBitmap = base64ToBitmap(maskBase64);
                    
                    return new MaskingResult(true, maskBitmap, message, null);
                } else {
                    String error = jsonResponse.getString("error");
                    return new MaskingResult(false, null, null, error);
                }
            } else {
                return new MaskingResult(false, null, null, "HTTP Error: " + response.code());
            }
            
        } catch (IOException | JSONException e) {
            e.printStackTrace();
            return new MaskingResult(false, null, null, e.getMessage());
        }
    }
    
    /**
     * Bitmap'i Base64 string'e çevir
     */
    private String bitmapToBase64(Bitmap bitmap) {
        ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, byteArrayOutputStream);
        byte[] byteArray = byteArrayOutputStream.toByteArray();
        return Base64.encodeToString(byteArray, Base64.DEFAULT);
    }
    
    /**
     * Base64 string'i Bitmap'e çevir
     */
    private Bitmap base64ToBitmap(String base64String) {
        byte[] decodedBytes = Base64.decode(base64String, Base64.DEFAULT);
        return BitmapFactory.decodeByteArray(decodedBytes, 0, decodedBytes.length);
    }
    
    /**
     * Maskeleme sonucu için wrapper class
     */
    public static class MaskingResult {
        public final boolean success;
        public final Bitmap mask;
        public final String message;
        public final String error;
        
        public MaskingResult(boolean success, Bitmap mask, String message, String error) {
            this.success = success;
            this.mask = mask;
            this.message = message;
            this.error = error;
        }
    }
}

// Kullanım örneği:
/*
public class MainActivity extends AppCompatActivity {
    
    private ImageMaskingAPI api;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        // API'yi başlat (device ID'yi kullan)
        String deviceId = Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID);
        api = new ImageMaskingAPI(deviceId);
        
        // API sağlık kontrolü
        if (api.checkHealth()) {
            Log.d("API", "Server is healthy!");
        } else {
            Log.e("API", "Server is not responding!");
        }
    }
    
    private void processImage(Bitmap image) {
        // Background thread'de çalıştır
        new Thread(() -> {
            ImageMaskingAPI.MaskingResult result = api.maskImage(image);
            
            // UI thread'de sonucu göster
            runOnUiThread(() -> {
                if (result.success) {
                    // Maske başarıyla alındı
                    ImageView maskImageView = findViewById(R.id.maskImageView);
                    maskImageView.setImageBitmap(result.mask);
                    Toast.makeText(this, result.message, Toast.LENGTH_SHORT).show();
                } else {
                    // Hata oluştu
                    Toast.makeText(this, "Error: " + result.error, Toast.LENGTH_LONG).show();
                }
            });
        }).start();
    }
}
*/
