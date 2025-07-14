#!/bin/bash

# UFUK DEGEN TARAFINDAN HAZIRLANDI

set -e

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Banner
show_banner() {
    clear
    echo -e "${PURPLE}╔════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║   UFUK DEGEN TARAFINDAN HAZIRLANDI     ║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Yükleme animasyonu
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

# IP adresini al
get_ip_address() {
    PUBLIC_IP=$(curl -s ifconfig.me || curl -s icanhazip.com || curl -s ipinfo.io/ip || echo "IP_BULUNAMADI")
    echo "$PUBLIC_IP"
}

# Bağımlılıkları yükle
install_dependencies() {
    echo -e "${YELLOW}Bağımlılıklar yükleniyor...${NC}"
    {
        sudo apt update && sudo apt upgrade -y
        sudo apt install htop ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev tmux iptables curl nvme-cli git wget make jq libleveldb-dev build-essential pkg-config ncdu tar clang bsdmainutils lsb-release libssl-dev libreadline-dev libffi-dev jq gcc screen file nano btop unzip lz4 python3 python3-pip python3-venv -y
    } &> /dev/null &
    loading $!
    echo -e "${GREEN}✓ Bağımlılıklar yüklendi${NC}"
}

# CLI kurulumu
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
    read -p "Private key (B64): " PRIVATE_KEY
    read -p "Octra adresiniz (oct...): " OCTRA_ADDRESS

    echo '{
  "priv": "'"${PRIVATE_KEY}"'",
  "addr": "'"${OCTRA_ADDRESS}"'",
  "rpc": "https://octra.network"
}' > wallet.json

    echo -e "${GREEN}✓ Octra CLI yapılandırıldı${NC}"
    cd ..
}

# CLI başlat
start_octra_cli() {
    echo -e "${GREEN}Screen oturumu başlatılıyor...${NC}"
    cd octra_pre_client
    screen -S octra -dm bash -c "source venv/bin/activate && python3 cli.py"
    sleep 2
    screen -r octra
    cd ..
}

# CLI güncelleme
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

    echo -e "${GREEN}✓ CLI güncellendi${NC}"
    cd ..
}

# Ana menü
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}Bir seçenek seçin:${NC}"
        echo "1) Bağımlılıkları yükle"
        echo "2) CLI kurulumu ve yapılandırması"
        echo "3) CLI arayüzünü başlat"
        echo "4) CLI güncelle"
        echo "5) Çıkış"
        echo ""
        read -p "Seçiminizi girin [1-5]: " choice

        case $choice in
            1)
                install_dependencies
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            2)
                setup_octra_cli
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            3)
                start_octra_cli
                ;;
            4)
                update_cli
                read -p "Devam etmek için ENTER'a basın..."
                ;;
            5)
                echo -e "${GREEN}Görüşmek üzere!${NC}"
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
