class CreateParticipants < ActiveRecord::Migration
  def change
    create_table :participants do |t|
      t.string :name
      t.text :wish_list
      t.boolean :participating
      t.integer :id_telegram
      t.integer :secret_santa_event_id

      t.belongs_to :secret_santa_event, index: true

      t.timestamps null: false

    end
  end
end
