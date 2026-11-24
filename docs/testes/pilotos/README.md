# Behave e Maestro no Guardian

O **Behave** executa cenários Gherkin em português. O **Maestro** automatiza a interface Android. Cada ferramenta tem um papel, e os comandos existentes continuam disponíveis.

| Comando na raiz do projeto | O que verifica |
| --- | --- |
| `node scripts/testar-guardian.cjs --behave` | Sobe uma API local com base descartável e roda os cenários marcados com `@behave`. |
| `node scripts/testar-guardian.cjs --maestro` | Compila e instala versões isoladas dos dois apps, abre cada um e confere a tela inicial no emulador. |
| `node scripts/testar-guardian.cjs --somente-testes` | Roda a suíte atual da API e do Flutter. |
| `node scripts/testar-guardian.cjs --e2e` | Roda o teste completo de uma notificação externa fictícia até o alerta no Pais. |

Os relatórios de cada execução ficam na pasta indicada no Terminal, dentro de `backend/data/execucoes-android/`. As ferramentas são instaladas apenas se for usar seus respectivos comandos.

## Behave

Crie um ambiente virtual e instale as dependências uma vez. No PowerShell, a partir da raiz:

```powershell
python -m venv backend/data/behave-venv
.\backend\data\behave-venv\Scripts\python.exe -m pip install -r docs/testes/gherkin/requirements.txt
node scripts/testar-guardian.cjs --behave
```

No macOS ou Linux, use `python3 -m venv backend/data/behave-venv` e `backend/data/behave-venv/bin/python -m pip install -r docs/testes/gherkin/requirements.txt`. Se o Behave estiver em outro ambiente virtual, indique o executável Python na variável `GUARDIAN_BEHAVE_PYTHON`.

Se você usa o preparador do Guardian, também pode executar `.\scripts\preparar-windows.cmd -Modo behave` na raiz depois de instalar o Behave.

Os arquivos `.feature` ficam em `docs/testes/gherkin/` e os passos Python em `docs/testes/gherkin/steps/`. Marque com `@behave` apenas os cenários que tenham todos os passos implementados. Atualmente o cenário executável é o **pareamento de uso único**. [Documentação Behave](https://behave.readthedocs.io/en/stable/gherkin/)

## Maestro

Instale o [Maestro CLI](https://docs.maestro.dev/maestro-cli/how-to-install-maestro-cli) e execute `node scripts/testar-guardian.cjs --maestro` na raiz, em um terminal que tenha acesso ao emulador Android. Se o CLI estiver fora do PATH, indique seu executável em `GUARDIAN_MAESTRO_BIN`.

Se o Flutter foi instalado pelo preparador, use `.\scripts\preparar-windows.cmd -Modo maestro` num PowerShell com acesso ao Maestro CLI.

O YAML fica em `docs/testes/pilotos/maestro/`. O comando instala versões com o sufixo `.maestro`, usa uma base fictícia separada e encerra a API ao terminar. As instalações de exploração `.teste` conservam seus dados. O teste atual confirma a abertura dos dois apps. O teste com notificações continua no modo E2E.
