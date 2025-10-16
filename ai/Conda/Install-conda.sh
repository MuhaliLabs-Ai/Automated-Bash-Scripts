#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
# 🚀 Termux AI Dev Installer (Micromamba + Proot Fallback)
# Author: Tony (MuhaliLabs)
# Purpose: Automatic Conda dev env setup in Termux
# ==========================================================

set -e
DEV_ENV="dev"
MICROMAMBA_DIR="$HOME/micromamba"
PROOT_DISTRO="ubuntu-20.04"

echo ""
echo "🌌 Starting Termux AI dev environment setup..."

# --- STEP 1: Ensure permissions and core packages ---
echo "⚡ Installing prerequisites..."
termux-setup-storage
pkg update -y
pkg install -y curl wget git tar proot-distro

# --- STEP 2: Detect working directory ---
INSTALL_DIR="$HOME"
echo "📂 Using installer working directory: $INSTALL_DIR"

# --- STEP 3: Try micromamba first ---
echo ""
echo "🧪 Attempting Micromamba installation..."
mkdir -p "$MICROMAMBA_DIR"
cd "$MICROMAMBA_DIR"

MICROMAMBA_TAR="micromamba.tar.bz2"
MICROMAMBA_URL="https://micromamba.snakepit.net/api/micromamba/linux-aarch64/latest"

curl -L -o "$MICROMAMBA_TAR" "$MICROMAMBA_URL" || {
    echo "⚠️ Micromamba download failed. Will attempt proot-distro fallback."
    MICROMAMBA_FAIL=1
}

if [ -z "$MICROMAMBA_FAIL" ]; then
    echo "📦 Extracting micromamba..."
    tar -xvjf "$MICROMAMBA_TAR" --strip-components=1
    rm -f "$MICROMAMBA_TAR"

    export MAMBA_ROOT_PREFIX="$MICROMAMBA_DIR"
    export PATH="$MICROMAMBA_DIR/bin:$PATH"

    ./micromamba --version >/dev/null 2>&1 || MICROMAMBA_FAIL=1
fi

# --- STEP 4: Create dev environment with micromamba ---
if [ -z "$MICROMAMBA_FAIL" ]; then
    echo "🧠 Creating '$DEV_ENV' environment with micromamba..."
    ./micromamba create -y -n $DEV_ENV python=3.10 -c conda-forge
    ./micromamba activate $DEV_ENV

    echo "📚 Installing Python packages..."
    pip install -U pip setuptools wheel
    pip install numpy pandas scipy tqdm requests openai whisper torch torchvision torchaudio
    pip install yt-dlp ffmpeg-python opencv-python pillow

    echo ""
    echo "✅ Micromamba environment setup complete!"
    echo "💡 Activate anytime with: source $MICROMAMBA_DIR/bin/activate $DEV_ENV"
    exit 0
fi

# --- STEP 5: Fallback to proot-distro if micromamba fails ---
echo ""
echo "⚡ Micromamba failed. Falling back to proot-distro Ubuntu..."
proot-distro install $PROOT_DISTRO || echo "⚠️ Ubuntu distro already installed."
proot-distro login $PROOT_DISTRO <<'EOF'
set -e
echo "🌌 Inside Ubuntu chroot: Installing Miniforge..."
apt update && apt install -y curl wget tar bzip2

INSTALLER="Miniforge3-Linux-aarch64.sh"
curl -L -O https://github.com/conda-forge/miniforge/releases/latest/download/$INSTALLER
bash "$INSTALLER" -b -p ~/miniforge3
rm -f "$INSTALLER"
export PATH="$HOME/miniforge3/bin:$PATH"

# Create dev environment
source ~/miniforge3/etc/profile.d/conda.sh
conda create -y -n dev python=3.10
conda activate dev

# Install AI packages
pip install -U pip setuptools wheel
pip install numpy pandas scipy tqdm requests openai whisper torch torchvision torchaudio
pip install yt-dlp ffmpeg-python opencv-python pillow

echo ""
echo "✅ Ubuntu proot dev environment ready!"
echo "💡 Activate inside chroot with: conda activate dev"
EOF

echo ""
echo "🎉 Setup complete. If micromamba worked, use it directly. Otherwise, run 'proot-distro login $PROOT_DISTRO' to use the dev environment inside Ubuntu."
