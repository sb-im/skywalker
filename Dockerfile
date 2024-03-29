FROM golang:1.17-alpine AS builder

# See: https://docs.github.com/en/packages/guides/connecting-a-repository-to-a-container-image#connecting-a-repository-to-a-container-image-on-the-command-line
LABEL org.opencontainers.image.source=https://github.com/SB-IM/skywalker

RUN apk update && apk add --no-cache \
    build-base \
    git \
    openssh-client

WORKDIR /src

COPY go.mod .

# See: https://docs.docker.com/develop/develop-images/build_enhancements/
# http://blog.oddbit.com/post/2019-02-24-docker-build-learns-about-secr/
RUN --mount=type=ssh,id=github git config --global url."git@github.com:".insteadOf "https://github.com/"; \
    mkdir -p -m 0600 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts; \
    go env -w GOPRIVATE="github.com/SB-IM"; \
    go mod download all; \
    go mod verify

COPY . .

ARG DEBUG=false

RUN DEBUG=${DEBUG} make skywalker

FROM alpine AS bin

RUN apk add --no-cache ca-certificates

COPY --from=builder /src/skywalker /usr/bin/skywalker

RUN addgroup -g 10001 -S skywalker && \
    adduser -u 10001 -S skywalker -G skywalker

USER skywalker

EXPOSE 8080

ENV DEBUG_MQTT_CLIENT=false

VOLUME [ "/etc/skywalker" ]

ENTRYPOINT [ "/usr/bin/skywalker" ]
