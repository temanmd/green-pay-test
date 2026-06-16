# frozen_string_literal: true

# Хелперы для request-спек API: разбор JSON-ответа с символьными ключами.
module ApiHelpers
  def json_response
    JSON.parse(response.body, symbolize_names: true)
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
