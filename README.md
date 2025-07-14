![GX6YwvoW8AAyCUK](https://github.com/user-attachments/assets/65fbb2b4-43f1-49c9-961c-70d8f4b3b680)

## Octra Testnet Katılım Rehberi

Bu rehber, tarayıcıdan 2 tıkla yapılan testlerden farklıdır. İşlemler terminal üzerinden, WSL ya da VPS üzerinde yapılır.

---

### Ne Yapacağız?

1. WSL kurulum (veya VPS kullanımı)
2. Scripti indirip çalıştırma
3. Testnet işlemlerini gerçekleştirme

---

### 1. WSL Kurulumu

Sıradan veya ücretsiz sunucular üzerinden de bu işlemleri gerçekleştirebilirsiniz.

Kendi bilgisayarınızdan yapmak istiyorsanız, WSL kurulumunu tamamlayıp Ubuntu 22.04 yüklemeniz gerekir.

➡️ Rehber: [WSL Kurulumu için tıklayın](https://x.com/UfukDegen/status/1944066889346429338)

---

### 2. Güncelleme

Sistemi güncellemek için aşağıdaki komutu terminale girin:

```bash
sudo apt update && sudo apt upgrade -y
```

---

### 3. Script Kurulumu ve Çalıştırma

Aşağıdaki komutları sırasıyla terminale girin:

```bash
wget https://raw.githubusercontent.com/UfukNode/octra/refs/heads/main/octrascript.sh
chmod +x octrascript.sh
sudo ./octrascript.sh
```

---

### 4. Cüzdan Oluşturma

- Script menüsünden `1` numaralı seçeneği seçerek tam kurulumu başlatın.
- WSL kullanıyorsanız: `http://localhost:8888`
- VPS kullanıyorsanız: `http://<sunucu-ip>:8888`

Tarayıcıdan bu adrese gidin → “New Wallet” butonuna tıklayın → Verilen bilgileri kaydedin.

---

### 5. \$OCT Faucet

Test token almak için şu adrese gidin:
➡️ [https://faucet.octra.network/](https://faucet.octra.network/)

* “oct..” ile başlayan adresinizi girin
* İnsan doğrulamasını yapın
* Tokenleri alın
* 📌 *Validatör kutucuğunu işaretlemeyin*

---

### 6. CLI Arayüzü Başlat

- Cüzdan ve faucet işlemini tamamladıktan sonra ENTER’a basın
- Privkey ve adres bilgilerinizi girin
- Ana menüden `4` numaralı seçeneği seçerek CLI arayüzünü başlatın

---

### ⚠️ Ekstra Bilgi

- CLI arayüzü bozuk görünürse `2` yazıp ENTER yapın (görüntü yenilenir)
- Hâlâ düzelmezse `CTRL+C` ile çıkın, menüden tekrar `4`’ü seçerek arayüzü yeniden başlatın

---

### 7. TX Atma

- CLI arayüzünde `1` yazın
- Aktif bir cüzdan adresi girin (örnek: `oct...`)
- Göndermek istediğiniz miktarı yazın
- ENTER’a basarak işlemi tamamlayın

---

### 8. Encrypt Balance

→ CLI arayüzünde `4` yazın
→ Şifrelemek istediğiniz miktarı girin
→ İşlem 5-10 dakika sürebilir, bitmeden başka işlem yapmayın

---

### 9. Private Transfer

- CLI arayüzünde `6` yazın
- Aktif bir alıcı adresi girin
- Gönderilecek miktarı yazıp işlemi tamamlayın

---

### 10. Farklı Cüzdan ile Giriş (Opsiyonel)

Multi önermem, ben multici değil emekçi bir adamım ama yersen.

- Ana menüden `CTRL+C` ile çıkış yap.

```bash
rm -rf octra_pre_client/wallet.json  # Eski cüzdanı sil
./octrascript.sh  # Script menüsüne geri dön
```

- Menüde `3` seçeneğini seç → Yeni cüzdan bilgilerini gir
- Ardından CLI arayüzünü başlat

---

### 💡Ekstra Bilgiler

* Menüden çıktıktan sonra tekrar girmek için:

```bash
./octrascript.sh
```

* CLI projesi güncellendiyse, menüden `5` numaralı seçeneği seçerek güncelleyebilirsiniz.
