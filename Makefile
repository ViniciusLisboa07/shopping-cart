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

run-tests:
	docker compose run test bundle exec rspec

bash:
	docker exec -it shopping-cart-web-1 /bin/bash

bundle:
	docker compose run web bundle install