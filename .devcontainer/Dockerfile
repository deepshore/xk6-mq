FROM mcr.microsoft.com/devcontainers/go:1.24-bullseye

# Install the Go compiler and Git
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    tar \
    bash \
    build-essential \
    xz-utils \
  && rm -rf /var/lib/apt/lists/*

# Create location for the git clone and MQ installation
RUN mkdir -p /opt/mqm \
  && chmod a+rx /opt/mqm

# Location of the downloadable MQ client package \
ENV RDURL="https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist" \
    RDTAR="IBM-MQC-Redist-LinuxX64.tar.gz" \
    VRMF=9.4.3.0

# Install the MQ client from the Redistributable package. This also contains the
# header files we need to compile against. Setup the subset of the package
# we are going to keep - the genmqpkg.sh script removes unneeded parts
ENV genmqpkg_incnls=1 \
    genmqpkg_incsdk=1 \
    genmqpkg_inctls=1

# RUN cd /opt/mqm \
#  && curl -LO "$RDURL/$VRMF-$RDTAR" \
#  && tar -zxf ./*.tar.gz \
#  && rm -f ./*.tar.gz \
#  && bin/genmqpkg.sh -b /opt/mqm

