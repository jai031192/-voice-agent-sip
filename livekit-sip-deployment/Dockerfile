# ---------- BUILD STAGE ----------
FROM golang:1.24-alpine AS builder
 
# Install build dependencies
RUN apk add --no-cache \
    build-base \
    pkgconfig \
    opus-dev \
    opusfile-dev \
    soxr-dev \
    libsamplerate-dev \
    git \
    wget \
    curl \
    bash
 
# Set working directory
WORKDIR /app
 
# Copy Go module files
COPY go.mod ./
 
# Download dependencies
RUN go mod download || true
 
# Copy source code
COPY . .
 
# Build the SIP binary (static linking)
WORKDIR /app/sip
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo \
    -ldflags '-w -s' \
    -o /app/sip-app ./cmd/livekit-sip

# Build LiveKit CLI version 1.9.1
WORKDIR /app
RUN go install github.com/livekit/livekit-cli/cmd/livekit-cli@v1.9.1 && \
    cp $(go env GOPATH)/bin/livekit-cli /app/livekit-cli
 
 
# Make them executable
RUN chmod +x /app/docker-entrypoint.sh /app/sip-app /app/livekit-cli
 
# ---------- RUNTIME STAGE ----------
FROM alpine:latest
 
# Install runtime dependencies
RUN apk add --no-cache \
    opus \
    opusfile \
    soxr \
    libsamplerate \
    redis \
    ca-certificates \
    tzdata \
    wget \
    curl \
    bash
 
# Create a non-root user
RUN addgroup -g 1001 -S livekit && adduser -u 1001 -S livekit -G livekit
 
# Set working directory
WORKDIR /app
 
# Copy binaries from builder
COPY --from=builder /app/sip-app /app/sip-app
COPY --from=builder /app/livekit-cli /app/livekit-cli
 
# Copy config and entrypoint
COPY config.yaml livekit-config.yaml docker-entrypoint.sh ./
RUN chmod +x /app/sip-app /app/docker-entrypoint.sh /app/livekit-cli
 
# Switch to non-root user
USER livekit
 
# Expose required ports
EXPOSE 5060/tcp 5060/udp 7880/tcp 8080/tcp 6000-6100/udp 50000-50100/udp
 
# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=90s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1
 
# Environment variables (using your actual keys and IP)
ENV LIVEKIT_URL=http://40.81.229.194:7880
ENV LIVEKIT_API_KEY=108378f337bbab3ce4e944554bed555a
ENV LIVEKIT_API_SECRET=2098a695dcf3b99b4737cca8034b122fb86ca9f904c13be1089181c0acb7932d
 
# Entrypoint
ENTRYPOINT ["/app/docker-entrypoint.sh"]