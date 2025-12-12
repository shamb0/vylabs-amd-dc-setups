#!/bin/bash
# ==============================================================================
# Vyaakar Labs Tier-01 Factory Controller (vlabs-manage.sh)
# ------------------------------------------------------------------------------
# Automates the setup, mode switching, and resource management for the 
# MI300X Inference Factory.
#
# USAGE:
#   ./vlabs-manage.sh setup          # One-time host init (Disk, Rust, Tools)
#   ./vlabs-manage.sh dual           # Teamwork Mode (Architect + Builder)
#   ./vlabs-manage.sh solo-architect # Deep Thought Mode (262k Context)
#   ./vlabs-manage.sh solo-builder   # Deep Coding Mode (262k Context)
#   ./vlabs-manage.sh stop           # Shutdown all factories
# ==============================================================================

set -e  # Exit on error

# --- Configuration ---
# Matches your cheatsheet specifications
SCRATCH_DEV="/dev/vdc1"
SCRATCH_MOUNT="/mnt/scratch"
HF_CACHE="$SCRATCH_MOUNT/huggingface"
CARGO_HOME="$HOME/.custom_cargo"

# --- Visual Helpers ---
log_info() { echo -e "\033[1;34m[*] [INFO] $1\033[0m"; }
log_success() { echo -e "\033[1;32m[+] [SUCCESS] $1\033[0m"; }
log_warn() { echo -e "\033[1;33m[!] [WARN] $1\033[0m"; }

# --- 1. Host Setup Function ---
setup_host() {
    log_info "Initializing Vyaakar Labs Host Environment..."

    # A. Mount Persistence Disk (5TB NVMe)
    if mountpoint -q "$SCRATCH_MOUNT"; then
        log_success "Disk $SCRATCH_MOUNT is already mounted."
    else
        log_info "Mounting $SCRATCH_DEV to $SCRATCH_MOUNT..."
        sudo mkdir -p "$SCRATCH_MOUNT"
        sudo mount "$SCRATCH_DEV" "$SCRATCH_MOUNT"
        log_success "Disk mounted."
    fi

    # B. Prepare Cache Directories
    log_info "Verifying HuggingFace cache directory..."
    sudo mkdir -p "$HF_CACHE"
    
    # C. Rust & Shpool Toolchain (Idempotent)
    # Checks if 'shpool' is in the custom cargo path
    export PATH="$CARGO_HOME/bin:$PATH"
    
    if command -v shpool &> /dev/null; then
        log_success "Rust & shpool are already installed."
    else
        log_info "Installing Rust toolchain to $CARGO_HOME..."
        
        # Install Rustup
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        
        # Source env manually since we are in a script
        source "$HOME/.cargo/env" 2>/dev/null || true
        
        # Install Tools
        log_info "Compiling shpool and exa (this may take a moment)..."
        # We temporarily set CARGO_HOME for installation
        export CARGO_HOME="$CARGO_HOME"
        cargo install shpool exa
        
        # Persist to .bashrc for future interactive sessions
        if ! grep -q "custom_cargo" ~/.bashrc; then
            echo '' >> ~/.bashrc
            echo '# Vyaakar Labs Toolchain' >> ~/.bashrc
            echo "export CARGO_HOME=\"$CARGO_HOME\"" >> ~/.bashrc
            echo 'export PATH="$CARGO_HOME/bin:$PATH"' >> ~/.bashrc
            log_success "Added toolchain to .bashrc"
        fi
    fi
    
    log_success "Host Setup Complete. You are ready to launch the factory."
}

# --- 2. Mode Switcher Function ---
start_mode() {
    MODE_NAME=$1
    PROFILE_TAG=$2
    
    echo ""
    log_info "Switching Factory to: $MODE_NAME"
    
    # A. Clean Slate (Stop existing containers to free VRAM)
    log_info "Shutting down active containers..."
    docker compose down 2>/dev/null
    
    # B. Launch New Profile
    # The --profile flag tells docker-compose which set of services to start
    log_info "Ignition: Starting profile '$PROFILE_TAG'..."
    docker compose --profile "$PROFILE_TAG" up -d
    
    echo ""
    log_success "Factory Floor is Active ($MODE_NAME)"
    echo "--------------------------------------------------------"
    echo "   Architect Port : 30001 (Reasoning)"
    echo "   Builder Port   : 30000 (Coding)"
    echo "--------------------------------------------------------"
    echo "To view logs: docker compose logs -f"
    echo "--------------------------------------------------------"
}

# --- 3. Main Execution Router ---

case "$1" in
    setup)
        setup_host
        ;;
    dual)
        # Launches: architect-dual (FP8/AITER), builder-dual (BF16/No-Triton), janitor
        start_mode "DUAL-MODEL (Teamwork)" "dual"
        ;;
    solo-architect)
        # Launches: architect-solo (Max Context), janitor
        start_mode "SOLO-ARCHITECT (Deep Thought)" "solo-architect"
        ;;
    solo-builder)
        # Launches: builder-solo (Max Context), janitor
        start_mode "SOLO-BUILDER (Deep Coding)" "solo-builder"
        ;;
    stop)
        log_info "Stopping all factory services..."
        docker compose down
        log_success "Factory shutdown complete."
        ;;
    *)
        echo "Usage: $0 {setup|dual|solo-architect|solo-builder|stop}"
        exit 1
        ;;
esac
