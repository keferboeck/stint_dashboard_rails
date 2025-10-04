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

## Before build and relase to DO

```
npm ci
npm run tailwind:build
npm run build
RAILS_ENV=production bundle exec rake assets:precompile
```