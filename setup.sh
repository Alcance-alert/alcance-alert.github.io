#!/bin/bash
# ALCANCE ALERT — Setup Script
# Uso: bash setup.sh

set -e
echo "🚀 Alcance Alert — Setup iniciando..."

if ! command -v brew &>/dev/null; then
  echo "📦 Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
else
  echo "✅ Homebrew já instalado"
fi

brew install cairo
pip3 install cairosvg pillow requests schedule --quiet

REPO_DIR="$HOME/Documents/alcance-alert.github.io"
if [ ! -d "$REPO_DIR" ]; then
  git clone https://github.com/Alcances-alert/alcance-alert.github.io.git "$REPO_DIR"
else
  echo "✅ Repo já existe"
fi

if ! grep -q "deploy-alcance" ~/.zshrc 2>/dev/null; then
  echo "alias deploy-alcance='cp ~/Documents/alcance-alert.github.io/landing.html ~/Documents/alcance-alert.github.io/index.html && cd ~/Documents/alcance-alert.github.io && git add -A && git commit -m \"deploy \$(date +%Y-%m-%d)\" && git push'" >> ~/.zshrc
  echo "✅ Alias criado"
fi

echo ""
echo "✅ Setup completo!"
echo "Rode: source ~/.zshrc"
