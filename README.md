# README

## Development environment:

```
# option A: run both with Procfile.dev (recommended)
# Procfile.dev
web: bin/rails server -p 3000
css: bin/rails tailwind:watch

# then:
bin/dev
```

## DB Migration & Seed

```
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
```

## Maizzle Compiling

```
# live preview for emails (Maizzle server)
npm run email:dev

# when happy, compile and sync into Rails
npm run email:build

# send a real test (dev)
bin/rails c
u = User.first
u.send_reset_password_instructions
# open http://localhost:3000/letter_opener
```