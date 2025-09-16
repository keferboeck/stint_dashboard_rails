# db/seeds.rb

def ensure_admin!(first_name:, last_name:, position:, email:)
  u = User.find_or_initialize_by(email: email)
  u.first_name = first_name
  u.last_name  = last_name
  u.role       = "admin"
  u.password   = "StintDashboard!!x"
  u.password_confirmation = "StintDashboard!!x"
  u.save!
  u
end

georg = ensure_admin!(
  first_name: "Georg",
  last_name:  "Keferboeck",
  position:   "Develper",
  email:      "georg@keferboeck.com"
)

gemma = ensure_admin!(
  first_name: "Gemma",
  last_name:  "Kindness",
  position:   "Brand Lead",
  email:      "gemma.kindness@stint.co"
)

puts "Seeded admins: #{[georg.email, gemma.email].join(', ')}"