# language: pt
Funcionalidade: Alertas de notificações externas

  @e2e
  Cenário: Receber uma notificação neutra
    Dado que a proteção está ativa no Kids
    E o emissor fictício está autorizado
    Quando o emissor publica uma notificação com uma mensagem neutra
    Então a API permanece sem alertas para esse perfil

  @e2e
  Cenário: Receber um sinal de risco em uma notificação externa
    Dado que a proteção está ativa no Kids
    E o emissor fictício está autorizado
    Quando o emissor publica uma notificação com pedido de segredo e convite para outro aplicativo
    Então a API registra um único alerta de risco elevado na categoria pedido de segredo
    E o Guardian Pais mostra o alerta no perfil vinculado com origem "Notificação analisada pelo Guardian Kids"
    E o alerta não contém o texto da notificação

  @api
  Esquema do Cenário: Rejeitar campos que excedem o contrato do alerta
    Dado que um Kids está vinculado e pode enviar um evento
    Quando o evento inclui o campo adicional "<campo>"
    Então a API responde com HTTP 400

    Exemplos:
      | campo       |
      | text        |
      | summary     |
      | packageName |

  @api
  Cenário: Isolar alertas entre famílias
    Dado que um dispositivo da primeira família enviou um alerta
    Quando os responsáveis das duas famílias consultam seus alertas
    Então apenas o responsável da primeira família vê esse alerta
    E a API rejeita a contestação feita pela segunda família

  @api
  Cenário: Bloquear um dispositivo que perdeu o vínculo
    Dado que um Kids está vinculado a um perfil infantil
    Quando o responsável revoga o vínculo
    Então a API rejeita novos alertas desse dispositivo com HTTP 401
    E rejeita a consulta da proteção e os reportes de estado desse dispositivo
