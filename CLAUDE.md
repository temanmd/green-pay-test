# green-pay-test — Senior Ruby (FinTech / Payments) test task

API-only Rails app implementing a minimal payments domain:
**Orders** belong to **Users**; each User has an **Account** with a balance.
Moving an order to `succeeded` posts a ledger transaction and updates the
balance. Cancelling a *succeeded* order posts a compensating (reversal)
transaction and updates the balance back.

This is an interview/portfolio project: the code is meant to be **read and
defended in an interview**. Optimise for clarity and correct payment semantics
over feature breadth.

## Stack
- Ruby 4.0.5, Rails 8.1.3 (API-only), PostgreSQL 18
- `panko_serializer` + `oj` (serialization), `aasm` (order state machine),
  `mutations` (command objects)
- RSpec (**request specs only**), `factory_bot`, `test-prof`
- RuboCop, `brakeman`, `bundler-audit`, `isolator`

## Run
- `make up` — build + start Postgres + app on `:3000` (single command)
- `make test` — full RSpec suite in the container
- `make rubocop` — lint
- `make console` / `make bash` — into the app container
- DB port `5432` is exposed, so `bundle exec rspec` / `bin/rails` also work
  locally against the Docker DB (defaults point at `localhost`).

## Architecture (CQRS-style)
- **Write side** — command objects in `app/services/`. A command wraps its
  writes in a single DB transaction, locks the account row
  (`SELECT … FOR UPDATE` via `with_lock`), and is the **only** place a balance
  changes.
- **Read side** — reads are trivial (find by id) and live in the controllers; a
  dedicated `app/queries/` layer is the convention if/when reads grow.
- **Serialization** — Panko serializers in `app/serializers/`.
- **No business logic in ActiveRecord callbacks.** Status changes are explicit
  `aasm` events triggered *from commands*; side effects live in commands.

## Money & ledger rules (read before touching balances)
- Money = **integer minor units** (`*_cents`) + currency code. Never floats.
- The ledger is **append-only**: transactions are immutable. A cancel never
  deletes or edits — it writes a compensating **reversal** entry linked to the
  original.
- `accounts.balance_cents` is a **cached** value, updated in the *same* DB
  transaction as the ledger entry, under a row lock.
- Idempotency = state-machine guards + unique DB constraints (one settlement /
  one reversal per order) + HTTP `Idempotency-Key`.

## Conventions
- **TDD**: write the request spec first, then the implementation.
- Index every FK and every column we filter or lock on.
- Commits are made by the repo owner (the human), in small reviewable steps.

## More context
- `docs/decisions.md` — architecture decisions with rationale & trade-offs.
- `.claude/progress.md` — step-by-step build log (mirrors the commit history).
