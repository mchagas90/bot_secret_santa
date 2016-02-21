class SecretSantaEvent < ActiveRecord::Base
  has_many :participants
  validates :id_chat, uniqueness: true
end
