# 📦 SystemD Base Images for Containers

This repository manages the automated build and push of specialized base images for containers, featuring SystemD support. These images are necessary for running services that require SystemD initialization within environments that utilize rootless containers or specific service management patterns.

All resulting container images are stored securely on the GitHub Container Registry (GHCR).

## 🚀 Available Images

The CI/CD pipeline builds and tags the following image families across multiple OS versions:

| OS Family         | Versions Built | Full Image Name Format                   |
| ----------------- | -------------- |                                          |
| Oracle Linux      | `8`, `9`       | ghcr.io/sectigo/sectigo-oracle:<VERSION> |
| Debian            | `11`, `12`     | ghcr.io/sectigo/sectigo-debian:<VERSION> |

(Note: sectigo refers to the GitHub user or organization that owns this repository.)

## ✨ Features and Use Cases

*Key Features*
- SystemD Enabled: Fully configured to run SystemD as the PID 1 process, ideal for complex service testing.
- Optimization: Minimal unnecessary services removed and optimized for speed and size in CI/CD pipelines.
- Multi-Arch Support: Built using Buildx and QEMU for multi-platform compatibility.
- Version Tagging: Each build receives a base version tag (e.g., :8) and a specific SHA-based tag (e.g., :8-<short_sha>).

* Primary Use Cases *
- Ansible/Molecule infrastructure testing.
- CI/CD integration tests requiring SystemD or service isolation.
- Development environments mimicking production service management.
- Service testing requiring high fidelity to traditional VM initialization.

## 🐳 Usage: Running the Images

These images require the Docker container to be run with --privileged and bind-mount the cgroup file system to enable SystemD functionality.

1. Direct Docker Run

Replace <sectigo> with your GitHub organization/username.

```
docker run -d --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
  ghcr.io/<sectigo>/sectigo-oracle:8
```

2. With Docker Compose

```
services:
  app:
    image: ghcr.io/sectigo/sectigo-oracle:8
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

3. With Molecule/Ansible

```
platforms:
  - name: instance
    image: ghcr.io/sectigo/sectigo-oracle:8
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
```

## 🧑‍💻 Building Locally

To build these images on your local machine, navigate to the project root and use the following commands.

```
# Example: Build Oracle Linux 8
docker build -t sectigo-oracle:8 ./oraclelinux/8/

# Example: Build Debian 12
docker build -t sectigo-debian:12 ./debian/12/
```

## ⚙️ CI/CD Pipeline (.github/workflows/docker-build.yml)

The build process is managed entirely by GitHub Actions, running on push events or manually triggered via workflow_dispatch.

| ---------------|------------------------------------------------------------------------ |
| Feature        |  Details                                                                |
| -------------- | ----------------------------------------------------------------------- |
| Registry       |  ghcr.io                                                                |
| -------------- | ----------------------------------------------------------------------- |
| Authentication |  Uses secrets.GITHUB_TOKEN for GHCR access.                             |
| -------------- |------------------------------------------------------------------------ |
| Builders       |  Uses Buildx and QEMU for multi-platform support.                       |
| -------------- |------------------------------------------------------------------------ |
| Tags Generated |  Base version (8, 9, 11, 12) and SHA-based tag (<VERSION>-<short_sha>). |
| -------------- | ----------------------------------------------------------------------- |

*Running the Workflow Manually*

You can manually trigger a build run for specific OS families:

1. Navigate to the Actions tab in the repository.
2. Select the Build and Push SystemD Images workflow.
3. Click Run workflow.
4. In the dropdown, select the os_family to build:
  - all (default)
  - oraclelinux
  - debian

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Test your changes locally using the "Building Locally" guide.
2. Update documentation or Dockerfiles as necessary.
3. Submit a Pull Request (PR) with a clear description of your changes
