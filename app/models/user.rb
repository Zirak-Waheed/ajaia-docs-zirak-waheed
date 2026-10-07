class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :owned_documents, class_name: "Document", foreign_key: :owner_id, inverse_of: :owner, dependent: :destroy
  has_many :document_shares, dependent: :destroy
  has_many :shared_documents, through: :document_shares, source: :document

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
