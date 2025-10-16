#!/data/data/com.termux/files/usr/bin/bash
# ==========================================================
# 🧬 Termux-safe Conda + AI Dev Environment Installer
# Author: Tony (MuhaliLabs)
# Purpose: Install Miniforge + fix ldd/file issue + create AI dev environment
# ==========================================================

set -e

CONDA_DIR="$HOME/miniforge3"
CONDA_BIN="$CONDA_DIR/bin"
BASHRC="$HOME/.bashrc"
DEV_ENV="dev"

echo ""
echo "🚀 Starting Conda (Miniforge) installation for Termux..."

# --- STEP 1: Termux permissions & dependencies ---
echo "⚡ Ensuring Termux permissions and dependencies..."
termux-setup-storage
pkg update -y
pkg install -y curl git wget tar

# --- STEP 2: Remove old installs ---
if [ -d "$CONDA_DIR" ]; then
  echo "⚠️ Removing existing Conda installation..."
  rm -rf "$CONDA_DIR"
fi

# --- STEP 3: Download Miniforge (aarch64) ---
ARCH=$(uname -m)
INSTALLER="Miniforge3-Linux-${ARCH}.sh"
URL="https://github.com/conda-forge/miniforge/releases/latest/download/${INSTALLER}"

echo "📦 Downloading Miniforge..."
curl -L -O "$URL"
chmod +x "$INSTALLER"

# --- STEP 4: Fix Termux ldd/file permissions ---
echo "🔧 Patching Termux environment for installer..."
# Override ldd temporarily to avoid permission errors
alias ldd="true"
export PATH="$PREFIX/bin:$PATH"
unset LD_PRELOAD
unset LD_LIBRARY_PATH

# --- STEP 5: Run installer ---
echo "⚙️ Installing Miniforge..."
bash "$INSTALLER" -b -p "$CONDA_DIR"
rm -f "$INSTALLER"

# --- STEP 6: Add Conda to PATH permanently ---
if ! grep -q "$CONDA_BIN" "$BASHRC"; then
  echo "🔧 Adding Conda to PATH in $BASHRC..."
  echo 'export PATH="$HOME/miniforge3/bin:$PATH"' >> "$BASHRC"
fi
source "$BASHRC"

# --- STEP 7: Make Conda global (Termux-specific) ---
ln -sf "$CONDA_BIN/conda" "$PREFIX/bin/conda"

# --- STEP 8: Verify install ---
echo "✅ Verifying Conda installation..."
conda --version || { echo "❌ Conda not found!"; exit 1; }

# --- STEP 9: Create AI Dev environment ---
echo ""
echo "🧠 Creating AI development environment: '$DEV_ENV'"
source "$CONDA_DIR/etc/profile.d/conda.sh"
conda create -y -n $DEV_ENV python=3.10

echo "⚙️ Activating '$DEV_ENV'..."
conda activate $DEV_ENV

# --- STEP 10: Install key AI packages ---
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
