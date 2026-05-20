# Pin the builder image tag and update it intentionally. Do not use "latest".
FROM golang:1.26.3-alpine AS build

WORKDIR /src
COPY docker/hello-server.go .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/hello-server hello-server.go

FROM scratch

COPY --from=build /out/hello-server /hello-server
USER 1000:1000

EXPOSE 5678

ENTRYPOINT ["/hello-server"]
CMD ["-text=Hello from EKS"]
