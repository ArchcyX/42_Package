#!/bin/bash

#===============================================================================
#  w7h3r-NeovimConfig Kurulum Scripti
#  Ecole 42 bilgisayarları için (sudo gerektirmez)
#===============================================================================

set -e

# Dizinler
HOME_BIN="$HOME/bin"
HOME_LOCAL="$HOME/.local"
NVIM_CONFIG="$HOME/.config/nvim"
TMP_DIR="$HOME/tmp/nvim-install-$$"

# Sürümler
NVIM_VERSION="0.10.2"
RIPGREP_VERSION="14.1.0"
FD_VERSION="10.2.0"
NODE_VERSION="20.18.0"

# Renkler
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

print_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║       w7h3r-NeovimConfig - 42 Kurulum Scripti                ║"
    echo "║       sudo gerektirmez - Tüm araçlar \$HOME'a kurulur        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() { echo -e "\n${BLUE}[▶]${NC} ${BOLD}$1${NC}"; }
print_substep() { echo -e "    ${CYAN}→${NC} $1"; }
print_success() { echo -e "${GREEN}[✓]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[! ]${NC} $1"; }
print_error() { echo -e "${RED}[✗]${NC} $1"; }

cleanup() {
    rm -rf "$TMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

download_file() {
    local url="$1"
    local output="$2"
    local description="$3"
    
    print_substep "$description indiriliyor..."
    
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL --connect-timeout 30 --max-time 600 -o "$output" "$url" 2>/dev/null; then
            return 0
        fi
        if curl -fsSLk --connect-timeout 30 --max-time 600 -o "$output" "$url" 2>/dev/null; then
            return 0
        fi
    fi
    
    if command -v wget >/dev/null 2>&1; then
        if wget -q --timeout=30 -O "$output" "$url" 2>/dev/null; then
            return 0
        fi
        if wget -q --no-check-certificate --timeout=30 -O "$output" "$url" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

detect_os() {
    print_step "Sistem tespit ediliyor..."
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Desteklenmeyen işletim sistemi:  $OSTYPE"
        exit 1
    fi
    
    ARCH=$(uname -m)
    print_success "Sistem: $OS ($ARCH)"
}

create_directories() {
    print_step "Dizinler oluşturuluyor..."
    
    mkdir -p "$HOME_BIN"
    mkdir -p "$HOME_LOCAL/bin"
    mkdir -p "$HOME_LOCAL/lib"
    mkdir -p "$HOME_LOCAL/share"
    mkdir -p "$HOME/. config"
    mkdir -p "$HOME/. cache"
    mkdir -p "$TMP_DIR"
    
    print_success "Dizinler hazır"
}

setup_path() {
    print_step "PATH ayarlanıyor..."
    
    local PATH_LINE='export PATH="$HOME/bin:$HOME/. local/bin:$PATH"'
    
    for rc in "$HOME/.bashrc" "$HOME/. zshrc"; do
        if [ -f "$rc" ] || [ "$(basename "$rc")" = ".bashrc" ]; then
            touch "$rc"
            if !  grep -q 'HOME/bin' "$rc" 2>/dev/null; then
                echo "" >> "$rc"
                echo "# Neovim ve araçlar için PATH" >> "$rc"
                echo "$PATH_LINE" >> "$rc"
            fi
        fi
    done
    
    export PATH="$HOME/bin:$HOME/. local/bin:$PATH"
    print_success "PATH ayarlandı"
}

install_neovim() {
    print_step "Neovim kuruluyor..."
    
    if [ -f "$HOME_BIN/nvim" ] && "$HOME_BIN/nvim" --version >/dev/null 2>&1; then
        if [ -d "$HOME_LOCAL/share/nvim/runtime" ]; then
            local ver=$("$HOME_BIN/nvim" --version | head -n1)
            print_success "Neovim zaten kurulu: $ver"
            return 0
        fi
    fi
    
    print_substep "Eski kurulum temizleniyor..."
    rm -rf "$HOME_LOCAL/bin/nvim"
    rm -rf "$HOME_LOCAL/lib/nvim"
    rm -rf "$HOME_LOCAL/share/nvim/runtime"
    rm -f "$HOME_BIN/nvim"
    
    cd "$TMP_DIR"
    
    local url=""
    local archive=""
    
    if [[ "$OS" == "linux" && "$ARCH" == "x86_64" ]]; then
        url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-linux64.tar.gz"
        archive="nvim-linux64.tar.gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "x86_64" ]]; then
        url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-macos-x86_64.tar.gz"
        archive="nvim-macos. tar.gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "arm64" ]]; then
        url="https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim-macos-arm64.tar.gz"
        archive="nvim-macos. tar.gz"
    else
        print_error "Bu sistem için Neovim binary'si yok:  $OS $ARCH"
        exit 1
    fi
    
    if !  download_file "$url" "$archive" "Neovim v${NVIM_VERSION}"; then
        print_error "Neovim indirilemedi!"
        exit 1
    fi
    
    print_substep "Arşiv çıkartılıyor..."
    tar -xzf "$archive"
    
    local extract_dir=$(ls -d nvim-* 2>/dev/null | head -n1)
    
    if [ !  -d "$extract_dir" ]; then
        print_error "Çıkartma başarısız!"
        exit 1
    fi
    
    print_substep "Dosyalar kopyalanıyor (bin, lib, share)..."
    cp -r "$extract_dir"/* "$HOME_LOCAL/"
    
    ln -sf "$HOME_LOCAL/bin/nvim" "$HOME_BIN/nvim"
    
    if "$HOME_BIN/nvim" --version >/dev/null 2>&1; then
        print_success "Neovim kuruldu:  $("$HOME_BIN/nvim" --version | head -n1)"
    else
        print_error "Neovim çalıştırılamadı!"
        exit 1
    fi
}

install_ripgrep() {
    print_step "Ripgrep kuruluyor..."
    
    if [ -f "$HOME_BIN/rg" ] || command -v rg >/dev/null 2>&1; then
        print_success "Ripgrep zaten kurulu"
        return 0
    fi
    
    cd "$TMP_DIR"
    
    local url=""
    local archive="ripgrep. tar.gz"
    
    if [[ "$OS" == "linux" && "$ARCH" == "x86_64" ]]; then
        url="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "x86_64" ]]; then
        url="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-x86_64-apple-darwin.tar. gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "arm64" ]]; then
        url="https://github.com/BurntSushi/ripgrep/releases/download/${RIPGREP_VERSION}/ripgrep-${RIPGREP_VERSION}-aarch64-apple-darwin.tar.gz"
    else
        print_warning "Bu sistem için ripgrep yok"
        return 0
    fi
    
    if download_file "$url" "$archive" "Ripgrep"; then
        tar -xzf "$archive"
        find .  -name "rg" -type f -exec cp {} "$HOME_BIN/" \;
        chmod +x "$HOME_BIN/rg"
        print_success "Ripgrep kuruldu"
    else
        print_warning "Ripgrep indirilemedi"
    fi
}

install_fd() {
    print_step "fd kuruluyor..."
    
    if [ -f "$HOME_BIN/fd" ] || command -v fd >/dev/null 2>&1; then
        print_success "fd zaten kurulu"
        return 0
    fi
    
    cd "$TMP_DIR"
    
    local url=""
    local archive="fd. tar.gz"
    
    if [[ "$OS" == "linux" && "$ARCH" == "x86_64" ]]; then
        url="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "x86_64" ]]; then
        url="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-x86_64-apple-darwin.tar.gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "arm64" ]]; then
        url="https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/fd-v${FD_VERSION}-aarch64-apple-darwin.tar.gz"
    else
        print_warning "Bu sistem için fd yok"
        return 0
    fi
    
    if download_file "$url" "$archive" "fd"; then
        tar -xzf "$archive"
        find . -name "fd" -type f -exec cp {} "$HOME_BIN/" \;
        chmod +x "$HOME_BIN/fd"
        print_success "fd kuruldu"
    else
        print_warning "fd indirilemedi"
    fi
}

install_nodejs() {
    print_step "Node.js kuruluyor (Copilot için)..."
    
    if [ -f "$HOME_BIN/node" ] || command -v node >/dev/null 2>&1; then
        print_success "Node.js zaten kurulu"
        return 0
    fi
    
    cd "$TMP_DIR"
    
    local url=""
    local archive=""
    local use_xz=false
    
    if [[ "$OS" == "linux" && "$ARCH" == "x86_64" ]]; then
        url="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz"
        archive="node. tar.xz"
        use_xz=true
    elif [[ "$OS" == "macos" && "$ARCH" == "x86_64" ]]; then
        url="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-darwin-x64.tar.gz"
        archive="node.tar.gz"
    elif [[ "$OS" == "macos" && "$ARCH" == "arm64" ]]; then
        url="https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-darwin-arm64.tar. gz"
        archive="node.tar. gz"
    else
        print_warning "Bu sistem için Node.js yok"
        return 0
    fi
    
    if download_file "$url" "$archive" "Node. js"; then
        if [ "$use_xz" = true ]; then
            xz -d "$archive"
            tar -xf "node. tar"
        else
            tar -xzf "$archive"
        fi
        
        local node_dir=$(ls -d node-v* 2>/dev/null | head -n1)
        if [ -d "$node_dir" ]; then
            cp "$node_dir/bin/node" "$HOME_BIN/"
            cp "$node_dir/bin/npm" "$HOME_BIN/" 2>/dev/null || true
            cp "$node_dir/bin/npx" "$HOME_BIN/" 2>/dev/null || true
            cp -r "$node_dir/lib" "$HOME_LOCAL/" 2>/dev/null || true
            chmod +x "$HOME_BIN/node"
            print_success "Node. js kuruldu"
        fi
    else
        print_warning "Node.js indirilemedi"
    fi
}

backup_config() {
    print_step "Mevcut yapılandırma kontrol ediliyor..."
    
    if [ -d "$NVIM_CONFIG" ]; then
        local backup="$HOME/.config/nvim-backup-$(date +%Y%m%d_%H%M%S)"
        mv "$NVIM_CONFIG" "$backup"
        print_success "Yedek oluşturuldu: $backup"
    fi
    
    echo ""
    read -p "    Eski Neovim verilerini temizlemek ister misiniz? (e/h): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ee]$ ]]; then
        rm -rf "$HOME/. local/share/nvim" 2>/dev/null || true
        rm -rf "$HOME/.local/state/nvim" 2>/dev/null || true
        rm -rf "$HOME/. cache/nvim" 2>/dev/null || true
        print_success "Eski veriler temizlendi"
    fi
}

download_config() {
    print_step "w7h3r-NeovimConfig indiriliyor..."
    
    local REPO_URL="https://github.com/w7h3r/w7h3r-NeovimConfig. git"
    local REPO_TAR="https://github.com/w7h3r/w7h3r-NeovimConfig/archive/refs/heads/main.tar.gz"
    local REPO_ZIP="https://github.com/w7h3r/w7h3r-NeovimConfig/archive/refs/heads/main.zip"
    
    # Eski config'i temizle
    rm -rf "$NVIM_CONFIG"
    mkdir -p "$HOME/.config"
    
    # Yöntem 1: git clone
    if command -v git >/dev/null 2>&1; then
        print_substep "Git ile indiriliyor..."
        
        if git clone --depth 1 "$REPO_URL" "$NVIM_CONFIG" 2>/dev/null; then
            if verify_config; then
                print_success "Config indirildi (git)"
                return 0
            fi
        fi
        
        rm -rf "$NVIM_CONFIG"
        if git -c http.sslVerify=false clone --depth 1 "$REPO_URL" "$NVIM_CONFIG" 2>/dev/null; then
            if verify_config; then
                print_success "Config indirildi (git, SSL atlandı)"
                return 0
            fi
        fi
    fi
    
    # Yöntem 2: tar. gz ile indir
    print_substep "Git başarısız, tar.gz deneniyor..."
    rm -rf "$NVIM_CONFIG"
    cd "$TMP_DIR"
    
    # Önceki indirmeleri temizle
    rm -f config.tar.gz config.zip 2>/dev/null
    rm -rf w7h3r-NeovimConfig-* 2>/dev/null
    
    if download_file "$REPO_TAR" "config.tar.gz" "Config (tar.gz)"; then
        if [ -f "config.tar.gz" ]; then
            tar -xzf config.tar.gz
            local extract_dir=$(ls -d w7h3r-NeovimConfig-* 2>/dev/null | head -n1)
            if [ -d "$extract_dir" ]; then
                mv "$extract_dir" "$NVIM_CONFIG"
                if verify_config; then
                    print_success "Config indirildi (tar. gz)"
                    return 0
                fi
            fi
        fi
    fi
    
    # Yöntem 3: zip ile indir
    print_substep "tar.gz başarısız, zip deneniyor..."
    rm -rf "$NVIM_CONFIG"
    cd "$TMP_DIR"
    rm -rf w7h3r-NeovimConfig-* 2>/dev/null
    
    if command -v unzip >/dev/null 2>&1; then
        if download_file "$REPO_ZIP" "config.zip" "Config (zip)"; then
            if [ -f "config.zip" ]; then
                unzip -q config.zip
                local extract_dir=$(ls -d w7h3r-NeovimConfig-* 2>/dev/null | head -n1)
                if [ -d "$extract_dir" ]; then
                    mv "$extract_dir" "$NVIM_CONFIG"
                    if verify_config; then
                        print_success "Config indirildi (zip)"
                        return 0
                    fi
                fi
            fi
        fi
    fi
    
    # Hiçbiri çalışmadı
    print_error "Config indirilemedi!"
    echo ""
    echo -e "    ${YELLOW}Manuel indirme: ${NC}"
    echo "    1.  Tarayıcıda aç:  https://github.com/w7h3r/w7h3r-NeovimConfig"
    echo "    2. 'Code' → 'Download ZIP' tıkla"
    echo "    3. ZIP'i çıkart"
    echo "    4. Klasörü taşı:"
    echo "       mv w7h3r-NeovimConfig-main ~/. config/nvim"
    echo ""
    exit 1
}

verify_config() {
    if [ !  -d "$NVIM_CONFIG" ]; then
        print_error "Config dizini yok:  $NVIM_CONFIG"
        return 1
    fi
    
    local required_files=(
        "init.lua"
        "lua/config/lazy.lua"
        "lua/plugins/essential/lsp.lua"
        "lua/plugins/42/42header.lua"
        "lua/settings/general.lua"
    )
    
    local missing=0
    for file in "${required_files[@]}"; do
        if [ ! -f "$NVIM_CONFIG/$file" ]; then
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        print_error "$missing dosya eksik!"
        return 1
    fi
    
    print_substep "Tüm config dosyaları mevcut"
    echo ""
    echo -e "    ${CYAN}$NVIM_CONFIG/${NC}"
    echo "    ├── init.lua"
    echo "    ├── lua/"
    echo "    │   ├── config/lazy.lua"
    echo "    │   ├── plugins/"
    echo "    │   │   ├── 42/ (42header, norminette)"
    echo "    │   │   └── essential/ (lsp, cmp, ... )"
    echo "    │   └── settings/general.lua"
    
    return 0
}

configure_user() {
    print_step "Kullanıcı bilgileri ayarlanıyor..."
    
    local header_file="$NVIM_CONFIG/lua/plugins/42/42header.lua"
    local init_file="$NVIM_CONFIG/init.lua"
    
    if [ !  -f "$header_file" ]; then
        print_error "42header.lua bulunamadı!"
        return 1
    fi
    
    echo ""
    read -p "    42 intra kullanıcı adınız:  " USER_42
    read -p "    42 e-posta adresiniz: " EMAIL_42
    
    if [ -n "$USER_42" ] && [ -n "$EMAIL_42" ]; then
        sed -i "s/user = \"muokcan\"/user = \"$USER_42\"/" "$header_file"
        sed -i "s/mail = \"muokcan@student.42kocaeli.com. tr\"/mail = \"$EMAIL_42\"/" "$header_file"
        print_success "42 header bilgileri güncellendi"
    else
        print_warning "42 header bilgileri varsayılan bırakıldı"
    fi
    
    if [ -f "$init_file" ]; then
        sed -i "s|/home/your~username/bin|$HOME/bin|" "$init_file"
        print_success "PATH ayarı güncellendi"
    fi
}

configure_norminette() {
    print_step "Norminette kontrol ediliyor..."
    
    local norm_file="$NVIM_CONFIG/lua/plugins/42/norminette.lua"
    
    if [ ! -f "$norm_file" ]; then
        print_warning "norminette.lua bulunamadı"
        return 0
    fi
    
    if command -v norminette >/dev/null 2>&1; then
        print_success "Norminette bulundu"
        
        read -p "    Norminette'i aktif etmek ister misiniz? (e/h): " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Ee]$ ]]; then
            sed -i "s/active = false/active = true/" "$norm_file"
            print_success "Norminette aktifleştirildi"
        fi
    else
        print_warning "Norminette bulunamadı"
    fi
}

install_plugins() {
    print_step "Neovim pluginleri yükleniyor..."
    
    if [ !  -f "$NVIM_CONFIG/init.lua" ]; then
        print_error "Config bulunamadı, plugin kurulumu atlanıyor"
        return 1
    fi
    
    print_warning "Bu işlem birkaç dakika sürebilir..."
    echo ""
    
    "$HOME_BIN/nvim" --headless "+Lazy!  sync" +qa 2>/dev/null || {
        print_warning "Plugin kurulumunda uyarılar olabilir"
    }
    
    print_success "Pluginler yüklendi"
}

print_summary() {
    echo ""
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Kurulum Tamamlandı!                        ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    echo -e "${BOLD}Kurulum Konumları:${NC}"
    echo "  Neovim        → $HOME_BIN/nvim"
    [ -f "$HOME_BIN/rg" ] && echo "  Ripgrep       → $HOME_BIN/rg"
    [ -f "$HOME_BIN/fd" ] && echo "  fd            → $HOME_BIN/fd"
    [ -f "$HOME_BIN/node" ] && echo "  Node.js       → $HOME_BIN/node"
    echo "  Config        → $NVIM_CONFIG"
    echo ""
    
    echo -e "${YELLOW}${BOLD}ÖNEMLİ: ${NC} PATH'i aktif etmek için:"
    echo ""
    echo -e "    ${CYAN}source ~/. bashrc${NC}  veya  ${CYAN}source ~/.zshrc${NC}"
    echo ""
    
    echo -e "${BOLD}Kısayollar:${NC}"
    echo "  Space        → Leader tuşu"
    echo "  F1           → 42 Header ekle"
    echo "  Ctrl+L       → Copilot kabul"
    echo "  gd           → Tanıma git"
    echo "  K            → Hover"
    echo ""
    
    echo -e "${BOLD}Sonraki: ${NC}"
    echo "  1. source ~/.bashrc"
    echo "  2. nvim"
    echo "  3. : Copilot auth"
    echo "  4. :checkhealth"
    echo ""
}

main() {
    print_header
    
    detect_os
    create_directories
    setup_path
    
    echo ""
    echo -e "${BOLD}Kurulacaklar:${NC}"
    echo "  • Neovim v$NVIM_VERSION"
    echo "  • Ripgrep v$RIPGREP_VERSION"
    echo "  • fd v$FD_VERSION"
    echo "  • Node.js v$NODE_VERSION"
    echo "  • w7h3r-NeovimConfig"
    echo ""
    
    read -p "Devam?  (e/h): " -n 1 -r
    echo ""
    
    if [[ !  $REPLY =~ ^[Ee]$ ]]; then
        echo "İptal edildi."
        exit 0
    fi
    
    install_neovim
    install_ripgrep
    install_fd
    install_nodejs
    backup_config
    download_config
    configure_user
    configure_norminette
    install_plugins
    print_summary
}

main "$@"
