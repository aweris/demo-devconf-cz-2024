# Project directories
ROOT_DIR        := $(CURDIR)
BUILD_DIR       := $(ROOT_DIR)/build

# Ensure everything works even if GOPATH is not set, which is often the case.
GOPATH          ?= $(shell go env GOPATH)

# Set $(GOBIN) to project directory for keeping everything in one place
GOBIN            = $(ROOT_DIR)/bin

# Dagger
DAGGER 			:= $(GOBIN)/dagger
DAGGER_VERSION  ?= v0.11.6

# Build variables
VERSION         ?= 0.1.0+dev
PLATFORM        ?= $(shell go env GOOS)/$(shell go env GOARCH)

# Helper variables
V  ?= 0
Q   = $(if $(filter 1,$V),,@)
M   = $(shell printf "\033[34;1m▶\033[0m")
DBG = $(if $(filter 1,$V),--debug,)

.PHONY: help
default: help

.PHONY: build
build: ## Builds demo binary
build: $(BUILD_DIR) $(DAGGER) ; $(info $(M) building binary)
	$(Q) $(DAGGER) $(DBG) call --source .:default build --platform $(PLATFORM) --version $(VERSION) file --path build/app -o $(BUILD_DIR)/app

.PHONY: run
run: ## Runs demo binary
run: $(DAGGER) ; $(info $(M) running binary)
	$(Q) $(DAGGER) $(DBG) call --source .:default as-service up

.PHONY: lint
lint: ## Runs golangci-lint analysis
lint: $(DAGGER) ; $(info $(M) runnig golangci-lint analysis)
	$(Q) $(DAGGER) $(DBG) call --source .:default lint stdout

.PHONY: test
test: ## Runs go test
test: $(DAGGER) ; $(info $(M) runnig tests)
	$(Q) $(DAGGER) $(DBG) call --source .:default test stdout

.PHONY: clean
clean: ## Cleanup everything
clean: ; $(info $(M) cleaning )
	$(Q) $(shell rm -rf $(GOBIN) $(BUILD_DIR))

.PHONY: help
help: ## Shows this help message
	$(Q) echo 'usage: make [target] ...'
	$(Q) echo
	$(Q) echo 'targets : '
	$(Q) echo
	$(Q) fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'| column -s: -t
	$(Q) echo

$(BUILD_DIR): ; $(info $(M) creating build directory)
	$(Q) $(shell mkdir -p $@)

$(DAGGER): ; $(info $(M) installing dagger $(DAGGER_VERSION))
	$(Q) curl -L https://dl.dagger.io/dagger/install.sh | BIN_DIR=$(GOBIN) DAGGER_VERSION=$(DAGGER_VERSION) sh
