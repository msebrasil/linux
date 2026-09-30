# Plano técnico — MSE Linux v0.1

## Decisões fechadas

- Nome de trabalho: MSE Linux
- Versão: 0.1
- Arquitetura inicial: amd64
- Base: Debian 13 (Trixie)
- Interface: Xorg + Openbox
- Painel: Tint2
- Sessão: LightDM com autologin do usuário `mse`
- Navegador: Google Chrome Stable
- URL: https://msebrasil.com.br/painel/
- Modo do navegador: maximizado, não quiosque
- Boot splash: fundo preto + logo MSE
- Rede: NetworkManager + nm-applet
- Impressão: CUPS + Avahi + IPP + USB/rede
- Impressoras prioritárias: Pantum M6550NW e Xprinter XP-430B
- Desligamento: botão na barra inferior com confirmação

## Testes obrigatórios antes de considerar v0.1 pronta

1. Boot BIOS
2. Boot UEFI
3. Rede Ethernet
4. Wi-Fi e reconexão após reboot
5. Chrome abre automaticamente
6. URL correta
7. Impressão pelo Chrome
8. Pantum M6550NW via USB
9. Pantum M6550NW via rede/Wi-Fi
10. Xprinter XP-430B via USB
11. Formato/tamanho de etiqueta correto na Xprinter
12. Botão de desligar
13. Reinício sem corromper a mídia
14. Teste em pendrive
15. Teste em cartão SD quando o hardware oferecer boot pelo leitor

## Fora do escopo da v0.1

- Atualizador automático próprio
- Instalador gráfico próprio
- Criptografia de persistência
- Sistema de módulos hot-plug completo
- Gerenciamento remoto
- ARM
