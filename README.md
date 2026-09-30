# MSE Linux v0.1

Distribuição Linux minimalista para uso do painel MSE no Google Chrome.

## Objetivo da v0.1

Fluxo principal:

1. Boot BIOS ou UEFI
2. Splash MSE com fundo preto
3. Login automático do usuário `mse`
4. Rede gerenciada pelo NetworkManager
5. Google Chrome aberto automaticamente em:
   https://msebrasil.com.br/painel/
6. Barra inferior mínima com rede e botão de desligar
7. Impressão por CUPS, USB e rede

## Base

- Debian 13 (Trixie), amd64
- live-build
- Xorg
- Openbox
- Tint2
- LightDM
- Google Chrome Stable
- CUPS / IPP / Avahi

## Impressoras-alvo

- Pantum M6550NW
- Xprinter XP-430B

Os drivers proprietários/oficiais dos fabricantes **não são redistribuídos neste pacote**.
Coloque os pacotes `.deb` oficiais nas pastas:

- `drivers/pantum/`
- `drivers/xprinter/`

O `build.sh` copia esses pacotes para a imagem e o hook de drivers tenta instalá-los.

## Requisitos para gerar a ISO

Execute em Debian 13/Ubuntu recente com privilégios administrativos:

```bash
sudo apt update
sudo apt install -y live-build debootstrap squashfs-tools xorriso isolinux syslinux-common \
  grub-pc-bin grub-efi-amd64-bin mtools dosfstools ca-certificates curl gnupg
```

## Gerar

```bash
chmod +x build.sh
sudo ./build.sh
```

A ISO será copiada para:

`output/mse-linux-v0.1-amd64.iso`

## Modo do Chrome

Nesta versão o Chrome abre maximizado, e não em quiosque, para preservar impressão, downloads
e o acesso à barra inferior do sistema.

Para trocar para quiosque, edite:

`config/includes.chroot/etc/xdg/openbox/autostart`

e substitua `--start-maximized` por `--kiosk`.

## Observação

A v0.1 é um protótipo funcional de build. Antes de uso em produção, valide a ISO em máquina virtual
e depois no hardware real, principalmente Wi-Fi, vídeo, Pantum M6550NW e Xprinter XP-430B.
