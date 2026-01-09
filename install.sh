#!/bin/bash

# ============================================
# 42 Package Installer - Ana Script
# ============================================

# Script'in bulunduğu dizini al
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Helper fonksiyonları yükle
source "${SCRIPT_DIR}/utils/helpers.sh"

# ============================================
# Konfigürasyon
# ============================================

BANNER_FILE="${SCRIPT_DIR}/Banners/welcome.txt"
PACKAGES_DIR="${SCRIPT_DIR}/packages"

# Paket seçimleri
declare -A SELECTIONS

# ============================================
# Ana Fonksiyonlar
# ============================================

show_welcome() {
    clear
    show_banner "$BANNER_FILE"
    echo ""
}

ask_package_questions() {
    print_section "📦 Paket Seçimi"
    
    local total=5
    local current=0
    
    # Soru 1: Oh-my-zsh
    ((current++))
    if ask_numbered_question $current $total "Oh-my-zsh kurmak istiyor musun?"; then
        SELECTIONS["oh_my_zsh"]=true
        INSTALLED_PACKAGES+=("Oh-my-zsh")
    else
        SELECTIONS["oh_my_zsh"]=false
        SKIPPED_PACKAGES+=("Oh-my-zsh")
    fi
    
    # Soru 2: 42 Vim
    ((current++))
    if ask_numbered_question $current $total "42 Package vim indirecek misin?"; then
        SELECTIONS["vim_42"]=true
        INSTALLED_PACKAGES+=("42 Package Vim")
    else
        SELECTIONS["vim_42"]=false
        SKIPPED_PACKAGES+=("42 Package Vim")
    fi
    
    # Soru 3: Terminal Banner
    ((current++))
    if ask_numbered_question $current $total "Kişisel terminal banner'ı kullanacak mısın?"; then
        SELECTIONS["terminal_banner"]=true
        INSTALLED_PACKAGES+=("Terminal Banner")
    else
        SELECTIONS["terminal_banner"]=false
        SKIPPED_PACKAGES+=("Terminal Banner")
    fi
    
    # Soru 4: 42 Directory Shortcuts
    ((current++))
    if ask_numbered_question $current $total "42 directory kısayolları ister misin? (Proje oluşturma vb. komutlar)"; then
        SELECTIONS["directory_shortcuts"]=true
        INSTALLED_PACKAGES+=("42 Directory Kısayolları")
    else
        SELECTIONS["directory_shortcuts"]=false
        SKIPPED_PACKAGES+=("42 Directory Kısayolları")
    fi
    
    # Soru 5: Default Makefile Template
    ((current++))
    if ask_numbered_question $current $total "Default Makefile template ister misin?"; then
        SELECTIONS["makefile_template"]=true
        INSTALLED_PACKAGES+=("Makefile Template")
    else
        SELECTIONS["makefile_template"]=false
        SKIPPED_PACKAGES+=("Makefile Template")
    fi
}

run_installations() {
    print_section "🚀 Kurulum"
    
    # Şimdilik sadece mesaj göster (gerçek kurulum sonra eklenecek)
    if [[ "${SELECTIONS["oh_my_zsh"]}" == true ]]; then
        print_info "Oh-my-zsh kurulumu yapılacak..."
        # source "${PACKAGES_DIR}/oh_my_zsh.sh"
        print_success "Oh-my-zsh (simülasyon)"
    fi
    
    if [[ "${SELECTIONS["vim_42"]}" == true ]]; then
        print_info "42 Package Vim kurulumu yapılacak..."
        # source "${PACKAGES_DIR}/vim_42.sh"
        print_success "42 Package Vim (simülasyon)"
    fi
    
    if [[ "${SELECTIONS["terminal_banner"]}" == true ]]; then
        print_info "Terminal Banner kurulumu yapılacak..."
        # source "${PACKAGES_DIR}/terminal_banner.sh"
        print_success "Terminal Banner (simülasyon)"
    fi
    
    if [[ "${SELECTIONS["directory_shortcuts"]}" == true ]]; then
        print_info "42 Directory kısayolları kurulumu yapılacak..."
        # source "${PACKAGES_DIR}/directory_shortcuts.sh"
        print_success "42 Directory Kısayolları (simülasyon)"
    fi
    
    if [[ "${SELECTIONS["makefile_template"]}" == true ]]; then
        print_info "Makefile template kurulumu yapılacak..."
        # source "${PACKAGES_DIR}/makefile_template.sh"
        print_success "Makefile Template (simülasyon)"
    fi
}

show_completion() {
    show_summary
    
    print_separator
    echo ""
    echo -e "${GREEN}${BOLD}    🎉 İşlem tamamlandı! 🎉${NC}"
    echo ""
    print_separator
    echo ""
}

# ============================================
# Ana Program
# ============================================

main() {
    show_welcome
    ask_package_questions
    run_installations
    show_completion
}

# Script'i çalıştır
main
