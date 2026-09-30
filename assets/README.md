# Assets do MSE Linux

A tela de inicialização utiliza a imagem MSE com fundo preto definida no projeto.

Arquivos esperados:

- `assets/mse-splash-1920x1080.png`
- `config/includes.chroot/usr/share/plymouth/themes/mse/mse-logo.png`

Os arquivos binários PNG devem ser copiados do pacote de projeto `mse-linux-v0.1-projeto.zip`.
O código de build permanece funcional sem o PNG, mas nesse caso mantém o tema Plymouth padrão.
