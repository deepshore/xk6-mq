FROM debian:bullseye-slim
ARG MQ_INSTALL_PATH="./mqm"

RUN useradd -rm -d /home/k6 -s /bin/bash -u 12345 k6
COPY ./k6 /usr/bin/k6
COPY $MQ_INSTALL_PATH /opt/mqm

USER 12345
WORKDIR /home/k6
ENTRYPOINT ["k6"]