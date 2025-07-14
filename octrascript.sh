#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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
    local spinstr='|/-\\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
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
    if [ ! -d "wallet-gen" ]; then
        git clone https://github.com/0xmoei/wallet-gen.git &> /dev/null
    fi
    cd wallet-gen
    chmod +x ./start.sh
    ./start.sh &> /dev/null &
    WALLET_PID=$!
    echo -e "${CYAN}Cüzdan oluşturucu çalışıyor...${NC}"
    echo -e "${YELLOW}Tarayıcıdan aç: ${GREEN}http://localhost:8888${NC}"
    read -p "Cüzdan bilgilerinizi kaydettikten sonra ENTER'a basın..."
    kill $WALLET_PID 2>/dev/null || true
    cd ..
}

setup_octra_cli() {
    echo -e "${YELLOW}Octra CLI kuruluyor...${NC}"
    if [ ! -d "octra_pre_client" ]; then
        git clone https://github.com/octra-labs/octra_pre_client.git || {
            echo -e "${RED}Klonlama başarısız oldu!${NC}"
            exit 1
        }
    fi
    cd octra_pre_client
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt &> /dev/null
    cp wallet.json.example wallet.json
    echo -e "${YELLOW}Cüzdan bilgilerinizi girin:${NC}"
    read -p "Private Key (Base64): " PRIVATE_KEY
    read -p "Octra Adresi (oct...): " OCTRA_ADDRESS
    sed -i "s/private-key-here/$PRIVATE_KEY/g" wallet.json
    sed -i "s/octxxxxxxxx/$OCTRA_ADDRESS/g" wallet.json
    echo -e "${GREEN}✓ Octra CLI yapılandırıldı${NC}"
    cd ..
}

open_testnet_interface() {
    echo -e "${YELLOW}Octra Testnet arayüzü açılıyor...${NC}"
    if [ ! -d "octra_pre_client" ]; then
        echo -e "${RED}octra_pre_client dizini yok. Önce CLI kurun.${NC}"
        return
    fi
    if [ ! -f "octra_pre_client/run.sh" ]; then
        echo -e "${RED}run.sh dosyası bulunamadı!${NC}"
        echo -e "${YELLOW}CLI güncellemeyi deneyin (seçenek 4)${NC}"
        read -p "Devam etmek için ENTER'a basın..."
        return
    fi
    screen -S octra -X quit 2>/dev/null
    cd octra_pre_client
    chmod +x run.sh
    screen -dmS octra bash -c "source venv/bin/activate && ./run.sh"
    sleep 1
    screen -r octra
    cd ..
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
            1) install_dependencies; install_nodejs; generate_wallet; setup_octra_cli; read -p "ENTER..." ;;
            2) generate_wallet; read -p "ENTER..." ;;
            3) open_testnet_interface ;;
            4) update_cli; read -p "ENTER..." ;;
            5) echo -e "${GREEN}Güle güle!${NC}"; exit 0 ;;
            *) echo -e "${RED}Geçersiz!${NC}"; sleep 2 ;;
        esac
    done
}

main_menu
