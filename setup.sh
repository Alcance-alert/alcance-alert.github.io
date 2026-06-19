#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  ALCANCE ALERT — Setup Script
#  Roda esse script num Mac novo e tudo fica configurado.
#  Uso: bash setup.sh
# ═══════════════════════════════════════════════════════════

set -e
echo ""
echo "🚀 Alcance Alert — Setup iniciando..."
echo ""

# ── 1. Homebrew ──────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "📦 Instalando Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Apple Silicon
  if [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  fi
else
  echo "✅ Homebrew já instalado"
fi

# ── 2. Cairo (necessário para cairosvg) ──────────────────
echo "📦 Instalando cairo..."
brew install cairo

# ── 3. Python packages ───────────────────────────────────
echo "📦 Instalando pacotes Python..."
pip3 install cairosvg pillow requests schedule --quiet

# ── 4. Clonar repo ───────────────────────────────────────
REPO_DIR="$HOME/Documents/alcance-alert.github.io"
if [ ! -d "$REPO_DIR" ]; then
  echo "📁 Clonando repositório..."
  mkdir -p "$HOME/Documents"
  git clone https://github.com/Alcances-alert/alcance-alert.github.io.git "$REPO_DIR"
else
  echo "✅ Repositório já existe"
fi

# ── 5. Alias deploy-alcance ──────────────────────────────
ZSHRC="$HOME/.zshrc"
if ! grep -q "deploy-alcance" "$ZSHRC" 2>/dev/null; then
  echo "⚙️  Criando alias deploy-alcance..."
  cat >> "$ZSHRC" << 'ALIAS'

# Alcance Alert deploy
alias deploy-alcance='cp ~/Documents/alcance-alert.github.io/landing.html ~/Documents/alcance-alert.github.io/index.html && cd ~/Documents/alcance-alert.github.io && git add -A && git commit -m "deploy $(date +%Y-%m-%d)" && git push'
ALIAS
else
  echo "✅ Alias deploy-alcance já existe"
fi

# ── 6. Copiar stock_alert.py para o lugar certo ──────────
ALERT_SRC="$REPO_DIR/stock_alert.py"
ALERT_DST="$HOME/stock_alert.py"
if [ -f "$ALERT_SRC" ]; then
  cp "$ALERT_SRC" "$ALERT_DST"
  echo "✅ stock_alert.py copiado para $ALERT_DST"
else
  echo "⚠️  stock_alert.py não encontrado no repo — copie manualmente depois"
fi

# ── 7. launchd — auto-start do script de alertas ─────────
PLIST="$HOME/Library/LaunchAgents/com.alcance.stockalert.plist"
if [ ! -f "$PLIST" ]; then
  echo "⚙️  Configurando launchd..."
  mkdir -p "$HOME/Library/LaunchAgents"
  cat > "$PLIST" << PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.alcance.stockalert</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>$HOME/stock_alert.py</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>/tmp/stockalert.log</string>
  <key>StandardErrorPath</key>
  <string>/tmp/stockalert.log</string>
</dict>
</plist>
PLISTEOF
  launchctl load "$PLIST"
  echo "✅ launchd configurado e iniciado"
else
  echo "✅ launchd já configurado"
fi

# ── 8. Gerar favicons ────────────────────────────────────
echo "🎨 Gerando favicons..."
python3 << 'PYEOF'
from PIL import Image, ImageDraw
import os
os.chdir(os.path.expanduser("~/Documents/alcance-alert.github.io"))

def draw_logo(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    pad = size * 0.05
    cx, cy, r = size/2, size/2, size/2 - pad
    d.ellipse([cx-r, cy-r, cx+r, cy+r], outline="#FF6B00", width=max(1, int(size*0.05)))
    pts_raw = [(18,54),(30,40),(42,46),(54,26),(66,30)]
    scale = size / 80
    pts = [(x*scale, y*scale) for x,y in pts_raw]
    d.line(pts, fill="#FF6B00", width=max(1, int(size*0.05)), joint="curve")
    dx, dy = 54*scale, 26*scale
    dr = size * 0.075
    d.ellipse([dx-dr, dy-dr, dx+dr, dy+dr], fill="#FF6B00")
    return img

for size in [16, 32, 48, 180, 192, 512]:
    draw_logo(size).save(f"favicon-{size}x{size}.png")
    print(f"  favicon-{size}x{size}.png OK")

imgs = [draw_logo(s) for s in [48, 32, 16]]
imgs[0].save("favicon.ico", format="ICO", sizes=[(48,48),(32,32),(16,16)], append_images=imgs[1:])
print("  favicon.ico OK")
PYEOF

# ── Fim ───────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════"
echo "✅ Setup completo!"
echo ""
echo "Próximos passos manuais:"
echo "  1. source ~/.zshrc"
echo "  2. Configurar git: git config --global user.email 'SEU@EMAIL'"
echo "  3. Verificar stock_alert.py (API keys)"
echo "  4. Testar: deploy-alcance"
echo "═══════════════════════════════════════════"
