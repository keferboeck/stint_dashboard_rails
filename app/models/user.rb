class User < ApplicationRecord
  # Devise modules: add/remove as needed (e.g. :confirmable, :lockable, :timeoutable)
  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  # String-backed enum (Rails 8 supports string values nicely)
  enum :role, { admin: "admin", staff: "staff", viewer: "viewer" }, prefix: true, validate: true

  validates :first_name, presence: true
  validates :last_name,  presence: true
  validates :role,       presence: true

  scope :admins, -> { where(role: User.roles[:admin]) }

  def admin?
    role.to_s == "admin"
  end

  def manager?
    role.to_s == "manager"
  end

  def viewer?
    role.to_s == "viewer"
  end
end