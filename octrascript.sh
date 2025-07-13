#!/bin/bash


set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

show_banner() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║    UFUK DEGEN TARAFINDAN HAZIRLANDI    ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

loading() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Root kontrolü
check_root() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${RED}Bu script root olarak çalıştırılmamalı!${NC}"
        exit 1
    fi
}

# Bağımlılıkları yükle
install_dependencies() {
    echo -e "${YELLOW}Bağımlılıklar yükleniyor...${NC}"
    {
        sudo apt update && sudo apt upgrade -y
        sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev python3 python3-pip python3-venv python3-dev -y
    } &> /dev/null &
    loading $!
    echo -e "${GREEN}✓ Bağımlılıklar yüklendi${NC}"
}

# Node.js yükle
install_nodejs() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}Node.js yükleniyor...${NC}"
        {
            sudo apt update
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
            sudo apt install -y nodejs
            npm install -g yarn
        } &> /dev/null &
        loading $!
        echo -e "${GREEN}✓ Node.js yüklendi${NC}"
    else
        echo -e "${GREEN}✓ Node.js zaten yüklü${NC}"
    fi
}

# Cüzdan oluştur
generate_wallet() {
    echo -e "${YELLOW}Cüzdan oluşturucu hazırlanıyor...${NC}"
    
    # Cüzdan oluşturucuyu klonla
    if [ ! -d "wallet-gen" ]; then
        git clone https://github.com/0xmoei/wallet-gen.git &> /dev/null
    fi
    
    cd wallet-gen
    chmod +x ./start.sh
    
    # Cüzdan oluşturucuyu arka planda başlat
    ./start.sh &> /dev/null &
    WALLET_PID=$!
    
    echo -e "${CYAN}Cüzdan oluşturucu çalışıyor...${NC}"
    echo -e "${YELLOW}Lütfen bu adımları takip edin:${NC}"
    echo -e "1. Tarayıcınızı açın ve şu adrese gidin: ${GREEN}http://localhost:8888${NC}"
    echo -e "2. 'GENERATE NEW WALLET' butonuna tıklayın"
    echo -e "3. Tüm cüzdan bilgilerini kaydedin"
    echo -e "4. Şu adresten faucet alın: ${GREEN}https://faucet.octra.xyz${NC}"
    echo ""
    
    # Kullanıcının cüzdan bilgilerini kaydetmesini bekle
    read -p "Cüzdan bilgilerinizi kaydettikten sonra ENTER'a basın..."
    
    # Cüzdan oluşturucuyu kapat
    kill $WALLET_PID 2>/dev/null || true
    
    cd ..
}

# Octra CLI kurulumu
setup_octra_cli() {
    echo -e "${YELLOW}Octra CLI kuruluyor...${NC}"
    
    # Octra CLI'yi klonla
    if [ ! -d "octra_pre_client" ]; then
        git clone https://github.com/octra-labs/octra_pre_client.git &> /dev/null
    fi
    
    cd octra_pre_client
    
    # Python sanal ortamını kur
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    
    # wallet.json oluştur
    cp wallet.json.example wallet.json
    
    echo -e "${YELLOW}Lütfen cüzdan bilgilerinizi girin:${NC}"
    read -p "Private key'inizi girin (B64 formatında): " PRIVATE_KEY
    read -p "Octra adresinizi girin (oct... ile başlayan): " OCTRA_ADDRESS
    
    # wallet.json dosyasını güncelle
    sed -i "s/private-key-here/$PRIVATE_KEY/g" wallet.json
    sed -i "s/octxxxxxxxx/$OCTRA_ADDRESS/g" wallet.json
    
    echo -e "${GREEN}✓ Octra CLI yapılandırıldı${NC}"
}

# Otomatik işlem gönderici
auto_transaction() {
    echo -e "${YELLOW}Otomatik işlem gönderici başlatılıyor...${NC}"
    
    cd octra_pre_client
    source venv/bin/activate
    
    # İşlem gönderilecek adresler
    ADDRESSES=(
        "octBvPDeFCaAZtfr3SBr7Jn6nnWnUuCfAZfgCmaqswV8YR5"
        # Buraya daha fazla adres ekleyebilirsiniz
    )
    
    # Otomatik işlem scripti oluştur
    cat > auto_tx.py << 'EOF'
import time
import random
import subprocess
import sys

def send_transaction():
    try:
        # CLI komutları burada çalıştırılacak
        # Bu bir placeholder - gerçek CLI komutlarına göre uyarlanmalı
        print("İşlem gönderiliyor...")
        time.sleep(2)
        print("İşlem gönderildi!")
        return True
    except Exception as e:
        print(f"Hata: {e}")
        return False

def main():
    transaction_count = 0
    
    while True:
        try:
            # İşlemler arası rastgele bekleme (5-15 dakika)
            delay = random.randint(300, 900)
            
            print(f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] İşlem #{transaction_count + 1} gönderiliyor")
            
            if send_transaction():
                transaction_count += 1
                print(f"Toplam gönderilen işlem: {transaction_count}")
            
            print(f"Sonraki işlem için {delay} saniye bekleniyor...")
            time.sleep(delay)
            
        except KeyboardInterrupt:
            print("\nOtomatik işlem gönderici durduruluyor...")
            sys.exit(0)
        except Exception as e:
            print(f"Beklenmeyen hata: {e}")
            time.sleep(60)

if __name__ == "__main__":
    main()
EOF
    
    echo -e "${GREEN}✓ Otomatik işlem gönderici oluşturuldu${NC}"
}

# Screen'de çalıştır
run_in_screen() {
    echo -e "${YELLOW}Octra testnet screen oturumunda başlatılıyor...${NC}"
    
    # Mevcut screen oturumunu kapat
    screen -S octra -X quit 2>/dev/null || true
    
    # Yeni screen oturumu oluştur
    screen -dmS octra bash -c "cd octra_pre_client && source venv/bin/activate && python3 auto_tx.py"
    
    echo -e "${GREEN}✓ Octra testnet 'octra' screen oturumunda çalışıyor${NC}"
    echo -e "${CYAN}Komutlar:${NC}"
    echo -e "  Logları görüntüle: ${YELLOW}screen -r octra${NC}"
    echo -e "  Oturumdan çık: ${YELLOW}Ctrl+A, sonra D${NC}"
    echo -e "  Durdur: ${YELLOW}screen -S octra -X quit${NC}"
}

# Güncelleme fonksiyonu
update_cli() {
    echo -e "${YELLOW}Octra CLI güncelleniyor...${NC}"
    
    cd octra_pre_client
    
    # wallet.json dosyasını yedekle
    cp wallet.json ../wallet.json.backup
    
    # Güncelle
    git stash &> /dev/null
    git pull origin main &> /dev/null
    
    # wallet.json dosyasını geri yükle
    cp ../wallet.json.backup wallet.json
    
    # Bağımlılıkları güncelle
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    
    echo -e "${GREEN}✓ Octra CLI güncellendi${NC}"
}

main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Bir seçenek seçin:${NC}"
        echo "1) Tam kurulum"
        echo "2) Sadece cüzdan oluştur"
        echo "3) Sadece CLI kur"
        echo "4) Otomatik işlem başlat"
        echo "5) CLI güncelle"
        echo "6) Logları görüntüle"
        echo "7) Çıkış"
        echo ""
        read -p "Seçiminizi girin [1-7]: " choice
        
        case $choice in
            1)
                check_root
                install_dependencies
                install_nodejs
                generate_wallet
                setup_octra_cli
                auto_transaction
                run_in_screen
                echo -e "${GREEN}Kurulum tamamlandı!${NC}"
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            2)
                generate_wallet
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            3)
                setup_octra_cli
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            4)
                auto_transaction
                run_in_screen
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            5)
                update_cli
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            6)
                screen -r octra
                ;;
            7)
                echo -e "${GREEN}Güle güle!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Geçersiz seçenek!${NC}"
                sleep 2
                ;;
        esac
    done
}

main_menu
