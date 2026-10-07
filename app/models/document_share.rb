class DocumentShare < ApplicationRecord
  ROLES = %w[editor viewer].freeze

  belongs_to :document, touch: true
  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :document_id, message: "already has access" }
  validate :cannot_share_with_owner

  private

  def cannot_share_with_owner
    errors.add(:base, "The owner already has full access") if document && user_id == document.owner_id
  end
end
