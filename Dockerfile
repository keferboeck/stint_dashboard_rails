# syntax=docker/dockerfile:1
FROM ruby:3.3.9-slim

# Minimal OS deps (no node/npm)
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

# Install gems first for better layer caching
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Copy app
COPY . .

# Precompile assets (Tailwind via tailwindcss-rails binary)
# Use a dummy secret so Rails can boot in asset compile phase.
ENV SECRET_KEY_BASE_DUMMY=1
RUN bundle exec rails assets:precompile

# Runtime
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log
EXPOSE 8080
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]