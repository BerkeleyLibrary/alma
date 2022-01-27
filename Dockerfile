# =============================================================================
# Target: base

FROM ruby:2.7.5-alpine AS base

RUN apk --no-cache --update upgrade && \
    apk --no-cache add \
        bash \
        ca-certificates \
        git \
        libc6-compat \
        openssl \
        tzdata \
        xz-libs \
    && rm -rf /var/cache/apk/*

WORKDIR /opt/app

# =============================================================================
# Target: development
#

FROM base AS development

# Install system packages needed to build gems with C extensions.
RUN apk --update --no-cache add \
        build-base \
        coreutils \
        git \
    && rm -rf /var/cache/apk/*

# Copy codebase to WORKDIR. Unlike application projects, for a gem project
# we need to do this before running `bundle install`, in order for the gem
# we're building to be able to "install" itself.
COPY . .

# Install gems.
RUN bundle install --path=/usr/local/bundle

# =============================================================================
# Target: production

FROM base AS production

# Copy the built codebase from the dev stage
COPY --from=development /opt/app /opt/app
COPY --from=development /usr/local/bundle /usr/local/bundle

# Sanity-check that everything was installed correctly and still runs in the
# slimmed-down production image.
RUN bundle config set deployment 'true'
RUN bundle install --local --path=/usr/local/bundle

CMD ['bundle', 'exec', 'rake']
