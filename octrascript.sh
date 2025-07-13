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

# Root kontrolü - Devre dışı bırakıldı
# check_root() {
#     if [[ $EUID -eq 0 ]]; then
#         echo -e "${RED}Bu script root olarak çalıştırılmamalı!${NC}"
#         exit 1
#     fi
# }

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
    echo -e "${YELLOW}Otomatik cüzdan oluşturuluyor...${NC}"
    
    # Cüzdan oluşturma scripti
    cat > create_wallet.js << 'EOF'
const { Wallet } = require('ethers');
const fs = require('fs');

// Yeni cüzdan oluştur
const wallet = Wallet.createRandom();

// Base64 formatında private key
const privateKeyB64 = Buffer.from(wallet.privateKey.slice(2), 'hex').toString('base64');

// Octra formatında adres (oct prefix'i ile)
const octraAddress = 'oct' + wallet.address.slice(2);

// Cüzdan bilgileri
const walletInfo = {
    address: wallet.address,
    octraAddress: octraAddress,
    privateKey: wallet.privateKey,
    privateKeyB64: privateKeyB64,
    mnemonic: wallet.mnemonic.phrase
};

// Cüzdan bilgilerini kaydet
fs.writeFileSync('wallet_info.json', JSON.stringify(walletInfo, null, 2));

// Ekrana yazdır
console.log('\n========== CÜZDAN BİLGİLERİ ==========');
console.log('Ethereum Adresi:', wallet.address);
console.log('Octra Adresi:', octraAddress);
console.log('Private Key (Hex):', wallet.privateKey);
console.log('Private Key (B64):', privateKeyB64);
console.log('Mnemonic:', wallet.mnemonic.phrase);
console.log('=====================================\n');
console.log('BU BİLGİLERİ GÜVENLİ BİR YERE KAYDEDİN!\n');
EOF

    if [ ! -d "node_modules" ]; then
        echo -e "${YELLOW}Gerekli paketler yükleniyor...${NC}"
        npm init -y &> /dev/null
        npm install ethers &> /dev/null
    fi
    
    node create_wallet.js
    
    if [ -f "wallet_info.json" ]; then
        PRIVATE_KEY_B64=$(cat wallet_info.json | jq -r '.privateKeyB64')
        OCTRA_ADDRESS=$(cat wallet_info.json | jq -r '.octraAddress')
        
        echo -e "${GREEN}✓ Cüzdan başarıyla oluşturuldu!${NC}"
        echo -e "${YELLOW}Cüzdan bilgileri 'wallet_info.json' dosyasına kaydedildi${NC}"
        
        export WALLET_PRIVATE_KEY_B64="$PRIVATE_KEY_B64"
        export WALLET_OCTRA_ADDRESS="$OCTRA_ADDRESS"
        
        echo -e "${CYAN}Faucet almak için bu adresi kullanın: ${GREEN}$OCTRA_ADDRESS${NC}"
        echo -e "${YELLOW}Faucet sitesi: https://faucet.octra.xyz${NC}"
        echo ""
        read -p "Faucet aldıktan sonra devam etmek için ENTER'a basın..."
    else
        echo -e "${RED}Cüzdan oluşturma başarısız!${NC}"
        exit 1
    fi
}

setup_octra_cli() {
    echo -e "${YELLOW}Octra CLI kuruluyor...${NC}"
    
    if [ ! -d "octra_pre_client" ]; then
        git clone https://github.com/octra-labs/octra_pre_client.git &> /dev/null
    fi
    
    cd octra_pre_client
    
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    
    cp wallet.json.example wallet.json
    
    if [ ! -z "$WALLET_PRIVATE_KEY_B64" ] && [ ! -z "$WALLET_OCTRA_ADDRESS" ]; then
        echo -e "${YELLOW}Cüzdan bilgileri otomatik olarak yapılandırılıyor...${NC}"
        sed -i "s/private-key-here/$WALLET_PRIVATE_KEY_B64/g" wallet.json
        sed -i "s/octxxxxxxxx/$WALLET_OCTRA_ADDRESS/g" wallet.json
    else
        echo -e "${YELLOW}Lütfen cüzdan bilgilerinizi girin:${NC}"
        read -p "Private key'inizi girin (B64 formatında): " PRIVATE_KEY
        read -p "Octra adresinizi girin (oct... ile başlayan): " OCTRA_ADDRESS
        
        sed -i "s/private-key-here/$PRIVATE_KEY/g" wallet.json
        sed -i "s/octxxxxxxxx/$OCTRA_ADDRESS/g" wallet.json
    fi
    
    echo -e "${GREEN}✓ Octra CLI yapılandırıldı${NC}"
    cd ..
}

auto_transaction() {
    echo -e "${YELLOW}Otomatik işlem gönderici hazırlanıyor...${NC}"
    
    cd octra_pre_client
    source venv/bin/activate
    
    cat > auto_tx.py << 'EOF'
import time
import random
import json
import subprocess
import sys
import os

# CLI komutlarını çalıştır
def run_cli_command(command):
    try:
        # CLI'yi subprocess olarak çalıştır
        process = subprocess.Popen(
            ['python3', 'cli.py'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True
        )
        
        # Komutları gönder
        output, error = process.communicate(input=command)
        
        if process.returncode == 0:
            return True, output
        else:
            return False, error
    except Exception as e:
        return False, str(e)

def encrypt_balance():
    print("Balance şifreleniyor...")
    success, result = run_cli_command("1\n")  # 1 = Encrypt balance
    if success:
        print("✓ Balance şifrelendi")
    else:
        print(f"✗ Balance şifreleme hatası: {result}")
    time.sleep(2)
    return success

def send_private_transaction(to_address):
    print(f"Private transaction gönderiliyor: {to_address}")
    # 2 = Send private transaction, sonra adres, sonra miktar
    command = f"2\n{to_address}\n0.001\n"  
    success, result = run_cli_command(command)
    if success:
        print("✓ Transaction gönderildi")
    else:
        print(f"✗ Transaction hatası: {result}")
    return success

def main():
    transaction_count = 0
    
    # İlk önce balance'ı şifrele
    print("\n[İlk çalıştırma] Balance şifreleniyor...")
    encrypt_balance()
    time.sleep(5)
    
    # Transaction gönderilecek adresler
    addresses = [
        "octBvPDeFCaAZtfr3SBr7Jn6nnWnUuCfAZfgCmaqswV8YR5",
        # Buraya daha fazla adres ekleyebilirsiniz
    ]
    
    while True:
        try:
            # İşlemler arası rastgele bekleme (5-15 dakika)
            delay = random.randint(300, 900)
            
            print(f"\n[{time.strftime('%Y-%m-%d %H:%M:%S')}] İşlem #{transaction_count + 1} başlatılıyor")
            
            # Rastgele bir adres seç
            to_address = random.choice(addresses)
            
            # Her 10 işlemde bir balance'ı yeniden şifrele
            if transaction_count % 10 == 0 and transaction_count > 0:
                print("Balance yeniden şifreleniyor...")
                encrypt_balance()
                time.sleep(5)
            
            # Transaction gönder
            if send_private_transaction(to_address):
                transaction_count += 1
                print(f"Toplam gönderilen işlem: {transaction_count}")
            
            print(f"Sonraki işlem için {delay} saniye ({delay//60} dakika) bekleniyor...")
            time.sleep(delay)
            
        except KeyboardInterrupt:
            print("\nOtomatik işlem gönderici durduruluyor...")
            sys.exit(0)
        except Exception as e:
            print(f"Beklenmeyen hata: {e}")
            print("60 saniye sonra tekrar denenecek...")
            time.sleep(60)

if __name__ == "__main__":
    main()
EOF
    
    echo -e "${GREEN}✓ Otomatik işlem gönderici oluşturuldu${NC}"
    cd ..
}

run_in_screen() {
    echo -e "${YELLOW}Octra testnet screen oturumunda başlatılıyor...${NC}"
    
    screen -S octra -X quit 2>/dev/null || true
    
    screen -dmS octra bash -c "cd octra_pre_client && source venv/bin/activate && python3 auto_tx.py"
    
    echo -e "${GREEN}✓ Octra testnet 'octra' screen oturumunda çalışıyor${NC}"
    echo -e "${CYAN}Komutlar:${NC}"
    echo -e "  Logları görüntüle: ${YELLOW}screen -r octra${NC}"
    echo -e "  Oturumdan çık: ${YELLOW}Ctrl+A, sonra D${NC}"
    echo -e "  Durdur: ${YELLOW}screen -S octra -X quit${NC}"
}

update_cli() {
    echo -e "${YELLOW}Octra CLI güncelleniyor...${NC}"
    
    cd octra_pre_client
    
    cp wallet.json ../wallet.json.backup
    
    git stash &> /dev/null
    git pull origin main &> /dev/null
    
    cp ../wallet.json.backup wallet.json
    
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
                # check_root - Devre dışı
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
