# Cenários Gherkin do Guardian Vision IA

No projeto atual, os cenários ficam em `docs/testes/gherkin/`. Use um arquivo `.feature` por fluxo e coloque `# language: pt` na primeira linha. Os arquivos descrevem comportamentos já exercitados pelos testes existentes. A execução automatizada continua nos scripts Node.js e nos testes Flutter. O cenário marcado com `@behave` também pode ser executado diretamente. Os demais cenários documentam a cobertura existente.

## Onde cada teste roda

| Etiqueta | Cobertura no projeto | Comando a partir da pasta `scripts` |
| --- | --- | --- |
| `@api` | `backend/scripts-integration.cjs` valida HTTP, autenticação, isolamento, pareamento, autorizações e contrato de alertas. | `node testar-guardian.cjs --somente-testes` |
| `@flutter` | `apps/guardian_pais/test/` e `apps/guardian_kids/test/` validam formulários, menus e estados de proteção. | `node testar-guardian.cjs --somente-testes` |
| `@e2e` | `scripts/guardian-android-e2e.cjs` automatiza os dois apps no emulador com um emissor fictício. | `node testar-guardian.cjs --e2e` |

O modo `--somente-testes` também roda o teste Jest do backend. O modo `--e2e` inclui as mesmas verificações e depois executa o fluxo Android. No Windows, o preparador pode fazer a instalação inicial e iniciar o fluxo com `.\preparar-windows.cmd -Modo e2e`.

As etiquetas indicam a automação correspondente. Vários cenários podem descrever verificações feitas na mesma execução. O E2E exercita notificações do Android por meio de um emissor fictício. A disponibilidade de prévias por aplicativos reais exige teste próprio.

## Como adicionar outro cenário

Copie um cenário do fluxo que você quer ampliar. Use **Dado** para a condição inicial, **Quando** para a ação e **Então** para o resultado observável. Para casos que variam só nos dados ou no resultado, use **Esquema do Cenário** com **Exemplos**. Se ainda não houver automação para o comportamento, marque o cenário com `@manual` e mantenha a diferença explícita ao revisar a cobertura.

Veja os [comandos Behave e Maestro](../pilotos/README.md) para rodar o pareamento em Gherkin e o teste de abertura no Android.
