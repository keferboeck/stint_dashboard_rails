# ==============================================================
# Stint Dashboard – Production Dockerfile
# ==============================================================
# Ruby 3.3.9 base image (Debian slim)
FROM ruby:3.3.9-slim

# -----------------------------
# Set environment
# -----------------------------
ENV RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_DEPLOYMENT=true \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development test" \
    LANG=C.UTF-8

WORKDIR /rails

# -----------------------------
# Install system dependencies
# -----------------------------
# - build-essential: for native extensions
# - libyaml-dev: required by psych gem
# - libpq-dev: for PostgreSQL
# - nodejs & npm: for JS bundling
# - curl, git: general tooling
# -----------------------------
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
      build-essential \
      libyaml-dev \
      libpq-dev \
      pkg-config \
      nodejs \
      npm \
      git \
      curl && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------
# Install Ruby gems
# -----------------------------
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# -----------------------------
# Copy application code
# -----------------------------
COPY . .

# -----------------------------
# Prebuilt assets note:
# Assets should already exist in public/assets and app/assets/builds
# since DigitalOcean's build step will skip JS/Tailwind compilation.
# If you ever want to compile here, uncomment:
# RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile
# -----------------------------

# -----------------------------
# Expose port & start server
# -----------------------------
ENV PORT=80
EXPOSE 80
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "80"]