# README

## Development environment:

```
bin/dev
```

```
# one-off build
npm run tailwind:build
# or live watcher (in a separate terminal)
npm run tailwind:watch
```

```
# terminal 1 (tailwind)
npm run tailwind:watch

# terminal 2 (esbuild in watch mode)
npm run build:watch
```

```
# or in two tabs:
bin/rails tailwindcss:watch
bin/rails s
```

## DB Migration & Seed

```
RAILS_ENV=production bundle exec rails db:migrate
RAILS_ENV=production bundle exec rails db:seed
```