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

# Sistem türünü tespit et
detect_system() {
    if grep -qi microsoft /proc/version; then
        echo "WSL"
    else
        echo "VPS"
    fi
}

# IP adresini al
get_ip_address() {
    SYSTEM_TYPE=$(detect_system)
    
    if [ "$SYSTEM_TYPE" == "WSL" ]; then
        echo "localhost"
    else
        # VPS için public IP'yi al
        PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip || echo "IP_BULUNAMADI")
        echo "$PUBLIC_IP"
    fi
}

install_dependencies() {
    echo -e "${YELLOW}Bağımlılıklar yükleniyor...${NC}"
    {
        sudo apt update && sudo apt upgrade -y
        sudo apt install screen curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev python3 python3-pip python3-venv python3-dev -y
    } &> /dev/null &
    loading $!
    echo -e "${GREEN}✓ Bağımlılıklar yüklendi${NC}"
}

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

generate_wallet() {
    echo -e "${YELLOW}Cüzdan oluşturucu hazırlanıyor...${NC}"
    
    SYSTEM_TYPE=$(detect_system)
    IP_ADDRESS=$(get_ip_address)
    
    if [ ! -d "wallet-gen" ]; then
        git clone https://github.com/0xmoei/wallet-gen.git &> /dev/null
    fi
    
    cd wallet-gen
    chmod +x ./start.sh
    ./start.sh &> /dev/null &
    WALLET_PID=$!
    
    echo -e "${CYAN}Cüzdan oluşturucu çalışıyor...${NC}"
    echo ""
    
    if [ "$SYSTEM_TYPE" == "WSL" ]; then
        echo -e "${YELLOW}WSL kullanıcısı tespit edildi!${NC}"
        echo -e "${GREEN}Tarayıcınızda şu adrese gidin: http://localhost:8888${NC}"
    else
        echo -e "${YELLOW}VPS kullanıcısı tespit edildi!${NC}"
        echo -e "${GREEN}Tarayıcınızda şu adrese gidin: http://${IP_ADDRESS}:8888${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Cüzdan oluşturma adımları:${NC}"
    echo -e "1. Yukarıdaki adresi tarayıcınızda açın"
    echo -e "2. 'GENERATE NEW WALLET' butonuna tıklayın"
    echo -e "3. Tüm cüzdan bilgilerini kaydedin"
    echo -e "4. Faucet alın: ${GREEN}https://faucet.octra.xyz${NC}"
    echo ""
    read -p "Cüzdan bilgilerinizi kaydettikten sonra ENTER'a basın..."
    
    kill $WALLET_PID 2>/dev/null || true
    cd ..
}

setup_octra_cli() {
    echo -e "${YELLOW}Octra CLI kuruluyor...${NC}"
    
    if [ ! -d "octra_pre_client" ]; then
        git clone https://github.com/octra-labs/octra_pre_client.git || {
            echo -e "${RED}Octra CLI klonlama başarısız oldu!${NC}"
            exit 1
        }
    fi
    
    cd octra_pre_client
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    
    cp wallet.json.example wallet.json
    
    echo -e "${YELLOW}Lütfen cüzdan bilgilerinizi girin:${NC}"
    read -p "Private key (B64 formatında): " PRIVATE_KEY
    read -p "Octra adresiniz (oct... ile başlayan): " OCTRA_ADDRESS
    
    sed -i "s/private-key-here/$PRIVATE_KEY/g" wallet.json
    sed -i "s/octxxxxxxxx/$OCTRA_ADDRESS/g" wallet.json
    
    echo -e "${GREEN}✓ Octra CLI yapılandırıldı${NC}"
    cd ..
}

open_testnet_interface() {
    echo -e "${YELLOW}Octra Testnet arayüzü açılıyor...${NC}"
    
    if [ ! -d "octra_pre_client" ]; then
        echo -e "${RED}Octra CLI kurulu değil! Önce kurulum yapın (seçenek 1).${NC}"
        read -p "Devam etmek için ENTER'a basın..."
        return
    fi
    
    if screen -list | grep -q "\.octra"; then
        echo -e "${CYAN}Mevcut screen oturumuna bağlanılıyor...${NC}"
        screen -r octra
    else
        echo -e "${GREEN}Yeni screen oturumu oluşturuluyor...${NC}"
        cd octra_pre_client
        screen -dmS octra
        screen -S octra -X stuff "source venv/bin/activate\n"
        screen -S octra -X stuff "python3 cli.py\n"
        sleep 1
        screen -r octra
    fi
}

update_cli() {
    echo -e "${YELLOW}Octra CLI güncelleniyor...${NC}"
    
    if [ ! -d "octra_pre_client" ]; then
        echo -e "${RED}Octra CLI kurulu değil!${NC}"
        return
    fi
    
    cd octra_pre_client
    cp wallet.json ../wallet.json.backup
    git stash &> /dev/null
    git pull origin main &> /dev/null
    cp ../wallet.json.backup wallet.json
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    
    echo -e "${GREEN}✓ Octra CLI güncellendi${NC}"
    cd ..
}

main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Bir seçenek seçin:${NC}"
        echo "1) Tam kurulum"
        echo "2) Cüzdan oluştur"
        echo "3) Testnet arayüzüne git"
        echo "4) CLI güncelle"
        echo "5) Çıkış"
        echo ""
        read -p "Seçiminizi girin [1-5]: " choice

        case $choice in
            1)
                install_dependencies
                install_nodejs
                generate_wallet
                setup_octra_cli
                echo -e "${GREEN}Kurulum tamamlandı!${NC}"
                echo -e "${YELLOW}Testnet arayüzüne gitmek için 3'ü seçin${NC}"
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            2)
                generate_wallet
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            3)
                open_testnet_interface
                ;;
            4)
                update_cli
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            5)
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
