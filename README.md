## Shopping Cart

## Pré-requisitos

- Docker
- docker-compose
- Make (opcional, para usar os comandos simplificados)

## Inicializando o Projeto

### 1. Clone o repositório
```bash
git clone https://github.com/ViniciusLisboa07/shopping-cart
cd shopping-cart
```

### 2. Construa as imagens Docker
```bash
make build
# ou
docker compose build
```

### 3. Configure o banco de dados
```bash
make setup
# ou
docker compose run web bin/rails db:create db:migrate db:seed
```

### 4. Inicie a aplicação
```bash
make up
# ou
docker compose up
```

A aplicação estará disponível em: http://localhost:3000

## Executando Testes

### Configurar ambiente de teste (primeira vez)
```bash
make test-setup
```

## Executando Testes

```bash
make run-tests
# ou
docker compose run test bundle exec rspec
```

## API Endpoints

### 🛒 Carrinho de Compras

#### 1. Adicionar produto ao carrinho
```http
POST /cart
Content-Type: application/json

{
  "product_id": 1,
  "quantity": 2
}
```

#### 2. Visualizar carrinho atual
```http
GET /cart
```

#### 3. Alterar quantidade de produto
```http
POST /cart/add_item
Content-Type: application/json

{
  "product_id": 1,
  "quantity": 1
}
```

#### 4. Remover produto do carrinho
```http
DELETE /cart/:product_id
```
## Estrutura do Projeto

```
app/
├── controllers/          # Controladores da API
├── models/              # Modelos ActiveRecord
├── services/            # Lógica de negócio
├── serializers/         # Serialização JSON
├── sidekiq/             # Jobs em background
└── jobs/                # Jobs do Rails

spec/
├── factories/           # Factories para testes
├── services/            # Testes dos services
├── models/              # Testes dos models
├── requests/            # Testes de API
└── sidekiq/             # Testes dos jobs
```