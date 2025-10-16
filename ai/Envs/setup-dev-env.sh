#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
# 🚀 Termux AI Dev Installer + Launcher (Fixed)
# Author: Tony (MuhaliLabs)
# Purpose: Guaranteed working Micromamba + Debian fallback
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
pkg install -y curl wget git tar proot-distro bzip2

# --- STEP 2: Install Micromamba if missing ---
if [ ! -x "$MICROMAMBA_DIR/bin/micromamba" ]; then
    echo "📦 Installing Micromamba..."
    mkdir -p "$MICROMAMBA_DIR"
    cd "$MICROMAMBA_DIR"

    # Download latest aarch64 release
    curl -L -o micromamba.tar.bz2 "https://micromamba.snakepit.net/api/micromamba/linux-aarch64/latest"

    # Extract safely: preserve bin/micromamba
    tar -xvjf micromamba.tar.bz2
    rm -f micromamba.tar.bz2

    if [ ! -x "$MICROMAMBA_DIR/bin/micromamba" ]; then
        echo "❌ Micromamba binary not found after extraction!"
        exit 1
    fi
fi

# --- STEP 3: Setup PATH and verify ---
export MAMBA_ROOT_PREFIX="$MICROMAMBA_DIR"
export PATH="$MICROMAMBA_DIR/bin:$PATH"
hash -r

echo "✅ Micromamba version: $(micromamba --version)"

# --- STEP 4: Create dev environment if missing ---
if micromamba env list | grep -q "^$DEV_ENV"; then
    echo "✅ Micromamba dev environment '$DEV_ENV' already exists."
else
    echo "🧠 Creating Micromamba dev environment '$DEV_ENV'..."
    micromamba create -y -n "$DEV_ENV" python=3.10 -c conda-forge
fi

# Activate environment and install AI packages
micromamba activate "$DEV_ENV"
pip install -U pip setuptools wheel
pip install numpy pandas scipy tqdm requests openai whisper torch torchvision torchaudio
pip install yt-dlp ffmpeg-python opencv-python pillow

# --- STEP 5: Fallback Debian proot if Micromamba fails ---
MICROMAMBA_WORKS=$(command -v micromamba >/dev/null 2>&1 && echo 1 || echo 0)
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
    bash Miniforge3-Linux-aarch64.sh -b -p "$MINIFORGE_DIR"
    rm -f Miniforge3-Linux-aarch64.sh
fi

export PATH="$MINIFORGE_DIR/bin:$PATH"
source "$MINIFORGE_DIR/etc/profile.d/conda.sh"

if ! conda env list | grep -q "^$DEV_ENV"; then
    echo "🧠 Creating '$DEV_ENV' environment..."
    conda create -y -n $DEV_ENV python=3.10
fi

conda activate $DEV_ENV

pip install -U pip setuptools wheel
pip install numpy pandas scipy tqdm requests openai whisper torch torchvision torchaudio
pip install yt-dlp ffmpeg-python opencv-python pillow
EOF
fi

# --- STEP 6: Create wrapper script ---
echo "🌌 Creating dev launcher script..."
cat > "$WRAPPER" <<'EOL'
#!/data/data/com.termux/files/usr/bin/bash
MICROMAMBA_DIR="$HOME/micromamba"
DISTRO_NAME="debian"
DEV_ENV="dev"

MICROMAMBA="$MICROMAMBA_DIR/bin/micromamba"
if [ -x "$MICROMAMBA" ]; then
    export MAMBA_ROOT_PREFIX="$MICROMAMBA_DIR"
    export PATH="$MICROMAMBA_DIR/bin:$PATH"
    "$MICROMAMBA" activate "$DEV_ENV"
    echo "✅ Activated Micromamba dev environment '$DEV_ENV'."
    exec $SHELL
elif proot-distro list | grep -q "^\$DISTRO_NAME"; then
    echo "🌌 Launching Debian proot environment..."
    echo "💡 Activate dev environment inside with: conda activate $DEV_ENV"
    proot-distro login "$DISTRO_NAME"
else
    echo "❌ No dev environment found. Run the installer first."
fi
EOL

chmod +x "$WRAPPER"
echo "✅ Wrapper script 'dev' installed. Run 'dev' to launch your AI dev environment."

echo ""
echo "🎉 All-in-one fixed setup complete!"
