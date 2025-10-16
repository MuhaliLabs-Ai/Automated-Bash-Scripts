#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
# 🧬 Conda + Dev Environment Installer (Termux/Linux)
# Author: Tony (MuhaliLabs)
# Purpose: Install Miniforge + create AI dev environment
# ==========================================================

set -e

CONDA_DIR="$HOME/miniforge3"
CONDA_BIN="$CONDA_DIR/bin"
BASHRC="$HOME/.bashrc"
DEV_ENV="dev"

echo ""
echo "🚀 Starting Conda (Miniforge) installation..."

# --- STEP 1: Install dependencies ---
pkg update -y
pkg install -y curl wget git

# --- STEP 2: Remove old installs ---
if [ -d "$CONDA_DIR" ]; then
  echo "⚠️ Removing existing Conda installation..."
  rm -rf "$CONDA_DIR"
fi

# --- STEP 3: Download Miniforge ---
ARCH=$(uname -m)
INSTALLER="Miniforge3-Linux-${ARCH}.sh"
URL="https://github.com/conda-forge/miniforge/releases/latest/download/${INSTALLER}"

echo "📦 Downloading Miniforge for ${ARCH}..."
curl -L -O "$URL"

# --- STEP 4: Run installer ---
echo "⚙️ Installing Miniforge..."
bash "$INSTALLER" -b -p "$CONDA_DIR"
rm -f "$INSTALLER"

# --- STEP 5: Add to PATH ---
if ! grep -q "$CONDA_BIN" "$BASHRC"; then
  echo "🔧 Adding Conda to PATH..."
  echo 'export PATH="$HOME/miniforge3/bin:$PATH"' >> "$BASHRC"
fi
source "$BASHRC"

# --- STEP 6: Make Conda global (Termux-specific) ---
if [ -d "$PREFIX/bin" ]; then
  ln -sf "$CONDA_BIN/conda" "$PREFIX/bin/conda"
fi

# --- STEP 7: Verify install ---
echo "✅ Verifying Conda installation..."
conda --version || { echo "❌ Conda not found!"; exit 1; }

# --- STEP 8: Create AI Dev environment ---
echo ""
echo "🧠 Creating AI development environment: '$DEV_ENV'"
conda create -y -n $DEV_ENV python=3.10 pip

echo "⚙️ Activating '$DEV_ENV'..."
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda activate $DEV_ENV

# --- STEP 9: Install key packages ---
echo ""
echo "📚 Installing core AI tools..."
pip install -U pip setuptools wheel
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu
pip install numpy pandas scipy tqdm requests openai whisper moviepy
pip install yt-dlp ffmpeg-python opencv-python pillow

echo ""
echo "✨ Done! Your 'dev' environment includes:"
echo "    - Python 3.10"
echo "    - PyTorch CPU build"
echo "    - Whisper (speech-to-text)"
echo "    - yt-dlp, ffmpeg-python, moviepy, OpenCV"
echo "    - numpy, pandas, scipy, tqdm"
echo ""
echo "🔧 To activate it anytime, run:"
echo "    conda activate dev"
echo ""
echo "🌙 Restart your terminal or run:"
echo "    source ~/.bashrc"
echo ""
echo "🎉 Installation complete. Happy coding, Tony!"
