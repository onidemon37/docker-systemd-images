# 📦 SystemD Base Images for Containers

This repository manages the automated build and push of specialized base images for containers, featuring SystemD support. These images are necessary for running services that require SystemD initialization within environments that utilize rootless containers or specific service management patterns.

All resulting container images are stored securely on the GitHub Container Registry (GHCR).

## 🚀 Available Images

The CI/CD pipeline builds and tags the following image families across multiple OS versions:

| OS Family    | Versions Built          | Full Image Name Format                       |
|--------------|------------------------|----------------------------------------------|
| Oracle Linux | `8`, `9`, `10`         | `ghcr.io/onidemon37/oraclelinux:<VERSION>` |
| Debian       | `10`, `11`, `12`, `13` | `ghcr.io/onidemon37/debian:<VERSION>`      |
| Fedora       | `41`, `42`, `43`       | `ghcr.io/onidemon37/fedora:<VERSION>`      |

(Note: onidemon37 refers to the GitHub user or organization that owns this repository.)

## ✨ Features and Use Cases

**Key Features**

- SystemD Enabled: Fully configured to run SystemD as the PID 1 process, ideal for complex service testing.
- Optimization: Minimal unnecessary services removed and optimized for speed and size in CI/CD pipelines.
- Multi-Arch Support: Built using Buildx and QEMU for multi-platform compatibility.
- Version Tagging: Each build receives a base version tag (e.g., :8) and a specific SHA-based tag (e.g., :8-<short_sha>).

**Primary Use Cases**

- Ansible/Molecule infrastructure testing.
- CI/CD integration tests requiring SystemD or service isolation.
- Development environments mimicking production service management.
- Service testing requiring high fidelity to traditional VM initialization.

## 🐳 Usage: Running the Images

These images require the Docker container to be run with --privileged and bind-mount the cgroup file system to enable SystemD functionality.

### Direct Docker Run

Replace onidemon37 with your GitHub organization/username.

```bash
# Oracle Linux 8
docker run -d --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  ghcr.io/onidemon37/oraclelinux:8

# Fedora 41
docker run -d --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  ghcr.io/onidemon37/fedora:41
```

### With Docker Compose

```yaml
services:
  app:
    image: ghcr.io/onidemon37/oraclelinux:8
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

### With Molecule/Ansible

```yaml
platforms:
  - name: instance
    image: ghcr.io/onidemon37/oraclelinux:8
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

## 🧑‍💻 Local Development

### Quick Start with Makefile

This repository includes a comprehensive Makefile to simplify local development and testing:

```bash
# Show all available targets
make help

# Build all images
make all

# Build specific OS family
make debian          # Build all Debian images
make oraclelinux     # Build all Oracle Linux images
make fedora          # Build all Fedora images

# Build specific version
make debian-12       # Build Debian 12
make oraclelinux-8   # Build Oracle Linux 8
make fedora-43       # Build Fedora 43

# Test images
make test            # Test all built images
make test-debian-12  # Test specific image

# Lint Dockerfiles
make lint           # Run hadolint on all Dockerfiles

# Clean up
make clean          # Remove built images and cache
```

### Manual Docker Build Commands

If you prefer to build manually without the Makefile:

```bash
# Oracle Linux 8
docker build --build-arg ORACLELINUX_VERSION=8 -t oraclelinux-systemd:8 ./oraclelinux/8/

# Oracle Linux 9
docker build --build-arg ORACLELINUX_VERSION=9 -t oraclelinux-systemd:9 ./oraclelinux/9/

# Oracle Linux 10
docker build --build-arg ORACLELINUX_VERSION=10 -t oraclelinux-systemd:10 ./oraclelinux/10/

# Fedora 41
docker build --build-arg FEDORA_VERSION=41 -t fedora-systemd:41 ./fedora/41/

# Fedora 42
docker build --build-arg FEDORA_VERSION=42 -t fedora-systemd:42 ./fedora/42/

# Fedora 43
docker build --build-arg FEDORA_VERSION=43 -t fedora-systemd:43 ./fedora/43/

# Debian 12
docker build --build-arg DEBIAN_VERSION=12 -t debian-systemd:12 ./debian/12/

# Debian 13
docker build --build-arg DEBIAN_VERSION=13 -t debian-systemd:13 ./debian/13/

# Debian 11
docker build --build-arg DEBIAN_VERSION=11 -t debian-systemd:11 ./debian/11/

# Debian 10 (uses buster-slim)
docker build --build-arg DEBIAN_VERSION=buster-slim -t debian-systemd:10 ./debian/10/
```

### Testing Built Images

Test that systemd works correctly in your built images:

```bash
# Test Debian 12
docker run --rm --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  debian-systemd:12 systemctl --version

# Test Oracle Linux 8
docker run --rm --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  oraclelinux-systemd:8 systemctl --version

# Test Oracle Linux 10
docker run --rm --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  oraclelinux-systemd:10 systemctl --version

# Test Fedora 41
docker run --rm --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  fedora-systemd:41 systemctl --version

# Test Fedora 43
docker run --rm --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  fedora-systemd:43 systemctl --version
```

### Development Environment Setup

#### Quick Setup (Recommended)

Set up the complete development environment with one command:

```bash
make setup-dev
```

This will automatically:
- Install hadolint for Dockerfile linting
- Create a Python virtual environment
- Install pre-commit hooks for automated code quality checks
- Configure linting for Dockerfiles, YAML, and Markdown files

#### Manual Setup

If you prefer to install components individually:

```bash
# Install hadolint for Dockerfile linting
make install-hadolint

# Create Python virtual environment and install tools
make venv

# Setup pre-commit hooks
make pre-commit-install
```

#### Prerequisites

- **Docker**: Ensure Docker is installed and running
- **Make**: Available on most Unix-like systems
- **Python 3**: Required for pre-commit and linting tools
- **Homebrew** (macOS): Recommended for installing hadolint

#### Alternative: Devbox Environment

For a completely isolated development environment, you can use [Devbox](https://www.jetify.com/devbox):

```bash
# Install devbox (if not already installed)
curl -fsSL https://get.jetify.com/devbox | bash

# Enter the development environment
devbox shell

# All tools will be automatically available:
# - Docker, hadolint, make, Python 3.11, yamllint, shellcheck
# - Environment variables configured
# - Helpful aliases available
```

**Devbox Quick Commands:**

```bash
# Smart devbox entry (auto-installs if needed)
make devbox         # Enter devbox environment

# Manual setup
make install-devbox # Install devbox only
make setup-devbox   # Complete setup + test

# Check status
make devbox-status  # Show installation status

# Inside devbox shell
setup-dev      # Same as: make setup-dev
build-all      # Same as: make all
test-all       # Same as: make test
lint-all       # Same as: make lint-all
quick-check    # Lint + build debian-12 + test
```

### Project Structure

```text
docker-systemd-images/
├── Makefile                    # Build automation
├── README.md                   # This file
├── renovate.json               # Renovate dependency updates
├── .github/workflows/          # CI/CD pipeline
│   ├── docker-build.yml        # Main build workflow
│   └── lint.yml               # Code quality checks
├── debian/                     # Debian-based images
│   ├── 10/Dockerfile          # Debian 10 (Buster) - EOL
│   ├── 11/Dockerfile          # Debian 11 (Bullseye)
│   ├── 12/Dockerfile          # Debian 12 (Bookworm)
│   └── 13/Dockerfile          # Debian 13 (Trixie)
├── oraclelinux/               # Oracle Linux images
│   ├── 8/Dockerfile           # Oracle Linux 8
│   ├── 9/Dockerfile           # Oracle Linux 9
│   └── 10/Dockerfile          # Oracle Linux 10
└── fedora/                    # Fedora images
    ├── 41/Dockerfile          # Fedora 41
    ├── 42/Dockerfile          # Fedora 42
    └── 43/Dockerfile          # Fedora 43
```

**Key Features of Each Image:**

- **Debian 10**: Uses archive.debian.org mirrors (EOL), includes Python 3.11 compiled from source
- **Debian 11-13**: Uses standard repos, includes system Python 3 + additional packages
- **Oracle Linux 8-10**: Uses dnf package manager, includes Python 3.11 via alternatives system
- **Fedora 41-43**: Uses dnf package manager, includes latest Python 3 and systemd versions

### Code Quality and Testing Workflow

#### Linting

```bash
# Lint Dockerfiles only
make lint

# Lint all files (Dockerfiles, YAML, Markdown)
make lint-all

# Run pre-commit checks on all files
make pre-commit-run
```

#### Testing Images

```bash
# Test all built images
make test

# Test specific OS family
make test-debian
make test-oraclelinux

# Test specific version
make test-debian-12
make test-oraclelinux-8
```

#### Pre-commit Integration

Once you run `make setup-dev`, pre-commit hooks will automatically run on every commit, checking:

- Dockerfile linting with hadolint
- YAML formatting and validation
- Markdown formatting and links
- Trailing whitespace and file endings
- Shell script linting (if any)

To bypass pre-commit checks (not recommended):

```bash
git commit --no-verify -m "commit message"
```

## ⚙️ CI/CD Pipeline (.github/workflows/docker-build.yml)

The build process is managed entirely by GitHub Actions, running on push events or manually triggered via workflow_dispatch.

| Feature        | Details                                                                |
|----------------|------------------------------------------------------------------------|
| Registry       | ghcr.io                                                                |
| Authentication | Uses secrets.GITHUB_TOKEN for GHCR access.                             |
| Builders       | Uses Buildx and QEMU for multi-platform support.                       |
| Tags Generated | Base version (8, 9, 11, 12) and SHA-based tag (<VERSION>-<short_sha>). |

**Running the Workflow Manually**

You can manually trigger a build run for specific OS families:

1. Navigate to the Actions tab in the repository.
2. Select the Build and Push SystemD Images workflow.
3. Click Run workflow.
4. In the dropdown, select the os_family to build:

- all (default)
- oraclelinux
- debian

## 🔄 Automated Dependency Management

This repository uses [Renovate](https://docs.renovatebot.com/) for automated dependency updates:

- **Configuration**: [`renovate.json`](./renovate.json) extends shared configuration from `onidemon37/renovate-config`
- **Updates**: Automatically creates PRs for base image updates (Oracle Linux, Debian)
- **Schedule**: Runs on a configured schedule to keep base images current
- **Security**: Prioritizes security updates and provides vulnerability scanning

The Renovate bot monitors:
- Docker base images (oraclelinux:8, oraclelinux:9, oraclelinux:10, debian:*)
- Development dependencies in devbox.json
- GitHub Actions versions in workflow files

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Test your changes locally using the "Building Locally" guide.
2. Update documentation or Dockerfiles as necessary.
3. Submit a Pull Request (PR) with a clear description of your changes.
