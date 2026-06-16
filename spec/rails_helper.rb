# frozen_string_literal: true

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot'
# Ловит небезопасные не-атомарные операции внутри БД-транзакций (внешний вызов и т.п.) —
# профильная страховка для платёжной логики.
require 'isolator'

# Автоподключаем хелперы/матчеры из spec/support
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Сверяем схему тестовой БД с db/schema.rb; при отставании — пересоздаём из схемы.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

# test-prof: быстрые фикстуры с переиспользованием между примерами
require 'test_prof/recipes/rspec/before_all'
require 'test_prof/recipes/rspec/let_it_be'

RSpec.configure do |config|
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true

  # Тип спеки выводится из расположения файла (spec/requests → type: :request и т.д.)
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers

  config.filter_run_when_matching :focus
end
