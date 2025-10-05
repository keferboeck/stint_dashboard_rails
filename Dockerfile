# ===== Base image =====
FROM ruby:3.3.9-slim

# ===== System dependencies =====
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libpq-dev \
      libyaml-dev \
      pkg-config \
      git \
      curl \
      nodejs \
      npm \
    && rm -rf /var/lib/apt/lists/*

# ===== App setup =====
WORKDIR /rails/app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true

# ===== Install Ruby gems =====
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# ===== Install JS deps & build Tailwind/JS =====
COPY package.json package-lock.json ./
RUN npm ci

# ===== Copy source =====
COPY . .

# ===== Precompile assets =====
RUN npm run tailwind:build && \
    npm run build && \
    SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

# ===== Runtime =====
EXPOSE 8080
ENV PORT=8080

# Create tmp dirs expected by Rails
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]