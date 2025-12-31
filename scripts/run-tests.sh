#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Results tracking
PASSED=0
FAILED=0
RESULTS=""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "=============================================="
echo "Podman Dev Container Compatibility Test Suite"
echo "=============================================="
echo ""

# Print environment info
echo "Environment:"
echo "  - OS: $(uname -s) $(uname -m)"
echo "  - Podman: $(podman --version 2>/dev/null || echo 'not installed')"
echo "  - @devcontainers/cli: $(devcontainer --version 2>/dev/null || echo 'not installed')"
echo "  - Node.js: $(node --version 2>/dev/null || echo 'not installed')"
echo ""

# Check if podman is available
if ! command -v podman &> /dev/null; then
    echo -e "${RED}Error: podman is not installed${NC}"
    exit 1
fi

# Check if devcontainer CLI is available
if ! command -v devcontainer &> /dev/null; then
    echo -e "${RED}Error: @devcontainers/cli is not installed${NC}"
    echo "Install with: npm install -g @devcontainers/cli"
    exit 1
fi

# Check if podman machine is running (for macOS/Windows)
if [[ "$(uname -s)" == "Darwin" ]] || [[ "$(uname -s)" == *"MINGW"* ]]; then
    if ! podman machine list --format "{{.Running}}" 2>/dev/null | grep -q "true"; then
        echo -e "${YELLOW}Warning: No podman machine is running. Attempting to start...${NC}"
        podman machine start || {
            echo -e "${RED}Error: Failed to start podman machine${NC}"
            exit 1
        }
    fi
fi

# Function to run a single test
run_test() {
    local test_name="$1"
    local test_dir="$2"
    local validation_cmd="$3"
    
    echo "----------------------------------------------"
    echo "Test: $test_name"
    echo "----------------------------------------------"
    
    cd "$test_dir"
    
    # Run devcontainer up
    echo "Starting container..."
    OUTPUT=$(devcontainer up --workspace-folder . --docker-path podman 2>&1) || {
        echo -e "${RED}FAILED${NC}: Container failed to start"
        echo "$OUTPUT"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}| ${test_name} | ❌ FAILED | Container failed to start |\n"
        cd "$PROJECT_ROOT"
        return 1
    }
    
    # Extract container ID from JSON output
    CONTAINER_ID=$(echo "$OUTPUT" | grep -o '"containerId":"[^"]*"' | cut -d'"' -f4 | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo -e "${RED}FAILED${NC}: Could not get container ID"
        echo "$OUTPUT"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}| ${test_name} | ❌ FAILED | Could not get container ID |\n"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    echo "Container started: $CONTAINER_ID"
    
    # Run validation if provided
    if [ -n "$validation_cmd" ]; then
        echo "Running validation..."
        # Execute validation command with CONTAINER_ID in scope
        if ! eval "$validation_cmd"; then
            echo -e "${RED}FAILED${NC}: Validation failed"
            podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
            FAILED=$((FAILED + 1))
            RESULTS="${RESULTS}| ${test_name} | ❌ FAILED | Validation failed |\n"
            cd "$PROJECT_ROOT"
            return 1
        fi
    fi
    
    # Cleanup
    echo "Cleaning up..."
    podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
    
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
    RESULTS="${RESULTS}| ${test_name} | ✅ PASSED | |\n"
    
    cd "$PROJECT_ROOT"
    return 0
}

# Run tests (matching GitHub Actions test order)
echo ""
echo "Running tests..."
echo ""

# Test 1: Minimal
run_test "Minimal" "$PROJECT_ROOT/tests/minimal" ""

# Test 2: Dockerfile
run_test "Dockerfile" "$PROJECT_ROOT/tests/dockerfile" \
    'podman exec "$CONTAINER_ID" curl --version > /dev/null 2>&1'

# Test 3: Features (Go)
run_test "Features (Go)" "$PROJECT_ROOT/tests/features-go" \
    'podman exec "$CONTAINER_ID" go version > /dev/null 2>&1'

# Test 4: Docker in Docker (special handling)
echo "----------------------------------------------"
echo "Test: Docker in Docker"
echo "----------------------------------------------"
cd "$PROJECT_ROOT/tests/docker-in-docker"
echo "Starting container..."
OUTPUT=$(devcontainer up --workspace-folder . --docker-path podman 2>&1)
if [ $? -ne 0 ]; then
    echo -e "${RED}FAILED${NC}: Container failed to start"
    echo "$OUTPUT"
    FAILED=$((FAILED + 1))
    RESULTS="${RESULTS}| Docker in Docker | ❌ FAILED | Container failed to start |\n"
    cd "$PROJECT_ROOT"
else
    CONTAINER_ID=$(echo "$OUTPUT" | grep -o '"containerId":"[^"]*"' | cut -d'"' -f4 | head -1)
    if [ -z "$CONTAINER_ID" ]; then
        echo -e "${RED}FAILED${NC}: Could not get container ID"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}| Docker in Docker | ❌ FAILED | Could not get container ID |\n"
        cd "$PROJECT_ROOT"
    else
        echo "Container started: $CONTAINER_ID"
        echo "Waiting for Docker daemon..."
        DOCKER_READY=false
        for i in {1..30}; do
            if podman exec "$CONTAINER_ID" docker info &>/dev/null 2>&1; then
                DOCKER_READY=true
                break
            fi
            sleep 2
        done
        if [ "$DOCKER_READY" = "true" ]; then
            echo "Running docker version..."
            if podman exec "$CONTAINER_ID" docker version > /dev/null 2>&1; then
                echo "Running hello-world..."
                if podman exec "$CONTAINER_ID" docker run --rm hello-world > /dev/null 2>&1; then
                    podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
                    echo -e "${GREEN}PASSED${NC}"
                    PASSED=$((PASSED + 1))
                    RESULTS="${RESULTS}| Docker in Docker | ✅ PASSED | |\n"
                else
                    echo -e "${RED}FAILED${NC}: hello-world failed"
                    podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
                    FAILED=$((FAILED + 1))
                    RESULTS="${RESULTS}| Docker in Docker | ❌ FAILED | hello-world failed |\n"
                fi
            else
                echo -e "${RED}FAILED${NC}: docker version failed"
                podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
                FAILED=$((FAILED + 1))
                RESULTS="${RESULTS}| Docker in Docker | ❌ FAILED | docker version failed |\n"
            fi
        else
            echo -e "${RED}FAILED${NC}: Docker daemon did not start"
            podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
            FAILED=$((FAILED + 1))
            RESULTS="${RESULTS}| Docker in Docker | ❌ FAILED | Docker daemon did not start |\n"
        fi
        cd "$PROJECT_ROOT"
    fi
fi

# Test 5: Sample Python
run_test "Sample Python" "$PROJECT_ROOT/tests/sample-python" \
    'podman exec "$CONTAINER_ID" python3 --version > /dev/null 2>&1'

# Test 6: Sample Node.js
run_test "Sample Node.js" "$PROJECT_ROOT/tests/sample-node" \
    'podman exec "$CONTAINER_ID" node --version > /dev/null 2>&1'

# Test 7: Sample Go
run_test "Sample Go" "$PROJECT_ROOT/tests/sample-go" \
    'podman exec "$CONTAINER_ID" go version > /dev/null 2>&1'

# Summary
echo ""
echo "=============================================="
echo "Test Summary"
echo "=============================================="
echo ""
echo -e "| Test | Result | Notes |"
echo -e "|------|--------|-------|"
echo -e "$RESULTS"
echo ""
echo -e "Total: ${GREEN}$PASSED passed${NC}, ${RED}$FAILED failed${NC}"
echo ""

# Exit with appropriate code
if [ $FAILED -gt 0 ]; then
    exit 1
fi
exit 0
