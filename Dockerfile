# syntax=docker/dockerfile:1

# ===== ビルドステージ：Go のプログラムをコンパイルする =====
FROM golang:1.25 AS builder
WORKDIR /src

# 別ファイルを用意しなくて済むよう、ソースコードを Dockerfile 内に直接書く
COPY <<'EOF' main.go
package main

import (
	"fmt"
	"os"
	"runtime"
)

func main() {
	name := os.Getenv("APP_NAME")
	fmt.Printf("Hello from %s (built with %s)\n", name, runtime.Version())
}
EOF

RUN go mod init example.com/hello && \
    CGO_ENABLED=0 go build -o /out/hello .

# ===== 実行ステージ：小さなイメージに完成品だけをコピーする =====
FROM alpine:3.20

# ビルド時に --build-arg APP_VERSION=1.0 のように上書きできる
ARG APP_VERSION=dev
ENV APP_NAME="hello-app ${APP_VERSION}"

# root ではない一般ユーザーで実行する
RUN adduser -D appuser
USER appuser
WORKDIR /home/appuser

COPY --from=builder /out/hello ./hello
CMD ["./hello"]