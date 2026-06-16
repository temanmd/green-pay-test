.DEFAULT_GOAL := help
.PHONY: help up upd down reset build logs ps console bash test rspec rubocop migrate

help: ## Показать список команд
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

up: ## Собрать образы, поднять Postgres + app, подготовить БД, отдать API на :3000 (Ctrl-C — стоп)
	docker compose up --build

upd: ## То же, но в фоне (detached)
	docker compose up --build -d

down: ## Остановить и удалить контейнеры (данные БД сохраняются)
	docker compose down

reset: ## Полный сброс: удалить контейнеры ВМЕСТЕ с томом БД
	docker compose down -v

build: ## Пересобрать образ app
	docker compose build

logs: ## Стримить логи всех сервисов
	docker compose logs -f

ps: ## Статус контейнеров
	docker compose ps

console: ## Rails-консоль внутри контейнера
	docker compose exec app bin/rails console

bash: ## Shell внутри контейнера app
	docker compose exec app bash

test: ## Прогнать весь RSpec в контейнере (создаёт тестовую БД при необходимости)
	docker compose run --rm -e RAILS_ENV=test app bash -c "bin/rails db:prepare && bundle exec rspec"

rspec: test ## Алиас для test

rubocop: ## Запустить RuboCop в контейнере
	docker compose run --rm app bundle exec rubocop

migrate: ## Накатить миграции
	docker compose exec app bin/rails db:migrate
