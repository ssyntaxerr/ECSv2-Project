FROM golang:1.24-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o dashboard .

FROM alpine:3.21
RUN adduser -D appuser
WORKDIR /app
COPY --from=builder /app/dashboard .

USER appuser
EXPOSE 8081

CMD ["./dashboard"]