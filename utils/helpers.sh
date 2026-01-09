#!/bin/bash

# ============================================
# 42 Package Installer - Helper Functions
# ============================================

# Renk tanımlamaları
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color (Reset)

# Bold versiyonlar
BOLD='\033[1m'
RESET='\033[0m'

# ============================================
# Mesaj Fonksiyonları
# ============================================

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_skip() {
    echo -e "${YELLOW}⏭${NC} $1"
}

# ============================================
# Kullanıcı Etkileşimi
# ============================================

# Evet/Hayır sorusu sor
# Kullanım: ask_yes_no "Soru metni"
# Return: 0 = Evet, 1 = Hayır
ask_yes_no() {
    local question="$1"
    local answer
    
    while true; do
        echo -ne "${CYAN}${question}${NC} ${WHITE}(e/h):${NC} "
        read -r answer
        case "$answer" in
            [eEyY]|[eE][vV][eE][tT]|[yY][eE][sS])
                return 0
                ;;
            [hHnN]|[hH][aA][yY][iI][rR]|[nN][oO])
                return 1
                ;;
            *)
                print_warning "Lütfen 'e' (evet) veya 'h' (hayır) girin."
                ;;
        esac
    done
}

# Numaralı soru sor
# Kullanım: ask_numbered_question 1 5 "Soru metni"
ask_numbered_question() {
    local current="$1"
    local total="$2"
    local question="$3"
    
    echo -ne "${PURPLE}[${current}/${total}]${NC} "
    ask_yes_no "$question"
    return $?
}

# ============================================
# Banner Fonksiyonları
# ============================================

# Banner dosyasını oku ve göster
show_banner() {
    local banner_file="$1"
    
    if [[ -f "$banner_file" ]]; then
        echo -e "${CYAN}"
        cat "$banner_file"
        echo -e "${NC}"
    else
        print_error "Banner dosyası bulunamadı: $banner_file"
    fi
}

# Ayırıcı çizgi
print_separator() {
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════${NC}"
}

# Bölüm başlığı
print_section() {
    echo ""
    print_separator
    echo -e "${BOLD}${WHITE}  $1${NC}"
    print_separator
    echo ""
}

# ============================================
# Yardımcı Fonksiyonlar
# ============================================

# Script'in çalıştığı dizini al
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
}

# Paket kurulu mu kontrol et
is_installed() {
    command -v "$1" &> /dev/null
}

# Özet listesi için array
declare -a INSTALLED_PACKAGES
declare -a SKIPPED_PACKAGES

# Kurulum özetini göster
show_summary() {
    echo ""
    print_section "📋 Kurulum Özeti"
    
    if [[ ${#INSTALLED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "${GREEN}Kurulacak paketler:${NC}"
        for pkg in "${INSTALLED_PACKAGES[@]}"; do
            echo -e "  ${GREEN}✓${NC} $pkg"
        done
    fi
    
    if [[ ${#SKIPPED_PACKAGES[@]} -gt 0 ]]; then
        echo -e "\n${YELLOW}Atlanan paketler:${NC}"
        for pkg in "${SKIPPED_PACKAGES[@]}"; do
            echo -e "  ${YELLOW}⏭${NC} $pkg"
        done
    fi
    
    echo ""
}
