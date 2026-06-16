# Build progress log

Журнал коротких шагов. Каждый шаг = один коммит, делает человек-владелец репо.
См. также `CLAUDE.md` (конвенции) и `docs/decisions.md` (обоснования решений).

## Done

- **Step 0 — repo init** *(до начала работы, владелец)*
  `.gitignore`, `.rubocop.yml` + `.rubocop_todo.yml`, `.ruby-version` (4.0.5).

- **Step 1 — bootstrap Rails API**
  `rails new --api -d postgresql`, обрезанный под нужды payments-API.
  Выверенный `Gemfile` (panko, aasm, mutations, rspec, brakeman, isolator…).
  RSpec установлен, RuboCop зелёный, приложение бутается.
  Убрал из `.gitignore` `.rspec` и `db/schema.rb` (нужно коммитить).

- **Step 2 — Docker Compose + Makefile**
  Dev `Dockerfile` (ruby:4.0.5-slim + build-deps), Postgres 18 с healthcheck,
  app ждёт готовности БД. Entrypoint делает идемпотентный `db:prepare`.
  ENV-driven `database.yml`. Самодокументируемый `Makefile`.
  Проверено: `/up` → 200, `SELECT version()` → PostgreSQL 18.4.

- **Step 3 — context docs**
  `CLAUDE.md` (авто-подхват сессией), `docs/decisions.md` (ADR-001…009), этот журнал.

- **Step 4 — domain schema**
  Модели + миграции: `User`, `Account` (CHECK balance ≥ 0), `Order` (aasm-статусы),
  `Transaction` (append-only, знаковый `amount_cents`, unique `(order_id, kind)`,
  self-FK для reversal, `readonly?`). Все FK проиндексированы. Проверено smoke-скриптом.

- **Step 5 — RSpec request-харнесс**
  `rails_helper` (factory_bot, isolator, test-prof), `spec_helper` (SimpleCov по флагу),
  `ApiHelpers`, фабрики, health-спека. Добавлен `benchmark` (вынесен из stdlib в Ruby 4.0).

- **Step 6 — POST/GET users (первый TDD-срез)**
  Эволюция леджера под депозиты (`order_id` nullable, `kind=deposit`, CHECK-связка).
  `Users::Create` + `Accounts::Deposit` (mutations, лок + deposit-запись), panko-сериализаторы,
  `Api::BaseController` (404/422), роуты `/api/v1`. Спека red→green (7 примеров), проверено curl.

- **Step 7 — POST deposit**
  `POST /api/v1/accounts/:id/deposit` поверх `Accounts::Deposit`. `render_errors` вынесен
  в `Api::BaseController` (DRY). Спека red→green (3), проверено curl (1000→1500, 422, 404).

- **Step 8 — POST/GET orders**
  `Orders::Create` (валюта наследуется от счёта; user_id/amount валидируются → 422),
  `OrderSerializer`, `POST /orders` + `GET /orders/:id`. Спека red→green (6), проверено curl.

- **Step 9 — POST order success (ядро)**
  `Orders::Succeed`: `order.with_lock` → проверка статуса → `account.lock!` → проверка
  средств → settlement-запись (`-amount`) + дебет + `aasm succeed!`. Всё в одной транзакции,
  локи order→account. Спека red→green (5: успех, нехватка, повтор, cancelled, 404). Проверено curl.

- **Step 10 — POST order cancel (симметрия)**
  `Orders::Cancel`: из `succeeded` → reversal-запись (`+amount`, `reverses_transaction_id`) +
  кредит баланса + `aasm cancel!`; из `created` → отмена без денег; из `cancelled` → 422.
  Спека red→green (4). Проверено curl: 2000→500→2000, леджер = settlement + reversal (исходник цел).

- **Step 11 — HTTP Idempotency-Key**
  Таблица `idempotency_keys` (unique key, request_digest, сохранённый ответ), модель,
  concern `Idempotent` (around_action в `Api::BaseController`, только POST + заголовок).
  Повтор с тем же ключом/телом → сохранённый ответ; другое тело → 422; «в процессе» → 409.
  Спека red→green (4). Проверено curl (повтор не задвоил депозит, конфликт → 422).

- **Step 12 — README + финальная проверка**
  Полный README (запуск, тесты, API + curl на весь флоу, идемпотентность, решения,
  структура, ограничения). Поправлен read-слой в `CLAUDE.md` (queries не понадобились).
  Проверено на чистом окружении: `down -v` → `up --build` (4с) → полный цикл curl
  (2000→2500→1000→2500) → `make test` 30/30.

## Готово ✅

ТЗ закрыто целиком: заказы (create/success/cancel), счета-кошельки с депозитами,
append-only леджер, балансы под локами, идемпотентность (доменная + HTTP). 30 request-спек,
rubocop чистый, запуск одной командой `make up`.

## Заметки

- Направление средств: успех = **дебет** кошелька, отмена = **возврат** (ADR-009).
- При добавлении НОВОЙ корневой папки под `app/` нужен рестарт сервера (autoload-корни
  фиксируются при загрузке; dev-reload подхватывает только содержимое существующих).
