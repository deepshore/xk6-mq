#MAKEFLAGS += --silent

RDURL ?= https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist
RDTAR ?= IBM-MQC-Redist-LinuxX64.tar.gz
VRMF ?= 9.4.3.0
export MQ_INSTALL_PATH = /opt/mqm
export MQ_REDIST_INSTALL_PATH = $(shell pwd)/mqm_redist
export GOCACHE=/tmp/.gocache
export MQ_INSTALLATION_PATH = /opt/mqm
export MQSERVER = DEV.APP.SVRCONN/TCP/localhost(1414)

all: clean format build-deps build-mq build

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
clean: clean-deps
	rm -f ./k6

clean-deps:
	rm -rf $(MQ_REDIST_INSTALL_PATH)
	rm -rf $(MQ_INSTALL_PATH)

build-deps:
	mkdir -p $(MQ_REDIST_INSTALL_PATH) \
 	&& cd $(MQ_REDIST_INSTALL_PATH) \
 	&& curl -LO "$(RDURL)/$(VRMF)-$(RDTAR)" \
 	&& tar -zxf ./*.tar.gz \
 	&& rm -f ./*.tar.gz

build-mq:
	genmqpkg_incnls=1 \
	genmqpkg_incsdk=1 \
	genmqpkg_inctls=1 \
	$(MQ_REDIST_INSTALL_PATH)/bin/genmqpkg.sh -v -b $(MQ_INSTALL_PATH)

## build: Builds a custom 'k6' with the local extension. 
build:
	go install go.k6.io/xk6/cmd/xk6@latest && \
	CGO_ENABLED=1 \
	CGO_ARCH=amd64 \
	CGO_LDFLAGS="-L${MQ_INSTALL_PATH}/lib64 -Wl,-rpath,${MQ_INSTALL_PATH}/lib64" \
	CGO_CFLAGS="-I${MQ_INSTALL_PATH}/inc" \
	xk6 build -v --with $(shell go list -m)=.
## format: Applies Go formatting to code.
format:
	go fmt ./...

integration-test: build
	./k6 run examples/mqput.js


## test: Executes any unit tests.
test:
	go test -cover -race ./...

.PHONY: build clean format help test
