class Document < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :shares, class_name: "DocumentShare", dependent: :destroy
  has_many :collaborators, through: :shares, source: :user
  has_rich_text :body

  validates :title, presence: true, length: { maximum: 200 }

  scope :owned_by, ->(user) { where(owner: user) }
  scope :shared_with, ->(user) { where(id: DocumentShare.where(user: user).select(:document_id)) }
  # Single source of truth for "can this user see this document at all".
  scope :accessible_by, ->(user) { owned_by(user).or(shared_with(user)) }

  def owned_by?(user)
    user.present? && owner_id == user.id
  end

  # "owner", "editor", "viewer", or nil (no access)
  def role_for(user)
    return "owner" if owned_by?(user)
    return nil if user.nil?
    shares.find_by(user: user)&.role
  end

  def viewable_by?(user) = role_for(user).present?
  def editable_by?(user) = %w[owner editor].include?(role_for(user))
end
