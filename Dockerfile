# syntax=docker/dockerfile:1
FROM ruby:3.3.9-slim

# Minimal OS deps
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev pkg-config git curl \
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

# Gems layer
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# App source
COPY . .

# Precompile assets for production only (dummy DB + secret so Rails boots)
RUN SECRET_KEY_BASE=dummy \
    DATABASE_URL="postgresql://postgres:postgres@localhost:5432/dummy" \
    bin/rails assets:precompile

# Runtime setup
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log
EXPOSE 8080
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]