FROM golang:1.24-bookworm AS builder
ARG MQ_INSTALL_PATH="./mqm"

WORKDIR /build

COPY . .

RUN make build-mq
RUN make build

FROM golang:1.24-bookworm

COPY --from=builder /build/k6 /usr/bin/k6
#COPY --from=builder /opt/mqm /opt/mqm

RUN chmod +x /usr/bin/k6
CMD [ "/usr/bin/k6" ]
