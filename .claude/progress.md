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
  `CLAUDE.md` (авто-подхват сессией), `docs/decisions.md` (ADR-001…008 + допущение
  по направлению средств), этот журнал.

## Next

- **Step 4 — domain models & migrations (TDD-ready)**
  `User`, `Account` (`balance_cents`, `currency`), `Order` (`amount_cents`,
  `currency`, `status`), `Transaction` (append-only: `kind`, `amount_cents`,
  `order_id`, `account_id`, ссылка на оригинал для reversal).
  Индексы на все FK; уникальные индексы под идемпотентность
  (один settlement / один reversal на заказ); CHECK-констрейнты.

- **Step 5+** — команды (`app/services/`) с локами и проводками (спеки сначала),
  query-объекты, контроллеры + panko-сериализаторы + роуты,
  HTTP `Idempotency-Key`, финальный README с curl-примерами.

## Open questions / assumptions

- Направление движения средств: успех = **кредит** счёта, отмена = сторно
  (см. допущение в конце `docs/decisions.md`). Инвертируется тривиально.
