# Build Stage
FROM arm32v7/node:20-slim AS build-stage
WORKDIR /usr/src/cross-seed
COPY package*.json ./
ENV NPM_CONFIG_UPDATE_NOTIFIER=false
RUN npm ci --no-fund
COPY tsconfig.json ./
COPY src src
RUN npm run build && \
    npm prune --omit=dev && \
    rm -rf src tsconfig.json

# Production Stage
FROM arm32v7/node:20-slim

# Install tini for process management and clean signal handling
RUN apt-get update && \
    apt-get install -y curl tzdata tini && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Setup app
WORKDIR /usr/src/cross-seed
COPY --from=build-stage /usr/src/cross-seed ./
RUN npm link

# Environment setup
ENV CONFIG_DIR=/config
ENV DOCKER_ENV=true

# Expose default port
EXPOSE 2468

# Set working dir to config (mount volume here in Portainer)
WORKDIR /config

# Use tini as the container's init system
ENTRYPOINT ["/usr/bin/tini", "--", "cross-seed"]
