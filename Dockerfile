#--- base
FROM ruby:3.3.9-slim AS base
ENV RAILS_ENV=production RACK_ENV=production BUNDLE_WITHOUT="development:test"
RUN apt-get update -y && apt-get install -y --no-install-recommends build-essential git curl libpq-dev ca-certificates && rm -rf /var/lib/apt/lists/*
WORKDIR /rails
ENV BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_JOBS=4

#--- gems
FROM base AS gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

#--- app
FROM base AS app
COPY --from=gems /usr/local/bundle /usr/local/bundle
COPY . .
# Ensure public/assets exists so precompile can write into it
RUN mkdir -p public/assets

# Precompile assets (Tailwind v4 gem builds tailwind.css -> app/assets/builds -> public/assets)
# Use a dummy secret for compile-time; real SECRET_KEY_BASE is used at runtime.
ENV SECRET_KEY_BASE_DUMMY=1
RUN bundle exec rails assets:precompile

#--- runtime
FROM base AS runtime
COPY --from=app /rails /rails
ENV RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1
EXPOSE 8080
CMD ["bash", "-lc", "bundle exec puma -b tcp://0.0.0.0:8080 -e production"]