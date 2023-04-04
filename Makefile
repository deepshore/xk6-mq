#MAKEFLAGS += --silent

RDURL ?= https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist
RDTAR ?= IBM-MQC-Redist-LinuxX64.tar.gz
VRMF ?= 9.3.2.0
MQ_INSTALL_PATH ?= /opt/mqm

all: clean format build-deps build

## help: Prints a list of available build targets.
help:
	echo "Usage: make <OPTIONS> ... <TARGETS>"
	echo ""
	echo "Available targets are:"
	echo ''
	sed -n 's/^##//p' ${PWD}/Makefile | column -t -s ':' | sed -e 's/^/ /'
	echo
	echo "Targets run by default are: `sed -n 's/^all: //p' ./Makefile | sed -e 's/ /, /g' | sed -e 's/\(.*\), /\1, and /'`"

## clean: Removes any previously created build artifacts.
clean:
	rm -f ./k6

clean-deps:
	rm -rf $(MQ_INSTALL_PATH)

build-deps:
	mkdir -p $(MQ_INSTALL_PATH) \
 	&& cd $(MQ_INSTALL_PATH) \
 	&& curl -LO "$(RDURL)/$(VRMF)-$(RDTAR)" \
 	&& tar -zxf ./*.tar.gz \
 	&& rm -f ./*.tar.gz
 	
	genmqpkg_incnls=1 \
    genmqpkg_incsdk=1 \
    genmqpkg_inctls=1 \
	$(MQ_INSTALL_PATH)/bin/genmqpkg.sh -b $(MQ_INSTALL_PATH)

## build: Builds a custom 'k6' with the local extension. 
build:
	go install go.k6.io/xk6/cmd/xk6@latest
	XK6_BUILD_FLAGS="-ldflags '-L $(MQ_INSTALL_PATH)/inc'" \
    CGO_ENABLED=1 GO_ARCH=amd64 CGO_LDFLAGS_ALLOW="-Wl,-rpath.*" CGO_CFLAGS="-I $(MQ_INSTALL_PATH)/inc"  CFLAGS="-I $(MQ_INSTALL_PATH)/lib64" \
	xk6 build --with $(shell go list -m)=.
## format: Applies Go formatting to code.
format:
	go fmt ./...

## test: Executes any unit tests.
test:
	go test -cover -race ./...

.PHONY: build clean format help test
