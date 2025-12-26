# Podman Dev Container Compatibility Tests

| Platform | Status |
|----------|--------|
| Ubuntu | [![Dev Container Compatibility Tests (Ubuntu)](https://github.com/tnk4on/podman-devcontainer-test/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tnk4on/podman-devcontainer-test/actions/workflows/test.yml) |
| Fedora | [![Dev Container Compatibility Tests (Fedora)](https://github.com/tnk4on/podman-devcontainer-test/actions/workflows/test-fedora.yml/badge.svg?branch=main)](https://github.com/tnk4on/podman-devcontainer-test/actions/workflows/test-fedora.yml) |

Automated compatibility tests for [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers) with [Podman](https://podman.io/).

## Background

This repository was created to verify that VS Code Dev Containers work correctly with Podman as the container runtime. It addresses the issues discussed in:

- [microsoft/vscode-remote-release#2881](https://github.com/microsoft/vscode-remote-release/issues/2881) - Container samples not working using podman
- [microsoft/vscode-remote-release#6759](https://github.com/microsoft/vscode-remote-release/issues/6759) - Podman Usage Improvements

### Resolution

The compatibility issues have been resolved in:

- **devcontainers/cli v0.76.0** (April 2025) - [PR #985](https://github.com/devcontainers/cli/pull/985)
  - Added automatic Podman detection
  - Auto-applies `--security-opt label=disable` and `--userns=keep-id` when using Podman

- **Dev Containers Extension 0.412.0+** (April 2025)
  - Includes the fixed devcontainers/cli

## Test Cases

### Basic Tests

| Test | Description | devcontainer.json |
|------|-------------|-------------------|
| **Minimal** | Simplest possible config | `{"image": "alpine:latest"}` |
| **Dockerfile** | Custom Dockerfile build | `{"build": {"dockerfile": "..."}}` |
| **Features (Go)** | Dev Container Features | `{"features": {"go": {}}}` |
| **Docker in Docker** | Nested container support | `{"features": {"docker-in-docker": {}}}` |

### Sample Tests (Issue #2881)

These tests verify that official Dev Container samples work with Podman:

| Sample | Template | Image |
|--------|----------|-------|
| **Python** | `ghcr.io/devcontainers/templates/python` | `mcr.microsoft.com/devcontainers/python:1-3.12` |
| **Node.js** | `ghcr.io/devcontainers/templates/javascript-node` | `mcr.microsoft.com/devcontainers/javascript-node:1-22` |
| **Go** | `ghcr.io/devcontainers/templates/go` | `mcr.microsoft.com/devcontainers/go:1-1.22` |

## Automated Testing

Tests run on two platforms to ensure compatibility across different Linux distributions and Podman versions:

| Platform | OS | Podman Version | Infrastructure |
|----------|----|--------------------|----------------|
| **Ubuntu** | Ubuntu 24.04 | 4.x (stable) | GitHub-hosted runner |
| **Fedora** | Fedora CoreOS | 5.x (latest) | GCE VM (on-demand) |

### Ubuntu - Triggers

| Trigger | Description |
|---------|-------------|
| **Daily** | Scheduled at 00:00 UTC |
| **On Release** | When Podman or @devcontainers/cli releases a new version |
| **On Push** | When test files are modified |
| **Manual** | Via workflow dispatch |

### Fedora (GCE) - Triggers

| Trigger | Description |
|---------|-------------|
| **Weekly** | Scheduled on Sunday at 00:00 UTC |
| **Manual** | Via workflow dispatch |

**Note**: Fedora tests create an ephemeral GCE VM, run tests, and delete the VM automatically.

**Why two platforms?**
- **Ubuntu**: Widely used, stable Podman version, frequent testing
- **Fedora**: Latest Podman version (Podman is developed by Red Hat/Fedora), weekly testing

### Notifications

Notifications are sent only when relevant:

| Condition | Action |
|-----------|--------|
| **Test failure** | Creates Issue + Comment on Tracking Issue |
| **New Podman version** | Comment on Tracking Issue |
| **New CLI version** | Comment on Tracking Issue |
| **Manual trigger** | Comment on Tracking Issue |
| **Daily success (no changes)** | No notification |

## Running Tests Locally

### Prerequisites

- Podman installed and running
- Node.js 18+
- npm

### macOS

```bash
# Start Podman machine
podman machine init
podman machine start

# Run tests
./scripts/run-tests.sh
```

### Linux

```bash
# Run tests
./scripts/run-tests.sh
```

### Manual Test

```bash
# Install devcontainers CLI
npm install -g @devcontainers/cli

# Run a single test
cd tests/minimal
devcontainer up --workspace-folder . --docker-path podman
```

## Minimum devcontainer.json

The simplest working configuration:

```json
{
  "image": "alpine:latest"
}
```

No need for:
- `name` (optional)
- `remoteUser` (auto-detected)
- `runArgs` with `--userns=keep-id` (auto-added since CLI v0.76.0)
- `runArgs` with `--security-opt label=disable` (auto-added since CLI v0.76.0)

## Version Compatibility

| Dev Containers Extension | devcontainers/cli | Status |
|--------------------------|-------------------|--------|
| 0.412.0+ | 0.76.0+ | ✅ Fully compatible |
| < 0.412.0 | < 0.76.0 | ⚠️ Requires manual workarounds |

## Contributing

1. Fork the repository
2. Add new test cases under `tests/`
3. Update the GitHub Actions workflow if needed
4. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Related Links

- [Podman](https://podman.io/)
- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [devcontainers/cli](https://github.com/devcontainers/cli)
- [Dev Containers Specification](https://containers.dev/)

