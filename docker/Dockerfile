# Runtime image for phira-mp-server.
# Expects a statically linked (musl) binary at ./phira-mp-server
# next to this Dockerfile, as produced by .github/workflows/build.yml.
FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata \
 && addgroup -S phira \
 && adduser -S -G phira -h /app phira

COPY phira-mp-server /usr/local/bin/phira-mp-server
RUN chmod 0755 /usr/local/bin/phira-mp-server \
 && mkdir -p /app \
 && chown phira:phira /app

WORKDIR /app
USER phira

ENV RUST_LOG=info
EXPOSE 12346

ENTRYPOINT ["/usr/local/bin/phira-mp-server"]
CMD ["--port", "12346"]
