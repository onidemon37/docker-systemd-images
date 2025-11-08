# Makefile for building Docker SystemD images locally
# Author: Edino Moniz

.PHONY: help all debian oraclelinux clean clean-dev test lint lint-all install-deps setup-dev install-hadolint venv pre-commit-install pre-commit-run

# Default target
.DEFAULT_GOAL := help

# Variables
REGISTRY ?= ghcr.io/onidemon37
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Debian versions
DEBIAN_VERSIONS := 10 11 12 13

# Oracle Linux versions
ORACLELINUX_VERSIONS := 8 9 10

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Development environment
VENV_DIR := .venv
PYTHON := python3

## Display this help message
help:
	@echo "$(GREEN)Docker SystemD Images - Local Build Helper$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*##/ { printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make debian-12          # Build Debian 12 image"
	@echo "  make oraclelinux-8      # Build Oracle Linux 8 image"
	@echo "  make debian             # Build all Debian images"
	@echo "  make all                # Build all images"
	@echo "  make test-debian-12     # Test Debian 12 image"
	@echo "  make setup-dev          # Setup complete development environment"
	@echo "  make install-deps       # Install all development dependencies"

## Development Environment Setup

setup-dev: ## Setup complete development environment (hadolint + pre-commit)
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@$(MAKE) install-hadolint
	@$(MAKE) venv
	@$(MAKE) pre-commit-install
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "$(YELLOW)Activate virtualenv with: source $(VENV_DIR)/bin/activate$(NC)"

install-deps: ## Install all development dependencies
install-deps: install-hadolint venv pre-commit-install

install-hadolint: ## Install hadolint for Dockerfile linting
	@echo "$(YELLOW)Installing hadolint...$(NC)"
	@if command -v brew >/dev/null 2>&1; then \
		echo "Installing hadolint via Homebrew..."; \
		brew install hadolint || echo "$(RED)Failed to install hadolint via brew$(NC)"; \
	elif command -v wget >/dev/null 2>&1; then \
		echo "Installing hadolint via wget..."; \
		sudo wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Darwin-x86_64; \
		sudo chmod +x /usr/local/bin/hadolint; \
	else \
		echo "$(YELLOW)Neither brew nor wget available. Using Docker version for linting.$(NC)"; \
	fi

venv: ## Create Python virtual environment
	@echo "$(YELLOW)Creating Python virtual environment...$(NC)"
	@if [ ! -d "$(VENV_DIR)" ]; then \
		$(PYTHON) -m venv $(VENV_DIR); \
		echo "$(GREEN)Virtual environment created at $(VENV_DIR)$(NC)"; \
	else \
		echo "$(YELLOW)Virtual environment already exists$(NC)"; \
	fi
	@$(VENV_DIR)/bin/pip install --upgrade pip
	@$(VENV_DIR)/bin/pip install pre-commit yamllint

pre-commit-install: ## Install and setup pre-commit hooks
pre-commit-install: venv
	@echo "$(YELLOW)Setting up pre-commit hooks...$(NC)"
	@$(VENV_DIR)/bin/pre-commit install
	@echo "$(GREEN)Pre-commit hooks installed$(NC)"

pre-commit-run: ## Run pre-commit on all files
pre-commit-run: venv
	@echo "$(YELLOW)Running pre-commit on all files...$(NC)"
	@$(VENV_DIR)/bin/pre-commit run --all-files

## Building and Testing

all: ## Build all images
all: debian oraclelinux

debian: ## Build all Debian images
debian: $(addprefix debian-, $(DEBIAN_VERSIONS))

oraclelinux: ## Build all Oracle Linux images
oraclelinux: $(addprefix oraclelinux-, $(ORACLELINUX_VERSIONS))

# Individual Debian targets
debian-10: ## Build Debian 10 image
	@echo "$(GREEN)Building Debian 10 image...$(NC)"
	docker build \
		--build-arg DEBIAN_VERSION=buster-slim \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:10 \
		-t $(REGISTRY)/debian:10 \
		-t $(REGISTRY)/debian:10-$(GIT_COMMIT) \
		./debian/10/

debian-11: ## Build Debian 11 image
	@echo "$(GREEN)Building Debian 11 image...$(NC)"
	docker build \
		--build-arg DEBIAN_VERSION=11 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:11 \
		-t $(REGISTRY)/debian:11 \
		-t $(REGISTRY)/debian:11-$(GIT_COMMIT) \
		./debian/11/

debian-12: ## Build Debian 12 image
	@echo "$(GREEN)Building Debian 12 image...$(NC)"
	docker build \
		--build-arg DEBIAN_VERSION=12 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:12 \
		-t $(REGISTRY)/debian:12 \
		-t $(REGISTRY)/debian:12-$(GIT_COMMIT) \
		./debian/12/

debian-13: ## Build Debian 13 image
	@echo "$(GREEN)Building Debian 13 image...$(NC)"
	docker build \
		--build-arg DEBIAN_VERSION=13 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:13 \
		-t $(REGISTRY)/debian:13 \
		-t $(REGISTRY)/debian:13-$(GIT_COMMIT) \
		./debian/13/

# Individual Oracle Linux targets
oraclelinux-8: ## Build Oracle Linux 8 image
	@echo "$(GREEN)Building Oracle Linux 8 image...$(NC)"
	docker build \
		--build-arg ORACLELINUX_VERSION=8 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t oraclelinux-systemd:8 \
		-t $(REGISTRY)/oraclelinux:8 \
		-t $(REGISTRY)/oraclelinux:8-$(GIT_COMMIT) \
		./oraclelinux/8/

oraclelinux-9: ## Build Oracle Linux 9 image
	@echo "$(GREEN)Building Oracle Linux 9 image...$(NC)"
	docker build \
		--build-arg ORACLELINUX_VERSION=9 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t oraclelinux-systemd:9 \
		-t $(REGISTRY)/oraclelinux:9 \
		-t $(REGISTRY)/oraclelinux:9-$(GIT_COMMIT) \
		./oraclelinux/9/

oraclelinux-10: ## Build Oracle Linux 10 image
	@echo "$(GREEN)Building Oracle Linux 10 image...$(NC)"
	docker build \
		--build-arg ORACLELINUX_VERSION=10 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t oraclelinux-systemd:10 \
		-t $(REGISTRY)/oraclelinux:10 \
		-t $(REGISTRY)/oraclelinux:10-$(GIT_COMMIT) \
		./oraclelinux/10/

test-debian: ## Test Debian images
test-debian: $(addprefix test-debian-, $(DEBIAN_VERSIONS))

test-oraclelinux: ## Test Oracle Linux images
test-oraclelinux: $(addprefix test-oraclelinux-, $(ORACLELINUX_VERSIONS))

test: ## Test all images
test: test-debian test-oraclelinux

# Individual test targets
test-debian-10: ## Test Debian 10 image
	@echo "$(YELLOW)Testing Debian 10 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:10 systemctl --version

test-debian-11: ## Test Debian 11 image
	@echo "$(YELLOW)Testing Debian 11 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:11 systemctl --version

test-debian-12: ## Test Debian 12 image
	@echo "$(YELLOW)Testing Debian 12 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:12 systemctl --version

test-debian-13: ## Test Debian 13 image
	@echo "$(YELLOW)Testing Debian 13 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:13 systemctl --version

test-oraclelinux-8: ## Test Oracle Linux 8 image
	@echo "$(YELLOW)Testing Oracle Linux 8 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro oraclelinux-systemd:8 systemctl --version

test-oraclelinux-9: ## Test Oracle Linux 9 image
	@echo "$(YELLOW)Testing Oracle Linux 9 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro oraclelinux-systemd:9 systemctl --version

test-oraclelinux-10: ## Test Oracle Linux 10 image
	@echo "$(YELLOW)Testing Oracle Linux 10 image...$(NC)"
	docker run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro oraclelinux-systemd:10 systemctl --version

## Run hadolint on all Dockerfiles
lint: ## Lint all Dockerfiles with hadolint
	@echo "$(YELLOW)Linting Dockerfiles...$(NC)"
	@if command -v hadolint >/dev/null 2>&1; then \
		find . -name "Dockerfile" -exec echo "Linting {}" \; -exec hadolint --ignore DL3041 --ignore DL3008 --ignore DL3013 --ignore DL3003 --ignore DL3047 {} \; || true; \
	else \
		echo "$(RED)hadolint not found. Install with: make install-hadolint$(NC)"; \
		echo "$(YELLOW)Running hadolint via Docker instead...$(NC)"; \
		find . -name "Dockerfile" -exec echo "Linting {}" \; -exec docker run --rm -i hadolint/hadolint:latest hadolint --ignore DL3041 --ignore DL3008 --ignore DL3013 --ignore DL3003 --ignore DL3047 - < {} \; || true; \
	fi

lint-all: ## Run all linting (Dockerfile, YAML, Markdown via pre-commit)
lint-all: lint
	@if [ -d "$(VENV_DIR)" ]; then \
		echo "$(YELLOW)Linting YAML files...$(NC)"; \
		$(VENV_DIR)/bin/yamllint . || true; \
		echo "$(YELLOW)Running pre-commit checks (includes Markdown)...$(NC)"; \
		$(VENV_DIR)/bin/pre-commit run --all-files || true; \
	else \
		echo "$(RED)Virtual environment not found. Run 'make venv' first.$(NC)"; \
	fi

## Clean up Docker images and build cache
clean: ## Remove built images and clean Docker build cache
	@echo "$(YELLOW)Cleaning up Docker images...$(NC)"
	docker images | grep -E "(debian-systemd|oraclelinux-systemd)" | awk '{print $$3}' | xargs -r docker rmi -f || true
	docker system prune -f

clean-dev: ## Remove development environment (venv, pre-commit)
	@echo "$(YELLOW)Cleaning up development environment...$(NC)"
	rm -rf $(VENV_DIR)
	@if [ -f .git/hooks/pre-commit ]; then \
		echo "Removing pre-commit hooks..."; \
		rm -f .git/hooks/pre-commit .git/hooks/commit-msg .git/hooks/pre-push; \
	fi
	@echo "$(GREEN)Development environment cleaned$(NC)"

## Show image sizes
sizes: ## Show sizes of built images
	@echo "$(GREEN)Docker Image Sizes:$(NC)"
	@docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(debian-systemd|oraclelinux-systemd)" || echo "No images built yet"

## Push images to registry (requires docker login)
push: ## Push all built images to registry
	@echo "$(YELLOW)Pushing images to $(REGISTRY)...$(NC)"
	@for version in $(DEBIAN_VERSIONS); do \
		if docker images | grep -q "$(REGISTRY)/debian.*$$version[[:space:]]"; then \
			echo "Pushing Debian $$version..."; \
			docker push $(REGISTRY)/debian:$$version; \
			docker push $(REGISTRY)/debian:$$version-$(GIT_COMMIT); \
		fi \
	done
	@for version in $(ORACLELINUX_VERSIONS); do \
		if docker images | grep -q "$(REGISTRY)/oraclelinux.*$$version[[:space:]]"; then \
			echo "Pushing Oracle Linux $$version..."; \
			docker push $(REGISTRY)/oraclelinux:$$version; \
			docker push $(REGISTRY)/oraclelinux:$$version-$(GIT_COMMIT); \
		fi \
	done

## List available images
list: ## List all available built images
	@echo "$(GREEN)Available Images:$(NC)"
	@docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}" | head -1
	@docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}" | grep -E "(debian-systemd|oraclelinux-systemd|$(REGISTRY))" | sort || echo "No images found"
