# syntax=docker/dockerfile:1
FROM ruby:3.3.9-slim

# OS deps (libyaml-dev fixes the psych native extension build)
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev pkg-config git curl nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails/app

# Rails / Bundler env
ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    PORT=8080

# Install Ruby gems (layered on Gemfile changes)
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Install Node deps (layered on package files)
COPY package.json package-lock.json ./
RUN npm ci

# App source
COPY . .

# Build Tailwind and precompile Rails assets.
# IMPORTANT: provide dummy DATABASE_URL so Rails can boot during assets:precompile.
RUN npm run tailwind:build && \
    RAILS_ENV=production \
    DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dummy" \
    SECRET_KEY_BASE=dummy \
    bin/rails assets:precompile

# Runtime setup
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log
EXPOSE 8080

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]