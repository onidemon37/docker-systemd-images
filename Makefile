# Makefile for building Docker SystemD images locally
# Author: Edino Moniz

.PHONY: help all debian oraclelinux clean clean-dev test lint lint-all install-deps setup-dev setup-devbox devbox devbox-status devbox-update install-devbox install-hadolint venv pre-commit-install pre-commit-run check-docker

# Default target
.DEFAULT_GOAL := help

# Variables
REGISTRY ?= ghcr.io/onidemon37
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT := $(shell git rev-parse --short HEAD)

# Docker command detection and PATH setup
DOCKER := $(shell \
	if command -v docker >/dev/null 2>&1; then \
		echo "docker"; \
	elif command -v /usr/local/bin/docker >/dev/null 2>&1; then \
		echo "/usr/local/bin/docker"; \
	elif command -v /Applications/Docker.app/Contents/Resources/bin/docker >/dev/null 2>&1; then \
		echo "/Applications/Docker.app/Contents/Resources/bin/docker"; \
	else \
		echo "docker"; \
	fi \
)

# Docker Desktop PATH fix
export PATH := /usr/local/bin:/Applications/Docker.app/Contents/Resources/bin:$(PATH)

# OS Versions
DEBIAN_VERSIONS := 10 11 12 13
# Oracle Linux versions
ORACLELINUX_VERSIONS := 8 9 10
# Fedora versions (latest 3 releases)
FEDORA_VERSIONS := 41 42 43

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
	@echo "  make fedora-43          # Build Fedora 43 image"
	@echo "  make debian             # Build all Debian images"
	@echo "  make oraclelinux        # Build all Oracle Linux images"
	@echo "  make fedora             # Build all Fedora images"
	@echo "  make all                # Build all images"
	@echo "  make test-debian-12     # Test Debian 12 image"
	@echo "  make test-fedora-43     # Test Fedora 43 image"
	@echo "  make setup-dev          # Setup complete development environment"
	@echo "  make devbox             # Enter devbox shell (auto-install if needed)"
	@echo "  make setup-devbox       # Setup devbox isolated environment"
	@echo "  make install-devbox     # Install devbox only"
	@echo "  make install-deps       # Install all development dependencies"

## Development Environment Setup

check-docker: ## Check if Docker is available and running
	@echo "$(YELLOW)Checking for Docker...$(NC)"
	@DOCKER_CMD=""; \
	if command -v docker >/dev/null 2>&1; then \
		DOCKER_CMD="docker"; \
	elif command -v /usr/local/bin/docker >/dev/null 2>&1; then \
		DOCKER_CMD="/usr/local/bin/docker"; \
	elif command -v /Applications/Docker.app/Contents/Resources/bin/docker >/dev/null 2>&1; then \
		DOCKER_CMD="/Applications/Docker.app/Contents/Resources/bin/docker"; \
	else \
		echo "$(RED)Docker not found in common locations.$(NC)"; \
		echo "$(YELLOW)Please ensure Docker is installed and running.$(NC)"; \
		echo "$(YELLOW)Common paths: /usr/local/bin/docker, /Applications/Docker.app/Contents/Resources/bin/docker$(NC)"; \
		exit 1; \
	fi; \
	echo "$(GREEN)Docker found: $$DOCKER_CMD$(NC)"; \
	$$DOCKER_CMD --version || (echo "$(RED)Docker daemon may not be running$(NC)" && exit 1); \
	echo "$(YELLOW)Testing Docker connectivity...$(NC)"; \
	$$DOCKER_CMD info >/dev/null 2>&1 || (echo "$(RED)Docker daemon is not running or not accessible$(NC)" && exit 1); \
	echo "$(GREEN)Docker is ready!$(NC)"

setup-dev: ## Setup complete development environment (hadolint + pre-commit)
	@echo "$(GREEN)Setting up development environment...$(NC)"
	@$(MAKE) install-hadolint
	@$(MAKE) venv
	@$(MAKE) pre-commit-install
	@echo "$(GREEN)Development environment ready!$(NC)"
	@echo "$(YELLOW)Activate virtualenv with: source $(VENV_DIR)/bin/activate$(NC)"

setup-devbox: ## Setup devbox isolated development environment
	@echo "$(GREEN)Setting up devbox development environment...$(NC)"
	@$(MAKE) install-devbox
	@if command -v devbox >/dev/null 2>&1; then \
		echo "$(YELLOW)Testing devbox environment...$(NC)"; \
		devbox run echo "Devbox environment is working!"; \
		echo "$(GREEN)Devbox setup complete!$(NC)"; \
		echo "$(YELLOW)Enter the environment with: devbox shell$(NC)"; \
		echo "$(YELLOW)Or run commands with: devbox run <command>$(NC)"; \
	else \
		echo "$(RED)Devbox setup incomplete. Please restart your shell and try again.$(NC)"; \
	fi

devbox: ## Enter devbox shell if available, otherwise setup devbox
	@if [ -f "devbox.json" ]; then \
		DEVBOX_CMD=""; \
		if command -v devbox >/dev/null 2>&1; then \
			DEVBOX_CMD="devbox"; \
		elif [ -f "$${HOME}/.local/bin/devbox" ]; then \
			DEVBOX_CMD="$${HOME}/.local/bin/devbox"; \
		elif [ -f "/usr/local/bin/devbox" ]; then \
			DEVBOX_CMD="/usr/local/bin/devbox"; \
		fi; \
		if [ -n "$$DEVBOX_CMD" ]; then \
			echo "$(GREEN)Entering devbox environment with: $$DEVBOX_CMD$(NC)"; \
			$$DEVBOX_CMD shell; \
		else \
			echo "$(YELLOW)Devbox not found but devbox.json exists.$(NC)"; \
			echo "$(YELLOW)Options:$(NC)"; \
			echo "  1. Install devbox: make install-devbox"; \
			echo "  2. If already installed, restart your shell"; \
			echo "$(YELLOW)Installing devbox automatically...$(NC)"; \
			$(MAKE) install-devbox; \
		fi; \
	else \
		echo "$(RED)No devbox.json file found in current directory.$(NC)"; \
		echo "$(YELLOW)This command should be run from the project root.$(NC)"; \
		exit 1; \
	fi

devbox-status: ## Check devbox installation and environment status
	@echo "$(YELLOW)Devbox Environment Status:$(NC)"
	@echo ""
	@if [ -f "devbox.json" ]; then \
		echo "$(GREEN)✅ devbox.json found$(NC)"; \
	else \
		echo "$(RED)❌ devbox.json not found$(NC)"; \
	fi
	@DEVBOX_CMD=""; \
	if command -v devbox >/dev/null 2>&1; then \
		DEVBOX_CMD="devbox"; \
	elif [ -f "$${HOME}/.local/bin/devbox" ]; then \
		DEVBOX_CMD="$${HOME}/.local/bin/devbox"; \
	elif [ -f "/usr/local/bin/devbox" ]; then \
		DEVBOX_CMD="/usr/local/bin/devbox"; \
	fi; \
	if [ -n "$$DEVBOX_CMD" ]; then \
		echo "$(GREEN)✅ devbox found: $$DEVBOX_CMD$(NC)"; \
		$$DEVBOX_CMD version; \
		if [ -f "devbox.json" ]; then \
			echo "$(YELLOW)📦 Available packages:$(NC)"; \
			cat devbox.json | jq -r '.packages[]' 2>/dev/null | sed 's/^/   - /' || echo "   (Unable to read package list)"; \
		fi; \
	else \
		echo "$(RED)❌ devbox not installed$(NC)"; \
		echo "$(YELLOW)   Install with: make install-devbox$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Quick commands:$(NC)"
	@echo "  make devbox           # Enter devbox environment"
	@echo "  make install-devbox   # Install devbox"
	@echo "  make setup-devbox     # Complete devbox setup"
	@echo "  make devbox-update    # Update devbox.json format"

devbox-update: ## Update devbox.json to latest format
	@DEVBOX_CMD=""; \
	if command -v devbox >/dev/null 2>&1; then \
		DEVBOX_CMD="devbox"; \
	elif [ -f "$${HOME}/.local/bin/devbox" ]; then \
		DEVBOX_CMD="$${HOME}/.local/bin/devbox"; \
	elif [ -f "/usr/local/bin/devbox" ]; then \
		DEVBOX_CMD="/usr/local/bin/devbox"; \
	fi; \
	if [ -n "$$DEVBOX_CMD" ]; then \
		echo "$(YELLOW)Updating devbox.json format with: $$DEVBOX_CMD$(NC)"; \
		$$DEVBOX_CMD update; \
		echo "$(GREEN)devbox.json updated successfully$(NC)"; \
	else \
		echo "$(RED)Devbox not installed. Run 'make install-devbox' first.$(NC)"; \
	fi

install-deps: ## Install all development dependencies
install-deps: install-hadolint venv pre-commit-install

install-devbox: ## Install devbox for isolated development environments
	@echo "$(YELLOW)Installing devbox...$(NC)"
	@DEVBOX_CMD=""; \
	if command -v devbox >/dev/null 2>&1; then \
		DEVBOX_CMD="devbox"; \
	elif [ -f "$${HOME}/.local/bin/devbox" ]; then \
		DEVBOX_CMD="$${HOME}/.local/bin/devbox"; \
	elif [ -f "/usr/local/bin/devbox" ]; then \
		DEVBOX_CMD="/usr/local/bin/devbox"; \
	fi; \
	if [ -n "$$DEVBOX_CMD" ]; then \
		echo "$(GREEN)Devbox already installed: $$DEVBOX_CMD$(NC)"; \
		$$DEVBOX_CMD version; \
	else \
		echo "$(YELLOW)Downloading and installing devbox...$(NC)"; \
		if command -v curl >/dev/null 2>&1; then \
			curl -fsSL https://get.jetify.com/devbox | bash; \
			echo "$(YELLOW)Installation complete. Devbox should be available at: $$HOME/.local/bin/devbox$(NC)"; \
			if [ -f "$${HOME}/.local/bin/devbox" ]; then \
				echo "$(GREEN)✅ Devbox installed successfully$(NC)"; \
				$${HOME}/.local/bin/devbox version; \
			fi; \
		else \
			echo "$(RED)curl not found. Please install curl first.$(NC)"; \
			echo "$(YELLOW)Manual installation: visit https://www.jetify.com/devbox/docs/installing_devbox/$(NC)"; \
			exit 1; \
		fi; \
		if command -v devbox >/dev/null 2>&1 || command -v ~/.local/bin/devbox >/dev/null 2>&1; then \
			echo "$(GREEN)Devbox installed successfully!$(NC)"; \
			echo "$(YELLOW)Note: You may need to restart your shell or run:$(NC)"; \
			echo "$(YELLOW)  export PATH=\"\$$HOME/.local/bin:\$$PATH\"$(NC)"; \
			echo "$(YELLOW)Then run 'devbox shell' to enter the development environment$(NC)"; \
		else \
			echo "$(RED)Devbox installation may have failed. Please check manually.$(NC)"; \
			echo "$(YELLOW)Try restarting your shell or sourcing your profile$(NC)"; \
		fi; \
	fi

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
all: check-docker debian oraclelinux fedora

debian: ## Build all Debian images
debian: $(addprefix debian-, $(DEBIAN_VERSIONS))

oraclelinux: ## Build all Oracle Linux images
oraclelinux: $(addprefix oraclelinux-, $(ORACLELINUX_VERSIONS))

fedora: ## Build all Fedora images
fedora: $(addprefix fedora-, $(FEDORA_VERSIONS))

# Individual Debian targets
debian-10: ## Build Debian 10 image
	@echo "$(GREEN)Building Debian 10 image...$(NC)"
	$(DOCKER) build \
		--build-arg DEBIAN_VERSION=buster-slim \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:10 \
		-t $(REGISTRY)/debian:10 \
		-t $(REGISTRY)/debian:10-$(GIT_COMMIT) \
		./debian/10/

debian-11: ## Build Debian 11 image
	@echo "$(GREEN)Building Debian 11 image...$(NC)"
	$(DOCKER) build \
		--build-arg DEBIAN_VERSION=11 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:11 \
		-t $(REGISTRY)/debian:11 \
		-t $(REGISTRY)/debian:11-$(GIT_COMMIT) \
		./debian/11/

debian-12: ## Build Debian 12 image
	@echo "$(GREEN)Building Debian 12 image...$(NC)"
	$(DOCKER) build \
		--build-arg DEBIAN_VERSION=12 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:12 \
		-t $(REGISTRY)/debian:12 \
		-t $(REGISTRY)/debian:12-$(GIT_COMMIT) \
		./debian/12/

debian-13: ## Build Debian 13 image
	@echo "$(GREEN)Building Debian 13 image...$(NC)"
	@$(MAKE) check-docker
	$(DOCKER) build \
		--build-arg DEBIAN_VERSION=trixie \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t debian-systemd:13 \
		-t $(REGISTRY)/debian:13 \
		-t $(REGISTRY)/debian:13-$(GIT_COMMIT) \
		./debian/13/

# Individual Oracle Linux targets
oraclelinux-8: ## Build Oracle Linux 8 image
	@echo "$(GREEN)Building Oracle Linux 8 image...$(NC)"
	$(DOCKER) build \
		--build-arg ORACLELINUX_VERSION=8 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t oraclelinux-systemd:8 \
		-t $(REGISTRY)/oraclelinux:8 \
		-t $(REGISTRY)/oraclelinux:8-$(GIT_COMMIT) \
		./oraclelinux/8/

oraclelinux-9: ## Build Oracle Linux 9 image
	@echo "$(GREEN)Building Oracle Linux 9 image...$(NC)"
	$(DOCKER) build \
		--build-arg ORACLELINUX_VERSION=9 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t oraclelinux-systemd:9 \
		-t $(REGISTRY)/oraclelinux:9 \
		-t $(REGISTRY)/oraclelinux:9-$(GIT_COMMIT) \
		./oraclelinux/9/

oraclelinux-10: ## Build Oracle Linux 10 image
	@echo "$(GREEN)Building Oracle Linux 10 image...$(NC)"
	$(DOCKER) build \
		--build-arg ORACLELINUX_VERSION=10 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t oraclelinux-systemd:10 \
		-t $(REGISTRY)/oraclelinux:10 \
		-t $(REGISTRY)/oraclelinux:10-$(GIT_COMMIT) \
		./oraclelinux/10/

# Individual Fedora targets
fedora-41: ## Build Fedora 41 image
	@echo "$(GREEN)Building Fedora 41 image...$(NC)"
	$(DOCKER) build \
		--build-arg FEDORA_VERSION=41 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t fedora-systemd:41 \
		-t $(REGISTRY)/fedora:41 \
		-t $(REGISTRY)/fedora:41-$(GIT_COMMIT) \
		./fedora/41/

fedora-42: ## Build Fedora 42 image
	@echo "$(GREEN)Building Fedora 42 image...$(NC)"
	$(DOCKER) build \
		--build-arg FEDORA_VERSION=42 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t fedora-systemd:42 \
		-t $(REGISTRY)/fedora:42 \
		-t $(REGISTRY)/fedora:42-$(GIT_COMMIT) \
		./fedora/42/

fedora-43: ## Build Fedora 43 image
	@echo "$(GREEN)Building Fedora 43 image...$(NC)"
	$(DOCKER) build \
		--build-arg FEDORA_VERSION=43 \
		--label "build.date=$(BUILD_DATE)" \
		--label "build.commit=$(GIT_COMMIT)" \
		-t fedora-systemd:43 \
		-t $(REGISTRY)/fedora:43 \
		-t $(REGISTRY)/fedora:43-$(GIT_COMMIT) \
		./fedora/43/

test-debian: ## Test Debian images
test-debian: $(addprefix test-debian-, $(DEBIAN_VERSIONS))

test-oraclelinux: ## Test Oracle Linux images
test-oraclelinux: $(addprefix test-oraclelinux-, $(ORACLELINUX_VERSIONS))

test-fedora: ## Test Fedora images
test-fedora: $(addprefix test-fedora-, $(FEDORA_VERSIONS))

test: ## Test all images
test: test-debian test-oraclelinux test-fedora

# Individual test targets
test-debian-10: ## Test Debian 10 image
	@echo "$(YELLOW)Testing Debian 10 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:10 systemctl --version

test-debian-11: ## Test Debian 11 image
	@echo "$(YELLOW)Testing Debian 11 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:11 systemctl --version

test-debian-12: ## Test Debian 12 image
	@echo "$(YELLOW)Testing Debian 12 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:12 systemctl --version

test-debian-13: ## Test Debian 13 image
	@echo "$(YELLOW)Testing Debian 13 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro debian-systemd:13 systemctl --version

test-oraclelinux-8: ## Test Oracle Linux 8 image
	@echo "$(YELLOW)Testing Oracle Linux 8 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro oraclelinux-systemd:8 systemctl --version

test-oraclelinux-9: ## Test Oracle Linux 9 image
	@echo "$(YELLOW)Testing Oracle Linux 9 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro oraclelinux-systemd:9 systemctl --version

test-oraclelinux-10: ## Test Oracle Linux 10 image
	@echo "$(YELLOW)Testing Oracle Linux 10 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro oraclelinux-systemd:10 systemctl --version

test-fedora-41: ## Test Fedora 41 image
	@echo "$(YELLOW)Testing Fedora 41 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro fedora-systemd:41 systemctl --version

test-fedora-42: ## Test Fedora 42 image
	@echo "$(YELLOW)Testing Fedora 42 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro fedora-systemd:42 systemctl --version

test-fedora-43: ## Test Fedora 43 image
	@echo "$(YELLOW)Testing Fedora 43 image...$(NC)"
	$(DOCKER) run --rm --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:ro fedora-systemd:43 systemctl --version

## Run hadolint on all Dockerfiles
lint: ## Lint all Dockerfiles with hadolint
	@echo "$(YELLOW)Linting Dockerfiles...$(NC)"
	@if command -v hadolint >/dev/null 2>&1; then \
		find . -name "Dockerfile" -exec echo "Linting {}" \; -exec hadolint --ignore DL3041 --ignore DL3008 --ignore DL3013 --ignore DL3003 --ignore DL3047 --ignore SC2086 {} \; || true; \
	else \
		echo "$(RED)hadolint not found. Install with: make install-hadolint$(NC)"; \
		echo "$(YELLOW)Running hadolint via Docker instead...$(NC)"; \
		find . -name "Dockerfile" -exec echo "Linting {}" \; -exec $(DOCKER) run --rm -i hadolint/hadolint:latest hadolint --ignore DL3041 --ignore DL3008 --ignore DL3013 --ignore DL3003 --ignore DL3047 --ignore SC2086 - < {} \; || true; \
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
	$(DOCKER) images | grep -E "(debian-systemd|oraclelinux-systemd)" | awk '{print $$3}' | xargs -r $(DOCKER) rmi -f || true
	$(DOCKER) system prune -f

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
	@$(DOCKER) images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}" | grep -E "(debian-systemd|oraclelinux-systemd|fedora-systemd)" || echo "No images built yet"

## Push images to registry (requires docker login)
push: ## Push all built images to registry
	@echo "$(YELLOW)Pushing images to $(REGISTRY)...$(NC)"
	@for version in $(DEBIAN_VERSIONS); do \
		if $(DOCKER) images | grep -q "$(REGISTRY)/debian.*$$version[[:space:]]"; then \
			echo "Pushing Debian $$version..."; \
			$(DOCKER) push $(REGISTRY)/debian:$$version; \
			$(DOCKER) push $(REGISTRY)/debian:$$version-$(GIT_COMMIT); \
		fi \
	done
	@for version in $(ORACLELINUX_VERSIONS); do \
		if $(DOCKER) images | grep -q "$(REGISTRY)/oraclelinux.*$$version[[:space:]]"; then \
			echo "Pushing Oracle Linux $$version..."; \
			$(DOCKER) push $(REGISTRY)/oraclelinux:$$version; \
			$(DOCKER) push $(REGISTRY)/oraclelinux:$$version-$(GIT_COMMIT); \
		fi \
	done
	@for version in $(FEDORA_VERSIONS); do \
		if $(DOCKER) images | grep -q "$(REGISTRY)/fedora.*$$version[[:space:]]"; then \
			echo "Pushing Fedora $$version..."; \
			$(DOCKER) push $(REGISTRY)/fedora:$$version; \
			$(DOCKER) push $(REGISTRY)/fedora:$$version-$(GIT_COMMIT); \
		fi \
	done

## List available images
list: ## List all available built images
	@echo "$(GREEN)Available Images:$(NC)"
	@$(DOCKER) images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}" | head -1
	@$(DOCKER) images --format "table {{.Repository}}\t{{.Tag}}\t{{.CreatedSince}}\t{{.Size}}" | grep -E "(debian-systemd|oraclelinux-systemd|$(REGISTRY))" | sort || echo "No images found"
