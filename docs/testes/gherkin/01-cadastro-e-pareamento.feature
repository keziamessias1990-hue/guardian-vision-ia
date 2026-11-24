# language: pt
Funcionalidade: Cadastro e pareamento da família

  @flutter
  Cenário: Impedir cadastro do responsável com dados inválidos
    Dado que o responsável abriu o formulário de acesso no Guardian Pais
    Quando tenta cadastrar com e-mail vazio e senha vazia
    Então o formulário informa que o e-mail é inválido
    E pede uma senha de 12 a 256 caracteres

  @flutter
  Cenário: Cancelar e reabrir o cadastro infantil
    Dado que o responsável iniciou o cadastro de um perfil infantil
    E preencheu o nome do perfil
    Quando cancela o cadastro e abre o formulário novamente
    Então o formulário abre sem erro com o nome em branco
    E apresenta a faixa etária padrão "11-13"

  @e2e
  Cenário: Cadastrar e vincular um perfil pelo emulador
    Dado que o responsável entrou com uma conta fictícia no Guardian Pais
    Quando cria um perfil infantil e gera o código de pareamento
    E confirma o código no Guardian Kids
    Então o perfil cadastrado aparece no painel do Pais
    E o Kids mostra "Dispositivo vinculado"

  @api @behave
  Cenário: Aceitar um código curto apenas uma vez
    Dado que o responsável gerou um código de pareamento para seu perfil infantil
    Quando o código é informado no Kids em minúsculas e com espaço no lugar do hífen
    Então a API confirma o pareamento
    E uma nova tentativa com o mesmo código recebe HTTP 401
