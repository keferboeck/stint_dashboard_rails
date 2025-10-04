# ---- Build image ----
FROM ruby:3.3-slim AS build

# OS deps
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    build-essential nodejs npm git postgresql-client curl \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /rails

# Ruby deps
COPY Gemfile Gemfile.lock ./
RUN bundle config set path vendor/bundle
RUN bundle install --without development test

# Node deps + build your JS/CSS
COPY package.json package-lock.json* yarn.lock* ./
RUN npm ci

# Copy app
COPY . .

# IMPORTANT: make sure assets pipeline can compile without DB
# (and we’re not using MJML anymore)
ENV RAILS_ENV=production
ENV NODE_ENV=production

# Build JS/CSS to app/assets/builds
RUN npm run tailwind:build && npm run build

# Precompile Sprockets (writes to public/assets). Do NOT require DB here.
# Ensure your config/environments/production.rb has:
#   config.assets.initialize_on_precompile = false
RUN bundle exec rails assets:precompile

# ---- Runtime image ----
FROM ruby:3.3-slim

# OS deps to run
RUN apt-get update -y && apt-get install -y --no-install-recommends \
    postgresql-client curl \
  && rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production
ENV RACK_ENV=production
ENV RAILS_LOG_TO_STDOUT=true
ENV RAILS_SERVE_STATIC_FILES=true

WORKDIR /rails
COPY --from=build /rails /rails

# Port comes from DO as $PORT; puma.rb must use ENV["PORT"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]