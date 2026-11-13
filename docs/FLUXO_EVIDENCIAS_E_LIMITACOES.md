# Guardian Vision IA — Fluxo, evidências e limitações

**Atualizado em 12 de novembro de 2026**  
**Estado do projeto:** protótipo demonstrativo, sem contas reais, persistência, pareamento ou monitoramento automático de conversas.

## 1. Escopo que funciona hoje

O Guardian Vision possui dois aplicativos Flutter e uma API NestJS local:

- **Guardian Kids:** apresenta uma interface acolhedora, permite que a criança informe como está e analise manualmente um texto de teste por palavras-chave locais.
- **Guardian Pais:** apresenta um painel familiar, consulta perfis e alertas da API quando ela está acessível e possui dados de demonstração para mostrar o fluxo visual.
- **API NestJS:** expõe endpoints locais de saúde, crianças e alertas com dados mantidos apenas em memória.

O protótipo não lê mensagens de WhatsApp, Discord, Telegram ou outros aplicativos. Ele também não envia notificações reais, não possui login e não conecta de fato o Guardian Kids ao Guardian Pais.

## 2. Fluxo atual demonstrável

### 2.1 Guardian Kids: análise voluntária local

1. A criança abre o Guardian Kids.
2. A tela apresenta as ações “Estou com medo”, “Meu pai” e “Preciso de ajuda”.
3. A criança pode digitar um **texto fictício** no campo “Mensagem de teste”.
4. O app verifica localmente palavras e expressões de demonstração, como pedido de segredo, mudança de plataforma ou pedido de dados pessoais.
5. O resultado é exibido apenas na tela do próprio app.
6. O campo é limpo após a análise.

Os botões de ajuda exibem orientações. Eles não enviam mensagem, alerta ou chamada a um responsável. Essa limitação deve permanecer explícita na interface.

### 2.2 Guardian Pais: painel e consulta local

1. O responsável abre o Guardian Pais.
2. A home tenta consultar os endpoints `/api/children` e `/api/alerts`.
3. Quando a API não responde, a interface preenche o painel com dados de demonstração para manter o protótipo navegável.
4. O responsável visualiza crianças, contadores e alertas demonstrativos.
5. O alerta mostra categoria, severidade e estado de confirmação.
6. A ação “Contestar resultado” registra apenas um estado local da tela; ela não é persistida na API.

### 2.3 Fluxo alvo: pareamento e evento mínimo

O fluxo abaixo é o próximo passo técnico. Ele **ainda não está implementado**:

1. O responsável cria uma conta e um perfil infantil no Guardian Pais.
2. A API cria uma solicitação de pareamento de uso único e curta duração.
3. O Guardian Pais exibe um QR Code ou link de pareamento.
4. A criança abre o Guardian Kids, escaneia o QR Code ou acessa o link e confirma o vínculo.
5. A API registra o dispositivo, a família e a confirmação bilateral.
6. Quando a criança analisa voluntariamente um conteúdo, o Guardian Kids mantém o texto no dispositivo e envia somente um evento mínimo.
7. O Guardian Pais exibe o alerta e, no futuro, recebe uma notificação genérica sem conteúdo sensível na tela bloqueada.

O evento mínimo deve conter somente:

- identificador do perfil infantil;
- categoria limitada, como `secret-sharing`, `platform-change` ou `personal-data`;
- severidade;
- data e hora;
- estado de confirmação;
- origem declarada, como `manual-share` ou `guardian-kids-local`.

Ele não deve conter texto bruto, identificadores de terceiros, capturas de conversa nem token de acesso.

## 3. Evidências de teste disponíveis

### 3.1 Evidência visual

Foram fornecidas capturas do Android Emulator em 12 de novembro de 2026 mostrando:

- o Guardian Kids renderizado, com ações de apoio, campo de mensagem de teste e análise local manual;
- o Guardian Pais renderizado, com onboarding, contadores e perfil infantil de demonstração.

Essas capturas comprovam que as telas foram abertas no emulador. Elas não comprovam pareamento, notificação, leitura de mensagens externas ou persistência de dados.

### 3.2 Evidência automatizada do backend

Os seguintes comandos foram executados em 12 de novembro de 2026:

```bash
cd backend
npm test
npm run build
```

Resultado registrado:

- `npm test`: 1 suíte aprovada e 1 teste aprovado (`HealthService`).
- `npm run build`: build NestJS concluído com sucesso.

### 3.3 Evidência dos endpoints locais

Os endpoints abaixo responderam em uma instância local da API:

```text
GET http://127.0.0.1:3000/api/health
GET http://127.0.0.1:3000/api/children
GET http://127.0.0.1:3000/api/alerts
```

O endpoint de saúde respondeu:

```json
{"status":"ok","service":"guardian-api"}
```

Os endpoints de crianças e alertas retornaram dados demonstrativos em memória. Eles não são registros persistentes nem dados de famílias reais.

### 3.4 Como repetir a verificação

No computador que executa a API:

```bash
cd backend
npm run start:dev
```

Em outro terminal:

```bash
curl http://127.0.0.1:3000/api/health
curl http://127.0.0.1:3000/api/children
curl http://127.0.0.1:3000/api/alerts
```

Para validar os aplicativos:

```bash
cd apps/guardian_pais && flutter analyze && flutter test && flutter run
cd apps/guardian_kids && flutter analyze && flutter test && flutter run
```

## 4. Link e QR Code de pareamento

Não há link ou QR Code funcional no código atual. Gerar um QR Code agora sugeriria um pareamento que ainda não existe.

Quando autenticação e pareamento estiverem prontos, o QR Code deve carregar somente uma URL curta com token opaco de uso único, por exemplo:

```text
https://app.guardianvision.example/pair/<token-opaco>
```

O mesmo endereço pode abrir o Guardian Kids por App Link ou Universal Link. O token precisa expirar em poucos minutos, ser invalidado após o primeiro uso e nunca conter nome da criança, texto analisado, JWT, e-mail ou dado pessoal no próprio QR Code.

O backend deverá validar o token, exigir a confirmação do responsável e da criança ou dispositivo, registrar uma trilha de auditoria e permitir revogação do vínculo.

## 5. Limitações de acesso a plataformas

### Guardian Kids e Guardian Pais

Os dois apps podem ser conectados por uma API própria depois do pareamento. Essa é a integração recomendada para o MVP. O estado atual não tem autenticação, banco de dados, registro de dispositivo ou QR Code.

### iOS

Apps no iOS funcionam em sandbox e não têm acesso livre aos dados privados de outros apps. Portanto, o Guardian não pode ler conversas de WhatsApp, Discord ou Telegram instalados no dispositivo. A integração segura é o compartilhamento voluntário de um texto pela própria pessoa usuária. Consulte a documentação da Apple sobre [App Sandbox](https://developer.apple.com/documentation/security/protecting-user-data-with-app-sandbox).

### Android

Apps Android também funcionam em sandbox. Um `NotificationListenerService` existe tecnicamente, mas não deve ser adotado neste MVP para coletar conteúdo de mensagens. Aplicativos de monitoramento distribuídos pelo Google Play precisam ser identificados, visíveis, ter notificação persistente, declaração de finalidade e consentimento adequado; não podem se comportar como vigilância oculta. Consulte as [regras de monitoramento do Google Play](https://support.google.com/googleplay/android-developer/answer/18265346).

### WhatsApp

O WhatsApp não oferece acesso a conversas pessoais por API. A WhatsApp Business Platform atende mensagens entre uma empresa e usuários, não a leitura de chats pessoais de uma criança. Mensagens pessoais são protegidas por criptografia de ponta a ponta. Consulte [privacidade do WhatsApp](https://www.whatsapp.com/privacyquestions) e a [plataforma para empresas](https://whatsappbusiness.com/developers/developer-hub/).

### Discord

Uma integração permitida seria um bot em servidores nos quais o bot foi instalado. Ela não dá acesso geral às mensagens privadas da criança. O conteúdo de mensagens exige permissões específicas e revisão conforme as regras do Discord. Consulte [Privileged Intents](https://support-dev.discord.com/hc/en-us/articles/6207308062871-What-are-Privileged-Intents).

### Telegram

Um bot do Telegram recebe somente mensagens de conversas das quais participa, respeitando as configurações de privacidade do grupo. Ele não oferece acesso geral às conversas privadas da pessoa. Consulte as [perguntas frequentes de bots do Telegram](https://core.telegram.org/bots/faq).

## 6. Ajustes necessários antes de chamar a integração de funcional

### Prioridade alta

1. **Corrigir o endereço da API no Android Emulator.** O app Pais usa `127.0.0.1` e `localhost`; dentro do emulador Android esses endereços apontam para o próprio emulador, não para o computador. Em desenvolvimento Android, usar `http://10.0.2.2:3000/api`. A URL deve ser configurada por ambiente, e não por tentativa silenciosa de vários endereços.

2. **Indicar a origem dos dados na interface.** Atualmente, quando a API falha, o app Pais mostra dados fictícios sem um indicador visível de modo demonstração. A tela precisa exibir “Dados demonstrativos” ou “API indisponível” para não confundir a pessoa responsável.

3. **Corrigir a mensagem do Guardian Kids.** “Monitoramento local em funcionamento” dá a entender que existe acompanhamento contínuo. O que funciona é análise local manual de texto fornecido na tela. A mensagem deve ser “Análise local disponível para textos que você escolher”.

4. **Remover texto livre do contrato de alerta.** O endpoint atual aceita o campo `summary` livremente. Antes de integrar o Guardian Kids, esse campo deve ser substituído por categorias controladas ou validado para impedir texto bruto, nomes, telefones, endereços e identificadores de terceiros.

5. **Separar demonstração de produção.** O fallback com Guilherme e alertas fictícios deve existir apenas em modo demonstração explicitamente ativado, nunca como resposta silenciosa a erro de API.

### Próxima prioridade

6. Adicionar autenticação de responsável, banco de dados, perfis infantis, registro de dispositivo, pareamento de uso único e revogação.
7. Proteger endpoints por família e registrar auditoria de criação, confirmação, consulta e revogação de vínculo.
8. Adicionar testes de integração para `GET /children`, `GET /alerts` e `POST /alerts`, incluindo teste que prova a rejeição de texto bruto.
9. Usar HTTPS, configuração de ambiente e notificações genéricas somente depois de autenticação e revisão de privacidade.

## 7. Declaração de escopo para apresentação

> O Guardian Vision IA é um protótipo acadêmico de apoio à segurança digital familiar. Nesta versão, o Guardian Kids realiza análise voluntária e local de textos de teste por palavras-chave, enquanto o Guardian Pais apresenta dados demonstrativos e consulta endpoints locais de exemplo. O projeto não acessa conversas privadas de aplicativos de terceiros, não executa vigilância oculta, não possui pareamento real por QR Code, não envia notificações reais e não armazena dados de crianças. A integração futura seguirá o princípio de evento mínimo, com consentimento, vínculo familiar verificável e revisão jurídica antes de qualquer uso com dados reais.
