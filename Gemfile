# frozen_string_literal: true

source 'https://rubygems.org'

ruby '4.0.5'

# --- Core ---
gem 'bootsnap', require: false
gem 'pg', '~> 1.5' # PostgreSQL: ACID, row-level locks (SELECT ... FOR UPDATE), unique constraints — основа леджера
gem 'puma', '>= 6.0'
gem 'rails', '~> 8.1.3'
gem 'tzinfo-data', platforms: %i[windows jruby]

# --- Serialization ---
gem 'oj'                # быстрый JSON-бэкенд, на котором работает Panko
gem 'panko_serializer'  # быстрая и явная сериализация JSON (требование тестового)

# --- Domain ---
gem 'aasm'       # явная state-machine для статусов Order (переходы как guard'ы, а не AR-колбэки)
gem 'mutations'  # command-объекты с валидацией входа (write-сторона CQRS), как в референсном проекте

group :development, :test do
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'
  gem 'dotenv-rails' # загрузка .env при локальном (не-docker) запуске
  gem 'factory_bot_rails'
  gem 'rspec-rails', '~> 8.0'
end

group :development do
  gem 'brakeman', require: false       # статический анализатор безопасности (профильно для платежей)
  gem 'bundler-audit', require: false  # проверка гемов на известные CVE
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'isolator', require: false  # ловит небезопасные не-атомарные операции внутри БД-транзакций
  gem 'simplecov', require: false # отчёт о покрытии
  gem 'test-prof'                 # let_it_be / before_all — быстрые request-спеки
end
