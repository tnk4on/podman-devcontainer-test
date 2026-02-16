# Podman Dev Container Compatibility Tests

[![Dev Container Compatibility Tests](https://github.com/tnk4on/podman-devcontainer-test/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tnk4on/podman-devcontainer-test/actions/workflows/test.yml)

<!-- VERSION_TABLE_START -->
| Platform | OS Version | Podman | devcontainer CLI | Last Tested |
|----------|------------|--------|------------------|-------------|
| Ubuntu | 24.04 | 4.9.3 | 0.83.0 | 2026-02-16 |
| Fedora | 43 | 5.7.1 | 0.83.0 | 2026-02-16 |
<!-- VERSION_TABLE_END -->

Automated compatibility tests for [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) with [Podman](https://podman.io/).

## Quick Start

```bash
# Install devcontainers CLI
npm install -g @devcontainers/cli

# Run a test
cd tests/minimal
devcontainer up --workspace-folder . --docker-path podman
```

**Minimum devcontainer.json** (no special config needed since CLI v0.76.0):

```json
{
  "image": "alpine:latest"
}
```

---

## Background

This repository verifies VS Code Dev Containers compatibility with Podman, addressing:

- [#2881](https://github.com/microsoft/vscode-remote-release/issues/2881) - Container samples not working using podman
- [#6759](https://github.com/microsoft/vscode-remote-release/issues/6759) - Podman Usage Improvements

### ✅ Resolution

| Component | Version | Changes |
|-----------|---------|---------|
| **devcontainers/cli** | v0.76.0+ | Auto-detects Podman, applies `--security-opt label=disable` and `--userns=keep-id` |
| **Dev Containers Extension** | 0.412.0+ | Includes fixed CLI |

---

## Test Cases

### Basic Tests

| Test | Description |
|------|-------------|
| **Minimal** | `{"image": "alpine:latest"}` |
| **Dockerfile** | Custom Dockerfile build |
| **Features (Go)** | Dev Container Features |
| **Docker in Docker** | Nested container support |

### Sample Tests

Official Dev Container templates verified with Podman:

| Sample | Image |
|--------|-------|
| **Python** | `mcr.microsoft.com/devcontainers/python:1-3.12` |
| **Node.js** | `mcr.microsoft.com/devcontainers/javascript-node:1-22` |
| **Go** | `mcr.microsoft.com/devcontainers/go:1-1.22` |

---

## Automated Testing

### Triggers

| Trigger | Description |
|---------|-------------|
| **Daily** | 00:00 UTC (only if Podman/CLI versions changed) |
| **On Push** | When test files are modified |
| **Manual** | Via workflow dispatch |

### Infrastructure

| Platform | Infrastructure | Notes |
|----------|----------------|-------|
| **Ubuntu** | GitHub-hosted runner | Stable Podman (apt) |
| **Fedora** | AWS EC2 spot instance (c6id.large) | Latest Podman, NVMe SSD |

---

## Running Tests Locally

### Prerequisites

- Podman installed and running
- Node.js 18+

### macOS

```bash
podman machine init && podman machine start
./scripts/run-tests.sh
```

### Linux

```bash
./scripts/run-tests.sh
```

---

## Version Compatibility

| Dev Containers Extension | devcontainers/cli | Status |
|--------------------------|-------------------|--------|
| 0.412.0+ | 0.76.0+ | ✅ Fully compatible |
| < 0.412.0 | < 0.76.0 | ⚠️ Requires manual workarounds |

---

## Contributing

1. Fork the repository
2. Add new test cases under `tests/`
3. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Links

- [Podman](https://podman.io/) | [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) | [devcontainers/cli](https://github.com/devcontainers/cli) | [Dev Containers Spec](https://containers.dev/)
