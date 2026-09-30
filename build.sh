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

# Remove somente os arquivos gerados pelo lb config de uma tentativa anterior.
# Os includes, hooks, listas de pacotes e demais arquivos do projeto são preservados.
rm -f config/common config/bootstrap config/chroot config/binary config/source

lb config \
  --mode debian \
  --distribution trixie \
  --architectures amd64 \
  --archive-areas "main contrib non-free non-free-firmware" \
  --debian-installer none \
  --security false \
  --binary-images iso-hybrid \
  --linux-flavours amd64 \
  --bootappend-live "boot=live components username=mse hostname=mse-linux quiet splash loglevel=3 systemd.show_status=false vt.global_cursor_default=0" \
  --iso-application "MSE Linux" \
  --iso-publisher "MSE" \
  --iso-volume "MSE_LINUX_0_1"

# Algumas versões antigas de live-build podem manter defaults incompatíveis com
# Debian 13. Garanta que o repositório legado trixie/updates não seja habilitado.
if [[ -f config/common ]]; then
  sed -i 's/^LB_SECURITY=.*/LB_SECURITY="false"/' config/common
fi

if grep -Rqs "security.debian.org.*trixie/updates" config/common config/bootstrap config/chroot config/binary 2>/dev/null; then
  echo "ERRO: o live-build ainda configurou o repositório legado trixie/updates."
  grep -R "security.debian.org.*trixie/updates" config/common config/bootstrap config/chroot config/binary 2>/dev/null || true
  exit 1
fi

echo "[4/6] Gerando ISO..."

# Compatibilidade com versões antigas do live-build (como algumas versões
# empacotadas pelo Ubuntu): elas procuram Contents-amd64.gz diretamente em
# dists/trixie/, mas no Debian o arquivo fica dentro da área main/.
LB_LINUX_IMAGE_SCRIPT="/usr/lib/live/build/lb_chroot_linux-image"
LB_LINUX_IMAGE_BACKUP=""

if [[ -f "$LB_LINUX_IMAGE_SCRIPT" ]] && grep -q '/dists/\${LB_PARENT_DISTRIBUTION}/Contents-' "$LB_LINUX_IMAGE_SCRIPT"; then
  echo "  Ajustando lb_chroot_linux-image para o layout atual dos mirrors Debian..."
  LB_LINUX_IMAGE_BACKUP="$(mktemp)"
  cp -a "$LB_LINUX_IMAGE_SCRIPT" "$LB_LINUX_IMAGE_BACKUP"

  sed -i \
    -e 's#/dists/\${LB_PARENT_DISTRIBUTION}/Contents-#/dists/\${LB_PARENT_DISTRIBUTION}/main/Contents-#g' \
    -e 's#/dists/\${LB_DISTRIBUTION}/Contents-#/dists/\${LB_DISTRIBUTION}/main/Contents-#g' \
    "$LB_LINUX_IMAGE_SCRIPT"
fi

restore_live_build_script() {
  if [[ -n "$LB_LINUX_IMAGE_BACKUP" && -f "$LB_LINUX_IMAGE_BACKUP" ]]; then
    cp -a "$LB_LINUX_IMAGE_BACKUP" "$LB_LINUX_IMAGE_SCRIPT"
    rm -f "$LB_LINUX_IMAGE_BACKUP"
  fi
}
trap restore_live_build_script EXIT

# Força IPv4 em todas as chamadas ao wget executadas pelo live-build.
# Algumas etapas do live-build chamam wget diretamente no host.
WGET_WRAPPER_DIR="/tmp/mse-wget-ipv4"
mkdir -p "$WGET_WRAPPER_DIR"
cat > "$WGET_WRAPPER_DIR/wget" <<'EOF'
#!/usr/bin/env bash
exec /usr/bin/wget -4 "$@"
EOF
chmod +x "$WGET_WRAPPER_DIR/wget"
export PATH="$WGET_WRAPPER_DIR:$PATH"

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
