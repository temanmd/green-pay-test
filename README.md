# green-pay-test

Тестовое API на Rails для платёжного домена: **заказы**, **счета-кошельки** и
неизменяемый **леджер**. Перевод заказа в успех списывает деньги со счёта, отмена
успешного заказа делает компенсирующий возврат. Акцент — на корректности денег:
ACID, блокировки, append-only леджер и идемпотентность.

> Обоснования всех ключевых решений (с плюсами/минусами) — в
> [`docs/decisions.md`](docs/decisions.md) (ADR-001…009).

## Доменная модель

- **User** — пользователь.
- **Account** — кошелёк пользователя (1:1), `balance_cents` + `currency`.
- **Order** — заказ пользователя со статусом `created → succeeded → cancelled` (state-machine).
- **Transaction** — запись леджера, **append-only**. Знаковая сумма:
  `deposit > 0`, `settlement < 0`, `reversal > 0`. Инвариант:
  `account.balance_cents == SUM(transactions.amount_cents)`.

Семантика денег: **успех заказа = дебет** кошелька (с проверкой достаточности средств),
**отмена успешного заказа = возврат** (компенсирующая reversal-запись, исходная не меняется).

## Стек

Ruby 4.0.5 · Rails 8.1 (API-only) · PostgreSQL 18 · `panko_serializer` · `aasm`
(state-machine) · `mutations` (command-объекты) · RSpec (request-спеки) · Docker Compose.

## Быстрый старт

Нужен только **Docker** (Ruby/Postgres локально ставить не нужно).

```bash
make up
```

Одна команда: собирает образ, поднимает PostgreSQL, ждёт его готовности, создаёт и
мигрирует БД и запускает API на **http://localhost:3000**. Остановка — `Ctrl-C`,
полный сброс (с данными БД) — `make reset`.

| Команда        | Что делает                                              |
|----------------|---------------------------------------------------------|
| `make up`      | Поднять весь стек на `:3000` (foreground)               |
| `make upd`     | То же в фоне                                             |
| `make down`    | Остановить контейнеры (данные БД сохраняются)           |
| `make reset`   | Полный сброс вместе с томом БД                           |
| `make test`    | Прогнать весь RSpec в контейнере                         |
| `make rubocop` | Линтер                                                  |
| `make console` | Rails-консоль в контейнере                              |
| `make bash`    | Shell в контейнере                                       |
| `make`         | Список всех команд                                       |

## Тесты

```bash
make test                  # весь набор в контейнере
COVERAGE=1 make test       # с отчётом покрытия (SimpleCov → coverage/)
```

Покрытие — **только request-спеки**: проверяем поведение через публичный контракт
API (вход → статус/тело), а не приватные детали. Каждая ручка писалась по TDD
(сначала красная спека, потом реализация).

Локально (если есть Ruby 4.0.5; порт БД проброшен наружу):

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## API

Базовый префикс — `/api/v1`. Тело и ответы — JSON. Денежные суммы — целые в
минимальных единицах (центы) + код валюты.

| Метод | Путь                              | Назначение                          |
|-------|-----------------------------------|-------------------------------------|
| POST  | `/api/v1/users`                   | Создать юзера + (пополненный) счёт   |
| GET   | `/api/v1/users/:id`               | Юзер со счётом и балансом            |
| POST  | `/api/v1/accounts/:id/deposit`    | Пополнить счёт                       |
| POST  | `/api/v1/orders`                  | Создать заказ (статус `created`)     |
| GET   | `/api/v1/orders/:id`              | Заказ                                |
| POST  | `/api/v1/orders/:id/success`      | Перевести в успех (списание)         |
| POST  | `/api/v1/orders/:id/cancel`       | Отменить (возврат, если был успех)   |

Коды ответов: `201` — создание, `200` — чтение/переход, `422` — бизнес-ошибка
(нехватка средств, невалидный переход, валидация), `404` — нет ресурса,
`409` — запрос с этим `Idempotency-Key` ещё выполняется.

### Полный сценарий (curl)

```bash
BASE=http://localhost:3000/api/v1

# 1. Юзер со счётом на 2000 (стартовый баланс = первая deposit-запись в леджере)
curl -s -X POST $BASE/users -H 'Content-Type: application/json' \
  -d '{"user":{"name":"Alice","opening_balance_cents":2000,"currency":"EUR"}}'
# => {"id":1,"name":"Alice","account":{"id":1,"balance_cents":2000,"currency":"EUR"}}

# 2. Пополнить счёт на 500
curl -s -X POST $BASE/accounts/1/deposit -H 'Content-Type: application/json' \
  -d '{"amount_cents":500}'
# => {"id":1,"balance_cents":2500,"currency":"EUR"}

# 3. Создать заказ на 1500
curl -s -X POST $BASE/orders -H 'Content-Type: application/json' \
  -d '{"order":{"user_id":1,"amount_cents":1500}}'
# => {"id":1,"user_id":1,"amount_cents":1500,"currency":"EUR","status":"created"}

# 4. Успех — списание 1500 (баланс 2500 → 1000)
curl -s -X POST $BASE/orders/1/success
# => {"id":1,...,"status":"succeeded"}

# 5. Отмена успешного — возврат 1500 (баланс 1000 → 2500)
curl -s -X POST $BASE/orders/1/cancel
# => {"id":1,...,"status":"cancelled"}

# Проверить баланс
curl -s $BASE/users/1
```

Ошибочные случаи:

```bash
# Нехватка средств → 422
curl -s -X POST $BASE/orders -H 'Content-Type: application/json' \
  -d '{"order":{"user_id":1,"amount_cents":999999}}'   # создаём большой заказ
curl -s -X POST $BASE/orders/2/success                  # => 422 {"errors":["Insufficient funds"]}
```

### Идемпотентность

Любой `POST` можно сделать идемпотентным заголовком `Idempotency-Key` (как у Stripe).
Повтор с тем же ключом и тем же телом вернёт **сохранённый первый ответ** — операция
не выполнится дважды. Тот же ключ с другим телом → `422`.

```bash
KEY=$(uuidgen)
# Первый запрос — выполняется
curl -s -X POST $BASE/accounts/1/deposit -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $KEY" -d '{"amount_cents":500}'
# Повтор с тем же ключом — НЕ задвоит, вернёт тот же ответ
curl -s -X POST $BASE/accounts/1/deposit -H 'Content-Type: application/json' \
  -H "Idempotency-Key: $KEY" -d '{"amount_cents":500}'
```

Главная польза для платежей: ретрай `success`/`cancel` после таймаута вернёт исходный
успешный ответ, а не путающую ошибку.

## Ключевые технические решения

Кратко (подробно — [`docs/decisions.md`](docs/decisions.md)):

- **Деньги — целые в центах + валюта**, никаких float (точность, корректные агрегаты).
- **Append-only леджер** + кэш `balance_cents`: история фактов не переписывается,
  отмена — компенсирующая запись со ссылкой на оригинал.
- **Пессимистичные блокировки** (`SELECT … FOR UPDATE`, порядок `order → account`):
  нет lost-update и гонок на балансе; для денег выбираем строгую согласованность.
- **Идемпотентность в два уровня**: доменная (guard'ы state-machine + уникальные
  индексы `(order_id, kind)`) и транспортная (HTTP `Idempotency-Key`).
- **CQRS**: запись — command-объекты в `app/services/` (единственное место, где меняется
  баланс), чтение — простые выборки в контроллерах.
- **State-machine `aasm`** для статусов заказа; переходы вызываются из команд, **без
  бизнес-логики в AR-колбэках**.
- **Защита на уровне БД**: `CHECK (balance_cents >= 0)`, `CHECK amount > 0`, закрытые
  множества статусов/видов транзакций, FK на все связи.

## Структура

```
app/
  controllers/api/         # тонкие контроллеры; BaseController: ошибки + идемпотентность
  models/                  # User, Account, Order, Transaction (леджер), IdempotencyKey
  serializers/             # Panko-сериализаторы
  services/                # CQRS-команды: Users::Create, Accounts::Deposit,
                           #   Orders::{Create,Succeed,Cancel}
db/migrate, db/schema.rb   # индексы, CHECK-констрейнты, уникальные индексы
spec/requests/             # request-спеки (широкое покрытие сценариев)
docs/decisions.md          # ADR — обоснования решений
```

## Ограничения (осознанные, вне скоупа ТЗ)

- Аутентификация/авторизация не реализованы (по условию).
- Одна валюта на счёт; мультивалютность — расширение.
- «Зависшие» `Idempotency-Key` (если процесс упал между началом и ответом) не имеют
  TTL — в проде нужен лок с истечением; здесь опущено для простоты.
- Запись леджера защищена от мутаций на уровне приложения (`readonly?`); в проде можно
  добавить БД-триггер на запрет `UPDATE/DELETE`.
