# UNITYCFX
## Descrição
A Framework **unitycfx** é uma ferramenta standalone desenvolvida para facilitar a criação de scripts para FiveM. Ela fornece um conjunto de ferramentas básicas e funcionalidades que simplificam o desenvolvimento, permitindo que os desenvolvedores se concentrem na lógica do jogo em vez de lidar com detalhes técnicos complexos.

## Recursos Principais
- Preparação de Consultas SQL: Prepare consultas SQL para execução posterior. 
- Execução de Consultas SQL: Execute consultas SQL no banco de dados selecionado.
- Geração de IDs Únicos: Crie IDs únicos de forma simples e eficiente.
- Comunicação Tunnel: Comunicação bidirecional entre o cliente e o servidor.
- Funcionalidades Clientes: Funcionalidades específicas do lado do cliente para interações com o jogo.
- Funcionalidades do Servidor: Funcionalidades específicas do lado do servidor para gerenciamento de jogadores e do mundo virtual.
- Ferramentas Auxiliares: Conjunto de ferramentas auxiliares para facilitar o desenvolvimento.
## Get Started
Para começar a utilizar a UnityCFX em seu projeto, basta declarar o arquivo unitycfx.lua no diretório compartilhado (shared) do seu manifesto do recurso (fxmanifest.lua).
```lua
shared_script {
    "unitycfx.lua"
}
```
## Banco de dados
**Usando banco de dados**
```sql
local db = import('db')
-- Preparar query
db:prepare("buscarUsuarios", "SELECT * FROM usuarios WHERE id = @id")

-- Executar query
local resultado = db:query("buscarUsuarios", { id = 5 })
```
**Geração de IDs Únicos**
```lua
-- Criar um novo gerador de IDs
local gerador = Tools.newIDGenerator()

-- Gerar um novo ID
local novoID = gerador:gen()

--liberar ID
gerador:free(id)

--Limpar ids reservados
gerador:clear()
```
**Comunicação Tunnel Client para Server**
```lua
-- função lado server
function lib.minhaFuncao(param)
    local source = source
end

-- chamada da função no client
lib.minhaFuncao(param)
```
**Comunicação Tunnel server para client**
```lua
-- função lado client
function lib.minhaFuncao(param)
    local source = source
end

-- chamda da função no server
lib.minhaFuncao(source,param)
```
## Funções
Todas as funções podem ser executada tanto do lado client ou server. Funções do lado serve para client e obrigatório o uso do parâmetro **source** como primeiro argumento.
1. **Functions.getTools()**
   - Descrição: Retorna um conjunto de ferramentas auxiliares.
   - Parâmetros: Nenhum.

2. **Functions.getIdentity(source, identity)**
   - Descrição: Obtém a identidade de um jogador com base em um identificador específico.
   - Parâmetros:
     - `source`: O ID do jogador.
     - `identity`: O tipo de identidade a ser obtida (por exemplo, "discord").

3. **Functions.log(webhook, message)**
   - Descrição: Registra uma mensagem em um webhook especificado.
   - Parâmetros:
     - `webhook`: O URL do webhook para registrar a mensagem.
     - `message`: A mensagem a ser registrada.

4. **Functions.format(n)**
   - Descrição: Formata um número para exibição.
   - Parâmetros:
     - `n`: O número a ser formatado.

5. **Functions.blockPlayer(status)**
   - Descrição: Bloqueia ou desbloqueia o jogador no jogo.
   - Parâmetros:
     - `status`: Um booleano indicando se o jogador deve ser bloqueado (true) ou desbloqueado (false).

6. **Functions.createObject(dict, anim, prop, flag, hand)**
   - Descrição: Cria um objeto no jogo e o vincula ao jogador.
   - Parâmetros:
     - `dict`: O dicionário de animação do objeto.
     - `anim`: A animação a ser reproduzida.
     - `prop`: O modelo do objeto a ser criado.
     - `flag`: As bandeiras de criação do objeto.
     - `hand`: O osso da mão ao qual o objeto será vinculado.

7. **Functions.deleteObject()**
   - Descrição: Deleta o objeto criado anteriormente pelo jogador.
   - Parâmetros: Nenhum.

8. **Functions.playAnim(upper, dict, name, looping)**
   - Descrição: Reproduz uma animação no jogador.
   - Parâmetros:
     - `upper`: Um booleano indicando se a animação é superior (true) ou inferior (false).
     - `dict`: O dicionário de animação.
     - `name`: O nome da animação.
     - `looping`: Um booleano indicando se a animação deve ser reproduzida em loop (true) ou não (false).

9. **Functions.stopAnim(upper)**
   - Descrição: Interrompe uma animação em execução no jogador.
   - Parâmetros:
     - `upper`: Um booleano indicando se a animação superior deve ser interrompida (true) ou não (false).

10. **Functions.getPosition()**
   - Descrição: Obtém a posição atual do jogador.
   - Parâmetros: Nenhum.

11. **Functions.addBlip(x, y, z, idtype, idcolor, text, scale, route)**
   - Descrição: Adiciona um marcador (blip) no mapa do jogo.
   - Parâmetros:
     - `x`: A coordenada X do marcador.
     - `y`: A coordenada Y do marcador.
     - `z`: A coordenada Z do marcador.
     - `idtype`: O tipo de ícone do marcador.
     - `idcolor`: A cor do marcador.
     - `text`: O texto a ser exibido ao lado do marcador (opcional).
     - `scale`: A escala do marcador (opcional).
     - `route`: Se verdadeiro, exibe uma rota para o marcador (opcional).

12. **Functions.removeBlip(id)**
   - Descrição: Remove um marcador (blip) do mapa do jogo.
   - Parâmetros:
     - `id`: O ID do marcador a ser removido.

13. **Functions.drawText3D(x, y, z, text, scale)**
   - Descrição: Desenha um texto tridimensional no jogo.
   - Parâmetros:
     - `x`: A coordenada X do texto.
     - `y`: A coordenada Y do texto.
     - `z`: A coordenada Z do texto.
     - `text`: O texto a ser exibido.
     - `scale`: A escala do texto (opcional).

14. **Functions.teleport(x, y, z)**
   - Descrição: Teleporta o jogador para as coordenadas especificadas.
   - Parâmetros:
     - `x`: A coordenada X do destino.
     - `y`: A coordenada Y do destino.
     - `z`: A coordenada Z do destino.

15. **Functions.distance(x, y, z, distance)**
   - Descrição: Verifica se o jogador está a uma certa distância de um ponto específico.
   - Parâmetros:
     - `x`: A coordenada X do ponto.
     - `y`: A coordenada Y do ponto.
     - `z`: A coordenada Z do ponto.
     - `distance`: A distância máxima permitida.

16. **Functions.playSound(dict, name)**
   - Descrição: Toca um som no cliente.
   - Parâmetros:
     - `dict`: O dicionário do som.
     - `name`: O nome do som.

17. **Functions.getVehicle(radius)**
   - Descrição: Obtém o veículo mais próximo do jogador dentro de um determinado raio.
   - Parâmetros:
     - `radius`: O raio de busca para encontrar o veículo mais próximo.



