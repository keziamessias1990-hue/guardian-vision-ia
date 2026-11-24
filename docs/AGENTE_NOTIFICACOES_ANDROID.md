# Guardian Vision IA · Agente Android de notificações

## Ativação e privacidade

1. O responsável entra no Guardian Pais, cadastra o perfil infantil e gera um código de pareamento. No Guardian Kids, a família confirma o código.
2. No Pais, abra **Menu → Autorizações** e selecione WhatsApp, Discord, Telegram ou Roblox. No Kids, abra **Proteção**, consulte os aplicativos autorizados e marque o aceite depois de ler a explicação com a criança. A opção de jogo só cobre notificações classificadas como mensagens que exponham uma prévia ao Android. Nenhum aplicativo vem selecionado.
3. Autorize o acesso a notificações nos ajustes do Android e permita que o Kids mostre o aviso de proteção ativa. Volte ao Kids e toque em **Ativar alertas automáticos**. O aviso do Android abre os controles do Kids.
4. Para interromper, use **Pausar análise** e confirme a senha do responsável, retire o acesso nos ajustes ou dispense o aviso quando o Android oferecer essa opção. O serviço verifica a presença do aviso antes de ler a prévia e antes de iniciar o envio. Um pedido HTTP já iniciado pode chegar à API após uma pausa local. O responsável pode revogar o vínculo pelo endpoint de revogação da API.

O agente usa apenas as prévias de notificações novas, da categoria mensagem, dos pacotes selecionados, com o aparelho desbloqueado. Resumos de grupo, notificações contínuas e conteúdo marcado como secreto são ignorados. O motor Dart roda em uma instância Flutter sem interface. O Kids não tem campo para escrever mensagens. Apenas a análise síncrona recebe a prévia, com limite de 1.000 caracteres. O fluxo de rede recebe categoria e gravidade. O agente não grava texto, títulos, remetentes, anexos nem nomes de apps. A deduplicação em memória usa apenas a chave interna da notificação e o horário, em até 128 entradas.

O Kids guarda o token e o identificador do perfil em arquivo criptografado com o Android Keystore, fora do backup do sistema. O vínculo volta ao abrir o app após um reinício do processo. O Kids também guarda a seleção previamente aceita. Ao reabrir, retoma a análise se a API confirmar a mesma seleção e as permissões e o aviso do Android estiverem disponíveis. Pausar com a senha do responsável invalida a aprovação armazenada. A desinstalação ou limpeza dos dados do app exige novo pareamento. O estado da proteção fica visível no Kids e o aviso do sistema precisa estar presente para a captura. Uma rejeição autenticada com HTTP 401 pausa a sessão automática. O Android pode omitir prévias, restringir notificações sensíveis ou agrupá-las. O agente não abre conversas, recupera histórico ou acompanha notificações do iOS. O motor usa regras em português e pode omitir riscos ou sinalizar mensagens inocentes. Conversas que ficam só na interface do jogo não são acessíveis ao agente. A v1 processa um evento por vez, sem fila offline ou reenvio automático. Eventos durante um envio ou sem rede podem ser perdidos.

Referências do Android: [NotificationListenerService](https://developer.android.com/reference/android/service/notification/NotificationListenerService), [proteção de notificações sensíveis no Android 15](https://developer.android.com/about/versions/15/behavior-changes-all).

## Configuração de fontes

O responsável autenticado escolhe os aplicativos por perfil em **Menu → Autorizações**. Perfis antigos com configuração ausente começam com uma lista vazia. O Kids usa o token do dispositivo para consultar as fontes e mostra a lista sem opções de edição. Enquanto o serviço do Kids está em execução, ele consulta a autorização aproximadamente a cada 15 segundos. Uma mudança efetiva pausa a análise e invalida o aceite anterior. A família deve revisar a seleção e confirmar a ativação no Kids. Sem confirmação recente da API, o agente suspende a análise em até 45 segundos. Se a seleção mudar entre a consulta e a ativação, o Kids pede nova confirmação. A pausa pelo Kids exige a senha do responsável. As permissões podem ser revogadas nos ajustes do Android.

A API aceita a lista em `POST /api/children/:id/protection` com sessão do responsável dono do perfil. O vínculo ativo consulta `GET /api/device/protection` com o token do dispositivo. Um token de dispositivo não pode alterar a lista.

O Kids envia à API apenas o estado ativo ou pausado e a revisão da configuração, sem texto de notificações nesse reporte. O servidor guarda o estado mais recente com o próprio horário. O Pais mostra **Ativo**, **Pausado**, **Aguardando atualização** ou **Sem comunicação** e a hora do último contato. O painel consulta a API aproximadamente a cada 15 segundos e marca como sem comunicação um reporte com 45 segundos ou mais. O Android pode suspender o processo em segundo plano.

## Contrato da API

Atualize primeiro o NestJS. O endpoint existente `POST /api/alerts` recebe o token Bearer do aparelho vinculado. Ele aceita dois valores de `source`: `guardian-kids-local` identifica registros legados do teste manual, e `guardian-kids-notification` é a análise automática. O modo demonstração do Pais fica no próprio app.

```json
{
  "childId": "<id do perfil vinculado>",
  "category": "secret-sharing",
  "severity": "high",
  "occurredAt": "2026-11-21T19:00:00.000Z",
  "confirmationState": "pending",
  "source": "guardian-kids-notification"
}
```

O agente envia sinais moderados ou elevados. As categorias aceitas são `secret-sharing`, `platform-change`, `personal-data` e `general-risk`. A API valida a janela de horário de 24 horas e recusa atributos fora do contrato, inclusive nome do aplicativo, prévia e resumo. O token precisa pertencer ao perfil informado e estar ativo. Em sucesso, a API devolve HTTP 201 com os campos aceitos, `id` e `contested`. Um responsável autenticado lê os alertas da sua família por `GET /api/alerts`. O campo de origem é informado pelo cliente autenticado e indica o fluxo de envio, sem atestação da mensagem. O Pais apresenta a origem e o caráter preliminar do sinal ao atualizar o painel. O protótipo não oferece push.

Use HTTPS. O agente aceita HTTP apenas na compilação debug com o endereço do host do emulador `10.0.2.2`. O servidor de desenvolvimento deve operar com perfis fictícios e sem exposição pública.

## Revisão jurídica e operação

A autorização do Android e o aceite no Kids são controles técnicos de transparência e ativação. Para uso com dados reais no Brasil, documente a finalidade, necessidade, proporcionalidade, melhor interesse e hipótese legal para cada operação, inclusive o processamento local de prévias que podem conter dados de terceiros ou dados sensíveis. Quando o tratamento se apoiar em consentimento para crianças, avalie o consentimento específico e destacado e a verificação razoável do responsável prevista na LGPD. O pareamento atual prova posse de um código. A verificação da condição de responsável legal é uma questão em aberto. [LGPD, arts. 6º, 7º, 11, 14 e 18](https://planalto.gov.br/ccivil_03/_ato2015-2018/2018/lei/l13709compilado.htm) · [Enunciado CD/ANPD nº 1/2023](https://bibliotecadigital.mj.gov.br/handle/1/10215)

Revise a aplicabilidade do ECA Digital e do seu regulamento, inclusive supervisão apropriada à idade, informação acessível, padrões protetivos e relatório de impacto. Antes de um piloto com dados reais, defina controlador e canal de atendimento, procedimentos de acesso, correção, eliminação e revogação, avaliação de risco e prazo de retenção. O armazenamento JSON do protótipo retém os eventos até intervenção administrativa, inclusive após revogação. Ele não tem expiração automática de alertas nem interface de exercício de direitos. [ECA Digital, Lei nº 15.211/2025](https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2025/lei/l15211.htm) · [Decreto nº 12.880/2026](https://www.planalto.gov.br/ccivil_03/_ato2023-2026/2026/decreto/d12880.htm)

Se houver distribuição pelo Google Play, revise o enquadramento de monitoramento parental, a descrição pública, a divulgação destacada, o aviso persistente exigido pela política e a declaração de segurança de dados. O manifesto já declara `isMonitoringTool=child_monitoring`. A presença dessa declaração não implica aprovação da publicação. [Política de aplicativos de monitoramento](https://support.google.com/googleplay/android-developer/answer/9888380?hl=pt-BR) · [Declaração isMonitoringTool](https://support.google.com/googleplay/android-developer/answer/12955211?hl=pt-BR)
