#MAKEFLAGS += --silent

RDURL ?= https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/mqdev/redist
RDTAR ?= IBM-MQC-Redist-LinuxX64.tar.gz
VRMF ?= 9.4.3.0

export MQ_INSTALL_PATH = /opt/mqm
export MQ_REDIST_INSTALL_PATH = $(shell pwd)/mqm_redist
export GOCACHE=/tmp/.gocache
export MQSERVER = DEV.APP.SVRCONN/TCP/localhost(1414)

all: clean format install-xk6 build-deps build-mq build

## clean: Removes any previously created build artifacts.
.PHONY: clean
clean: clean-deps
	rm -f ./k6

.PHONY: clean-deps 
clean-deps:
	rm -rf $(MQ_REDIST_INSTALL_PATH)
	rm -rf $(MQ_INSTALL_PATH)

.PHONY: install-xk6
install-xk6:
	go install go.k6.io/xk6/cmd/xk6@v1.0.0

.PHONY: build-deps
build-deps:
	mkdir -p $(MQ_REDIST_INSTALL_PATH) \
 	&& cd $(MQ_REDIST_INSTALL_PATH) \
 	&& curl -LO "$(RDURL)/$(VRMF)-$(RDTAR)" \
 	&& tar -zxf ./*.tar.gz \
 	&& rm -f ./*.tar.gz

.PHONY: build-mq
build-mq:
	genmqpkg_incnls=1 \
	genmqpkg_incsdk=1 \
	genmqpkg_inctls=1 \
	$(MQ_REDIST_INSTALL_PATH)/bin/genmqpkg.sh -v -b $(MQ_INSTALL_PATH)

## build: Builds a custom 'k6' with the local extension.
.PHONY: build
build:
	CGO_ENABLED=1 \
	CGO_LDFLAGS="-L${MQ_INSTALL_PATH}/lib64 -Wl,-rpath,${MQ_INSTALL_PATH}/lib64" \
	CGO_CFLAGS="-I${MQ_INSTALL_PATH}/inc" \
	xk6 build -v --skip-cleanup --with $(shell go list -m)=. --k6-version v1.0.0 \
	&& ./k6 version

## format: Applies Go formatting to code.
.PHONY: format
format:
	go fmt .

.PHONY: integration-test
integration-test:
	./k6 run examples/mqput.js

.PHONY: integration-test-vus
integration-test-vus:
	./k6 run -vu 20 --duration 60m examples/mqput.js

## test: Executes any unit tests.
.PHONY: test
test:
	go test -cover -race ./...

