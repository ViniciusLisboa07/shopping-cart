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

## Serviços

- **Web**: Aplicação Rails (porta 3000)
- **DB**: PostgreSQL (porta 5432)
- **Redis**: Cache e jobs (porta 6379)
- **Sidekiq**: Processamento de jobs em background