FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o worker .

FROM alpine:3.21
RUN adduser -D appuser
WORKDIR /app
COPY --from=builder /app/worker .

USER appuser
EXPOSE 8090

CMD ["./worker"]