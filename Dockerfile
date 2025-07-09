# FROM golang:1.24-bookworm AS builder
# ARG MQ_INSTALL_PATH="./mqm"

# WORKDIR /build

# COPY . .

# RUN make

#USER 12345
#WORKDIR /home/k6
#ENTRYPOINT ["k6"]


FROM alpine:3.14
#ARG MQ_INSTALL_PATH="/opt/mqm"

COPY ./k6 /usr/bin/k6
RUN chmod +x /usr/bin/k6
#COPY $MQ_INSTALL_PATH /opt/mqm

#ENV MQ_INSTALL_PATH=$MQ_INSTALL_PATH

CMD [ "/usr/bin/k6" ]
