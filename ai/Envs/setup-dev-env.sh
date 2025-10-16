#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
# 🚀 Termux AI Dev Installer + Launcher
# Author: Tony (MuhaliLabs)
# Purpose: Fully automated Micromamba + Debian dev environment
# ==========================================================

set -e

MICROMAMBA_DIR="$HOME/micromamba"
DISTRO_NAME="debian"
DEV_ENV="dev"
WRAPPER="$PREFIX/bin/dev"

echo ""
echo "🌌 Starting Termux AI dev environment setup..."

# --- STEP 1: Prerequisites ---
termux-setup-storage
pkg update -y
pkg install -y curl wget git tar proot-distro

# --- STEP 2: Install Micromamba if missing ---
if [ ! -x "$MICROMAMBA_DIR/bin/micromamba" ]; then
    echo "📦 Installing Micromamba..."
    mkdir -p "$MICROMAMBA_DIR"
    cd "$MICROMAMBA_DIR"
    curl -L -o micromamba.tar.bz2 "https://micromamba.snakepit.net/api/micromamba/linux-aarch64/latest"
    tar -xvjf micromamba.tar.bz2 --strip-components=1
    rm -f micromamba.tar.bz2
fi

export MAMBA_ROOT_PREFIX="$MICROMAMBA_DIR"
export PATH="$MICROMAMBA_DIR/bin:$PATH"

# --- STEP 3: Create Micromamba dev environment ---
if "$MICROMAMBA_DIR/bin/micromamba" env list | grep -q "^$DEV_ENV"; then
    echo "✅ Micromamba dev environment '$DEV_ENV' already exists."
else
    echo "🧠 Creating Micromamba dev environment '$DEV_ENV'..."
    "$MICROMAMBA_DIR/bin/micromamba" create -y -n "$DEV_ENV" python=3.10 -c conda-forge
    "$MICROMAMBA_DIR/bin/micromamba" activate "$DEV_ENV"
    echo "📚 Installing Python packages..."
    pip install -U pip setuptools wheel
    pip install numpy pandas scipy tqdm requests openai whisper torch torchvision torchaudio
    pip install yt-dlp ffmpeg-python opencv-python pillow
    echo "✅ Micromamba dev environment ready."
fi

# --- STEP 4: Fallback Debian proot if Micromamba fails ---
MICROMAMBA_WORKS=$("$MICROMAMBA_DIR/bin/micromamba" --version >/dev/null 2>&1 && echo 1 || echo 0)
if [ "$MICROMAMBA_WORKS" -eq 0 ]; then
    echo "⚠️ Micromamba failed. Falling back to Debian..."
    if ! proot-distro list | grep -q "^$DISTRO_NAME"; then
        echo "📦 Installing Debian..."
        proot-distro install "$DISTRO_NAME"
    else
        echo "✅ Debian already installed."
    fi

    echo "🔄 Setting up dev environment inside Debian..."
    proot-distro login "$DISTRO_NAME" <<'EOF'
set -e
DEV_ENV="dev"
MINIFORGE_DIR="$HOME/miniforge3"

apt update && apt install -y curl wget tar bzip2 python3 python3-pip

if [ ! -d "$MINIFORGE_DIR" ]; then
    echo "📦 Installing Miniforge inside Debian..."
    curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-aarch64.sh
    bash "$MINIFORGE_DIR.sh" -b -p "$MINIFORGE_DIR"
    rm -f Miniforge3-Linux-aarch64.sh
fi

export PATH="$MINIFORGE_DIR/bin:$PATH"
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

# Create dev env if not exists
if ! conda env list | grep -q "^$DEV_ENV"; then
    echo "🧠 Creating '$DEV_ENV' environment..."
    conda create -y -n $DEV_ENV python=3.10
fi

conda activate $DEV_ENV

# Install AI packages
pip install -U pip setuptools wheel
pip install numpy pandas scipy tqdm requests openai whisper torch torchvision torchaudio
pip install yt-dlp ffmpeg-python opencv-python pillow
EOF
fi

# --- STEP 5: Create wrapper script ---
echo "🌌 Creating dev launcher script..."
cat > "$WRAPPER" <<EOL
#!/data/data/com.termux/files/usr/bin/bash
MICROMAMBA_DIR="$HOME/micromamba"
DISTRO_NAME="debian"
DEV_ENV="dev"

if [ -x "\$MICROMAMBA_DIR/bin/micromamba" ]; then
    export MAMBA_ROOT_PREFIX="\$MICROMAMBA_DIR"
    export PATH="\$MICROMAMBA_DIR/bin:\$PATH"
    "\$MICROMAMBA_DIR/bin/micromamba" activate "\$DEV_ENV"
    echo "✅ Activated Micromamba dev environment '\$DEV_ENV'."
    exec \$SHELL
elif proot-distro list | grep -q "^\$DISTRO_NAME"; then
    echo "🌌 Launching Debian proot environment..."
    echo "💡 Activate dev environment inside with: conda activate \$DEV_ENV"
    proot-distro login "\$DISTRO_NAME"
else
    echo "❌ No dev environment found. Run the installer first."
fi
EOL

chmod +x "$WRAPPER"
echo "✅ Wrapper script 'dev' installed. Run 'dev' to launch your AI dev environment."

echo ""
echo "🎉 All-in-one setup complete!"
