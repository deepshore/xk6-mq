FROM debian:bullseye-slim
RUN useradd -rm -d /home/k6 -s /bin/bash -u 12345 k6
COPY ./k6 /usr/bin/k6
COPY ./mqm /opt/mqm

USER 12345
WORKDIR /home/k6
ENTRYPOINT ["k6"]