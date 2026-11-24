# Sprint 1 — Integração Guardian (protótipo técnico)

## Para executar no Mac
1. `cd backend && npm ci && npm run start:dev`
2. No Guardian Pais, `flutter pub get && flutter run --dart-define=GUARDIAN_API_URL=http://10.0.2.2:3000/api` (Android Emulator); no simulador iOS use `http://127.0.0.1:3000/api`.
3. No Guardian Kids, o mesmo `flutter pub get` e `flutter run` com URL correspondente.
4. Pais: botão de acesso → cadastrar/login → adicionar criança → gerar código → copiar para Kids.
5. Kids: Parear → digitar código → analisar texto fictício `segredo Discord`.
6. Pais: atualização automática a cada 15 segundos, ou abrir novamente; conferir alerta e contestar.
7. Prova da API: com servidor em execução, `node backend/scripts-integration.cjs` na raiz. O teste cria contas exclusivamente fictícias e grava `backend/evidence-integration.json`.

## Limitações importantes
- Persistência local JSON em `backend/data/guardian-dev.json`, não adequada a produção, escalabilidade ou dispositivos reais.
- Tokens parentais e infantis ficam apenas na memória dos aplicativos; fechar o app exige novo login/pareamento. Na próxima fase, adicionar armazenamento seguro, sessão renovável e revogação completa.
- O código de pareamento tem validade de 5 minutos, uso único e revogação pelo responsável; é exibido como texto de uso único (QR visual ainda não implementado).
- Não há captura de outros aplicativos. Somente texto digitado voluntariamente dentro do Kids é analisado e apagado localmente.
- Teste automatizado cobre HTTP real e payload, mas capturas de tela e teste Flutter em simulador precisam ser executados no Mac.
- Backend é protótipo para ambiente local. Para produção: banco transacional, rate limit e bloqueio de tentativas, HTTPS, trilha de auditoria, proteção de dados infantis, controle de credenciais e revisão jurídica.
- Não inclua `backend/data/` ou arquivos de evidência com dados reais em commits.
