FROM arm32v7/alpine:3.17 AS build-stage

# Install node + build dependencies
RUN apk add --no-cache nodejs npm git python3 make g++

WORKDIR /usr/src/cross-seed
COPY package*.json ./
RUN npm ci --no-fund

COPY tsconfig.json ./
COPY src ./src

RUN npm run build && \
    npm prune --omit=dev && \
    rm -rf src tsconfig.json

# Production Stage
FROM arm32v7/alpine:3.17

RUN apk add --no-cache nodejs npm tini curl tzdata

WORKDIR /usr/src/cross-seed
COPY --from=build-stage /usr/src/cross-seed ./

RUN npm link

ENV CONFIG_DIR=/config
ENV DOCKER_ENV=true

EXPOSE 2468
WORKDIR /config

ENTRYPOINT ["/sbin/tini", "--", "cross-seed"]
