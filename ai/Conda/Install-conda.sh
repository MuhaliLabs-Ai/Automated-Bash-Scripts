#!/data/data/com.termux/files/usr/bin/bash
# ============================================
# 🧬 Conda Setup Script (Termux + Linux)
# Author: Tony (MuhaliLabs)
# Purpose: Install Miniconda, configure PATH,
#          and make Conda globally accessible.
# ============================================

set -e

# --- CONFIG ---
CONDA_DIR="$HOME/miniconda3"
CONDA_BIN="$CONDA_DIR/bin"
BASHRC="$HOME/.bashrc"
INSTALLER="Miniconda3-latest-Linux-$(uname -m).sh"
CONDA_URL="https://repo.anaconda.com/miniconda/$INSTALLER"

echo ""
echo "🔍 Checking for existing Conda installation..."
if [ -d "$CONDA_DIR" ]; then
    echo "⚠️ Conda already installed at $CONDA_DIR"
    read -p "Do you want to reinstall? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        rm -rf "$CONDA_DIR"
    else
        echo "✅ Skipping installation."
        exit 0
    fi
fi

echo ""
echo "📦 Downloading Miniconda installer..."
curl -L -o "$INSTALLER" "$CONDA_URL"

echo ""
echo "⚙️ Running installer..."
bash "$INSTALLER" -b -p "$CONDA_DIR"

echo ""
echo "🧹 Cleaning up..."
rm -f "$INSTALLER"

# --- Add to PATH if not already there ---
if ! grep -q "$CONDA_BIN" "$BASHRC"; then
    echo "🔧 Adding Conda to PATH in $BASHRC..."
    {
        echo ""
        echo "# >>> conda initialize >>>"
        echo "export PATH=\"$CONDA_BIN:\$PATH\""
        echo "# <<< conda initialize <<<"
    } >> "$BASHRC"
fi

# --- Initialize Conda ---
echo ""
echo "🔄 Initializing Conda..."
source "$CONDA_BIN/activate"
"$CONDA_BIN/conda" init bash

# --- Verify ---
echo ""
echo "✅ Verifying installation..."
source "$BASHRC"
conda --version

echo ""
echo "🎉 Conda installed successfully!"
echo "👉 Restart your terminal or run: source ~/.bashrc"
echo "👉 Then test with: conda info"
