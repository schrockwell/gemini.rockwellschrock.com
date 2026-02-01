# Build stage - generate the static site
FROM ruby:3.3-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY content/ content/
COPY web/ web/
COPY gemini/ gemini/
COPY generate.rb .

RUN ruby generate.rb

# Production stage
FROM lipanski/docker-static-website:latest

COPY --from=builder /app/_site .