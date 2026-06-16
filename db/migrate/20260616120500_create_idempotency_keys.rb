class CreateIdempotencyKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_keys do |t|
      t.string :key, null: false
      t.string :request_digest, null: false # отпечаток (метод+путь+тело): защита от повтора ключа с другим запросом
      t.integer :response_status            # NULL пока запрос «в процессе»
      t.text :response_body                 # сохранённое тело первого ответа (отдаём дословно при повторе)

      t.timestamps
    end

    add_index :idempotency_keys, :key, unique: true # атомарный барьер на повторный ключ
  end
end
