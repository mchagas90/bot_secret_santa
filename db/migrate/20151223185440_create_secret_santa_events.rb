class CreateSecretSantaEvents < ActiveRecord::Migration
  def change
    create_table :secret_santa_events do |t|
      t.integer :id_chat
      t.string :title

      t.timestamps null: false
    end
  end
end
