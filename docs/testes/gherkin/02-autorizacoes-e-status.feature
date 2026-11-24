# language: pt
Funcionalidade: Autorizações e estado da proteção

  @api
  Esquema do Cenário: Restringir a edição dos aplicativos autorizados
    Dado que existe um perfil infantil vinculado
    Quando <origem> tenta alterar os aplicativos autorizados do perfil
    Então a API responde com HTTP <status>

    Exemplos:
      | origem                      | status |
      | o responsável do perfil     | 201    |
      | uma conta de outra família  | 403    |
      | o dispositivo vinculado     | 401    |

  @flutter
  Cenário: Consultar as fontes e exigir aceite antes da ativação
    Dado que o Kids está vinculado e o Android concedeu as permissões necessárias
    E o responsável autorizou o Discord pelo Pais
    Quando a criança consulta os aplicativos autorizados no Kids
    Então o Discord aparece em uma lista sem edição
    E a ativação só fica disponível depois do aceite

  @flutter @api
  Cenário: Confirmar a senha do responsável para pausar
    Dado que a proteção está ativa
    Quando a pausa é solicitada no Guardian Kids
    Então o app pede a senha do responsável
    E só pausa depois que a API confirma a senha

  @api
  Cenário: Rejeitar reporte de uma seleção antiga
    Dado que o Kids reportou proteção ativa com a seleção atual
    Quando o responsável muda os aplicativos autorizados no Pais
    E o Kids reporta novamente usando a seleção anterior
    Então a API responde com HTTP 409
    E aceita o reporte pausado com a seleção atualizada

  @flutter
  Esquema do Cenário: Mostrar o último estado confirmado no Pais
    Dado que o perfil infantil está vinculado
    E o Kids reportou o estado "<reporte>"
    Quando o painel é consultado com "<condição>"
    Então o status exibido é "<status>"

    Exemplos:
      | reporte | condição                                  | status                 |
      | ativo   | reporte recente e seleção atual           | Ativo                  |
      | pausado | reporte recente e seleção atual           | Pausado                |
      | ativo   | reporte recente de uma seleção anterior   | Aguardando atualização |
      | ativo   | reporte com 45 segundos ou mais           | Sem comunicação        |
