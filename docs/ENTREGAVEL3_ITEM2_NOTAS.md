# Entregável 3 / Item 2 — integração e evidências

O documento acadêmico editável acompanha esta Sprint em `/Guardian_Entregavel3_Item2.docx` (entregue separadamente).

## Mudanças nesta versão
- No Kids, um alerta de risco heurístico passa por confirmação antes de qualquer envio.
- O texto digitado permanece apenas em memória local e é apagado do campo após a análise; o evento enviado contém apenas os seis campos do contrato.
- O aviso de privacidade do Kids foi alinhado ao comportamento real: após consentimento de envio, metadados mínimos seguem para API.
- No Pais, a opção Sair limpa o token parental em memória e a UI reflete ausência de autenticação. **O servidor ainda não invalida o token: não é logout seguro de produção.**
- O teste de integração HTTP foi ampliado com tentativas sem token, com token parental no lugar do infantil e com campo `text` proibido.

## O que registrar nas capturas
1. Login e perfil fictício dos pais.
2. Código temporário mascarado.
3. Análise no Kids com texto fictício e confirmação de envio.
4. Alertas do Pais com severidade e horário.
5. Log de integração após execução real e dados redigidos.

## Avisos
- Capturas e validação Flutter **não foram realizadas** neste ambiente.
- Não há IA treinada/validada nesta versão; a detecção é por palavras-chave.
- O backend grava dados em JSON local e não é adequado para uso real com crianças.
- Uma análise negativa não garante segurança; falso positivo também é possível.
- Para execução de dispositivo físico, configurar um endereço de rede acessível e HTTPS; `10.0.2.2` é exclusivo do Android Emulator.
