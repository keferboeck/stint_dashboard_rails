FROM ruby:3.3.9-slim

RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
      build-essential libpq-dev libyaml-dev pkg-config git curl nodejs npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails/app

ENV RAILS_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    PORT=8080

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Build ONLY Tailwind CSS, no JS
RUN npm run tailwind:build && \
    SECRET_KEY_BASE=dummy bundle exec rails assets:precompile

EXPOSE 8080
RUN mkdir -p tmp/pids tmp/cache tmp/sockets log

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]