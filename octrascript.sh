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

detect_system() {
    if grep -qi microsoft /proc/version; then
        echo "WSL"
    else
        echo "VPS"
    fi
}

get_ip_address() {
    SYSTEM_TYPE=$(detect_system)
    if [ "$SYSTEM_TYPE" == "WSL" ]; then
        echo "localhost"
    else
        curl -s ifconfig.me || curl -s icanhazip.com || echo "IP_ALINAMADI"
    fi
}

install_dependencies() {
    echo -e "${YELLOW}Bağımlılıklar yükleniyor...${NC}"
    {
        sudo apt update && sudo apt upgrade -y
        sudo apt install htop ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev build-essential pkg-config ncdu tar clang bsdmainutils lsb-release libssl-dev libreadline-dev libffi-dev jq gcc screen file nano btop unzip lz4 python3 python3-pip python3-venv -y
    } &> /dev/null &
    loading $!
    echo -e "${GREEN}✓ Bağımlılıklar yüklendi${NC}"
}

generate_wallet() {
    echo -e "${YELLOW}Cüzdan oluşturucu kuruluyor...${NC}"

    if [ ! -d "wallet-gen" ]; then
        git clone https://github.com/0xmoei/wallet-gen.git &> /dev/null
    fi

    cd wallet-gen
    chmod +x ./start.sh
    ./start.sh &> /dev/null &
    WALLET_PID=$!

    SYSTEM_TYPE=$(detect_system)
    IP_ADDRESS=$(get_ip_address)

    echo ""
    echo -e "${CYAN}Cüzdan oluşturucu başlatıldı!${NC}"

    if [ "$SYSTEM_TYPE" == "WSL" ]; then
        echo -e "${GREEN}Tarayıcınıza şu adresi yazın: ${YELLOW}http://localhost:8888${NC}"
    else
        echo -e "${GREEN}Tarayıcınıza şu adresi yazın: ${YELLOW}http://${IP_ADDRESS}:8888${NC}"
    fi

    echo ""
    echo -e "${CYAN}Adımlar:${NC}"
    echo -e "→ Tarayıcıdan yukarıdaki adrese gir"
    echo -e "→ 'Generate Wallet' butonuna bas"
    echo -e "→ Tüm bilgileri bir yere kaydet"
    echo -e "→ Dilersen: ${YELLOW}cat dosya.txt${NC} komutuyla bilgileri tekrar görebilirsin"
    echo ""
    echo -e "${YELLOW}İşin bitince CLI'de ${RED}CTRL + C${YELLOW} ile çıkabilirsin.${NC}"
    echo ""
    read -p "Devam etmek için ENTER'a bas..."
    kill $WALLET_PID 2>/dev/null || true
    cd ..
}

setup_octra_cli() {
    echo -e "${YELLOW}Octra CLI kuruluyor...${NC}"

    if [ ! -d "octra_pre_client" ]; then
        git clone https://github.com/octra-labs/octra_pre_client.git || {
            echo -e "${RED}Octra CLI klonlama başarısız!${NC}"
            exit 1
        }
    fi

    cd octra_pre_client
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null

    cp wallet.json.example wallet.json

    echo -e "${YELLOW}Cüzdan bilgilerinizi girin:${NC}"
    read -p "Private Key (B64): " PRIVATE_KEY
    read -p "Octra adresiniz (oct...): " OCTRA_ADDRESS

    echo '{
  "priv": "'"${PRIVATE_KEY}"'",
  "addr": "'"${OCTRA_ADDRESS}"'",
  "rpc": "https://octra.network"
}' > wallet.json

    echo -e "${GREEN}✓ CLI yapılandırıldı${NC}"
    cd ..
}

start_octra_cli() {
    echo -e "${YELLOW}Octra CLI başlatılıyor...${NC}"
    cd octra_pre_client

    if screen -list | grep -q "octra"; then
        echo -e "${GREEN}Mevcut screen oturumu bulundu, bağlanılıyor...${NC}"
        screen -r octra
    else
        echo -e "${GREEN}Yeni screen oturumu başlatılıyor...${NC}"
        screen -S octra -dm bash -c "source venv/bin/activate && python3 cli.py"
        sleep 2
        screen -r octra
    fi

    cd ..
}

update_cli() {
    echo -e "${YELLOW}CLI güncelleniyor...${NC}"
    cd octra_pre_client
    cp wallet.json ../wallet.json.backup
    git stash &> /dev/null
    git pull origin main &> /dev/null
    cp ../wallet.json.backup wallet.json
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    echo -e "${GREEN}✓ CLI güncellendi${NC}"
    cd ..
}

main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Bir seçenek seçin:${NC}"
        echo "1) Tüm kurulumu yap (bağımlılıklar + cüzdan + CLI)"
        echo "2) Sadece cüzdan oluştur"
        echo "3) Sadece CLI kur ve yapılandır"
        echo "4) CLI arayüzünü başlat"
        echo "5) CLI güncelle"
        echo "6) Çıkış"
        echo ""
        read -p "Seçiminizi girin [1-6]: " choice

        case $choice in
            1)
                install_dependencies
                generate_wallet
                setup_octra_cli
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
                start_octra_cli
                ;;
            5)
                update_cli
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            6)
                echo -e "${GREEN}Görüşürüz!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Geçersiz giriş!${NC}"
                sleep 1
                ;;
        esac
    done
}

main_menu
