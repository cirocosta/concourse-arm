FROM golang:alpine AS base

	RUN apk add --update git
	RUN git clone --branch=platform https://github.com/concourse/registry-image-resource /src
	WORKDIR /src

	RUN go mod download
	RUN go build -o /assets/in ./cmd/in
	RUN go build -o /assets/out ./cmd/out
	RUN go build -o /assets/check ./cmd/check


FROM alpine

	RUN apk add --update ca-certificates
	COPY --from=base assets/ /opt/resource/
