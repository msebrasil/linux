#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

if [[ "${EUID}" -ne 0 ]]; then
  echo "Execute com sudo: sudo ./build.sh"
  exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build não encontrado. Instale o pacote live-build."
  exit 1
fi

echo "[1/6] Limpando build anterior..."
lb clean --purge || true
rm -f live-image-amd64.hybrid.iso

echo "[2/6] Preparando drivers locais..."
mkdir -p config/includes.chroot/opt/mse-drivers/pantum
mkdir -p config/includes.chroot/opt/mse-drivers/xprinter
find config/includes.chroot/opt/mse-drivers/pantum -maxdepth 1 -name '*.deb' -delete || true
find config/includes.chroot/opt/mse-drivers/xprinter -maxdepth 1 -name '*.deb' -delete || true

shopt -s nullglob
PANTUM=(drivers/pantum/*.deb)
XPRINTER=(drivers/xprinter/*.deb)
if ((${#PANTUM[@]} > 0)); then cp -f "${PANTUM[@]}" config/includes.chroot/opt/mse-drivers/pantum/; fi
if ((${#XPRINTER[@]} > 0)); then cp -f "${XPRINTER[@]}" config/includes.chroot/opt/mse-drivers/xprinter/; fi
shopt -u nullglob

if compgen -G "drivers/pantum/*.deb" >/dev/null; then
  echo "  Pantum: driver encontrado."
else
  echo "  AVISO: nenhum .deb Pantum em drivers/pantum/"
fi

if compgen -G "drivers/xprinter/*.deb" >/dev/null; then
  echo "  Xprinter: driver encontrado."
else
  echo "  AVISO: nenhum .deb Xprinter em drivers/xprinter/"
fi

echo "[3/6] Configurando Debian Live..."
lb config \
  --mode debian \
  --distribution trixie \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --security false \
  --binary-images iso-hybrid \
  --bootappend-live "boot=live components username=mse hostname=mse-linux quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0" \  --iso-application "MSE Linux" \
  --iso-publisher "MSE" \
  --iso-volume "MSE_LINUX_0_1"

echo "[4/6] Gerando ISO..."
lb build

echo "[5/6] Copiando saída..."
mkdir -p output
if [[ -f live-image-amd64.hybrid.iso ]]; then
  cp -f live-image-amd64.hybrid.iso output/mse-linux-v0.1-amd64.iso
elif [[ -f live-image-amd64.iso ]]; then
  cp -f live-image-amd64.iso output/mse-linux-v0.1-amd64.iso
else
  echo "ISO não encontrada após o build."
  exit 1
fi

echo "[6/6] Concluído."
echo "ISO: $PROJECT_DIR/output/mse-linux-v0.1-amd64.iso"
