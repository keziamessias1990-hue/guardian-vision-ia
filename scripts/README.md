# Testar o Guardian no Android

O mesmo comando funciona no PowerShell do Windows e no Terminal do macOS ou Linux. Use a branch `feat/app-pai`. No GitHub, selecione essa branch antes de clicar em **Code → Download ZIP**, ou baixe com Git. Extraia o ZIP antes de abrir o terminal.

## Primeira execução no Windows

Em um Windows 10 ou 11 de 64 bits com processador Intel ou AMD, extraia o ZIP, abra o PowerShell na pasta `scripts` e execute:

```powershell
.\preparar-windows.cmd
```

O preparador usa o WinGet para instalar Git, Node.js e Android Studio quando necessário. Instala o Flutter 3.47.9 em `%LOCALAPPDATA%\Guardian`, usa o Java do Android Studio, configura o Android SDK, instala a imagem Android 35 e cria o emulador `Guardian_API_35`. Depois chama o mesmo script de exploração. As variáveis das ferramentas são configuradas para a sessão iniciada pelo comando.

- Para preparar e rodar o teste de ponta a ponta, use `.\preparar-windows.cmd -Modo e2e`.
- Para preparar a máquina sem iniciar o projeto, use `.\preparar-windows.cmd -SoPreparar`.
- Para rodar os testes de API e Flutter sem emulador, use `.\preparar-windows.cmd -Modo somente-testes`.

Na primeira execução, confirme os avisos dos instaladores e leia e aceite as licenças do SDK quando forem exibidas. Se faltar o WinGet, instale ou atualize o **App Installer** pela Microsoft Store. Se o emulador acusar falta de aceleração, [habilite a virtualização e a Plataforma do Hipervisor do Windows](https://developer.android.com/studio/run/emulator-acceleration), reinicie e rode o mesmo comando.

Se o PowerShell bloquear o arquivo extraído por ter sido baixado da internet, confirme que ele veio do repositório do Guardian, execute `Unblock-File .\preparar-windows.ps1` na pasta `scripts` e rode o preparador novamente. A política de execução do computador permanece como estava.

## Preparação manual no macOS, Linux ou Windows

- Instale Node.js com npm. Use a linha 22 a partir de 22.22.3, ou a linha 24 a partir de 24.15.0, para atender às dependências atuais.
- Instale Flutter e confirme que `flutter doctor` encontra o Android SDK. Aceite as licenças com `flutter doctor --android-licenses`.
- No Android Studio, instale **Android SDK Platform-Tools** e **Android SDK Build-Tools** e crie um emulador Android com **API 33 ou superior** no **Device Manager**. Se houver vários emuladores, abra só o desejado. Para o primeiro teste, deixe o Android desbloqueado e em modo retrato.
- Para o E2E, mantenha o JDK do Android Studio instalado. Se ele estiver em outro caminho, defina `JAVA_HOME` apontando para o JDK.

## Comandos na pasta scripts

Abra o terminal na pasta `scripts` do projeto e escolha um comando.

| Comando | Resultado |
| --- | --- |
| `node testar-guardian.cjs` | Roda os testes da API e dos dois apps. Abre o emulador, instala as versões de teste, abre os apps e mantém a API disponível para explorar. |
| `node testar-guardian.cjs --e2e` | Roda os testes e automatiza cadastro infantil, autorização, pareamento, ativação e o envio de duas notificações externas fictícias. Confere o resultado na API e no Guardian Pais. |
| `node testar-guardian.cjs --somente-testes` | Roda os testes automatizados da API e Flutter. Pode ser usado sem abrir o emulador. |

Se estiver na raiz do projeto, use `node scripts/testar-guardian.cjs` com as mesmas opções. O script executa a versão da pasta baixada. Em uma cópia Git, atualize a branch com `git pull --ff-only` quando houver uma nova versão.

## Explorar os apps

No Terminal, pressione `1` para abrir o Pais, `2` para abrir o Kids e `q` para encerrar a API. A tela também mostra a conta fictícia inicial. Mantenha o Terminal aberto enquanto explora. Os dados dessa sessão ficam em `backend/data/execucoes-android/familia.json` e podem ser reutilizados na próxima execução.

O modo E2E usa uma base nova e instalações Android exclusivas com final `.e2e`. Ele limpa apenas os dados dessas instalações ao começar e concede o acesso necessário para o teste no emulador. O emissor fictício está separado dos dois apps e usa a mesma via de notificações do Android. Ao concluir ou falhar depois da concessão, o roteiro retira a permissão de leitura da instalação E2E. As capturas e o resultado ficam na pasta indicada no Terminal, dentro de `backend/data/execucoes-android/`.

O teste usa mensagens fictícias. Ele verifica o caminho Android → Kids → API → Pais. A disponibilidade de prévias em aplicativos reais depende de cada origem e de como ela publica a notificação.
