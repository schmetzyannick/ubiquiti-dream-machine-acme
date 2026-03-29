FROM alpine:3.20

RUN apk add --no-cache \
    ca-certificates \
    curl \
    openssl \
    openssh-client \
    sed \
    sshpass

WORKDIR /workspace

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["issue"]
