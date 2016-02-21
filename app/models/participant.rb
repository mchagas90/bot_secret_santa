class Participant < ActiveRecord::Base
  belongs_to :secret_santa_event
  validates :id_telegram, uniqueness: { scope: :secret_santa_event_id }
end
