#multi-arch image
FROM public.ecr.aws/docker/library/golang:bookworm AS build
WORKDIR /bin
COPY main.go main.go
RUN go build main.go

#multi-arch image
FROM public.ecr.aws/docker/library/debian:bookworm-slim
WORKDIR /bin
COPY --from=build /bin/main /bin/main
ENTRYPOINT ["/bin/main"]