build:
	docker compose build

up:
	docker compose up

down:
	docker compose down

setup:
	docker compose run web bin/rails db:create db:migrate db:seed

migrate:
	docker compose run web bin/rails db:migrate

test-setup:
	docker compose run test bin/rails db:create db:migrate RAILS_ENV=test