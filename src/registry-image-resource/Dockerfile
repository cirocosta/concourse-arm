FROM cirocosta/golang-builder AS base

	RUN git clone https://github.com/concourse/registry-image-resource /src
	WORKDIR /src

	RUN go mod download
	RUN go build -o /assets/in ./cmd/in
	RUN go build -o /assets/out ./cmd/out
	RUN go build -o /assets/check ./cmd/check


FROM ubuntu:bionic

	COPY --from=base assets/ /opt/resource/
