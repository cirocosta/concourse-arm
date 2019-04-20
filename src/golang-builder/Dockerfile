FROM ubuntu:bionic

# gcc for cgo
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    curl \
    ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN curl -SL https://dl.google.com/go/go1.12.4.linux-armv6l.tar.gz | tar -C /usr/local -xzf -

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH


RUN mkdir -p "$GOPATH/src" "$GOPATH/bin" && chmod -R 777 "$GOPATH"
WORKDIR $GOPATH
