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
echo "  - @devcontainers/cli: $(npx @devcontainers/cli --version 2>/dev/null || echo 'not installed')"
echo "  - Node.js: $(node --version 2>/dev/null || echo 'not installed')"
echo ""

# Check if podman is available
if ! command -v podman &> /dev/null; then
    echo -e "${RED}Error: podman is not installed${NC}"
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
    local extra_validation="$3"
    
    echo "----------------------------------------------"
    echo "Test: $test_name"
    echo "----------------------------------------------"
    
    cd "$test_dir"
    
    # Run devcontainer up
    echo "Starting container..."
    OUTPUT=$(npx @devcontainers/cli up \
        --workspace-folder . \
        --docker-path podman \
        2>&1) || {
        echo -e "${RED}FAILED${NC}: Container failed to start"
        echo "$OUTPUT"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}| ${test_name} | ❌ FAILED | Container failed to start |\n"
        return 1
    }
    
    # Extract container ID from JSON output
    CONTAINER_ID=$(echo "$OUTPUT" | grep -o '"containerId":"[^"]*"' | cut -d'"' -f4 | head -1)
    
    if [ -z "$CONTAINER_ID" ]; then
        echo -e "${RED}FAILED${NC}: Could not get container ID"
        FAILED=$((FAILED + 1))
        RESULTS="${RESULTS}| ${test_name} | ❌ FAILED | Could not get container ID |\n"
        return 1
    fi
    
    echo "Container started: $CONTAINER_ID"
    
    # Run extra validation if provided
    if [ -n "$extra_validation" ]; then
        echo "Running validation: $extra_validation"
        if ! eval "$extra_validation"; then
            echo -e "${RED}FAILED${NC}: Validation failed"
            podman rm -f "$CONTAINER_ID" > /dev/null 2>&1 || true
            FAILED=$((FAILED + 1))
            RESULTS="${RESULTS}| ${test_name} | ❌ FAILED | Validation failed |\n"
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

# Run tests
echo ""
echo "Running tests..."
echo ""

# Test 1: Minimal
run_test "Minimal (image only)" "$PROJECT_ROOT/tests/minimal" ""

# Test 2: Dockerfile
run_test "Dockerfile build" "$PROJECT_ROOT/tests/dockerfile" \
    "podman exec $CONTAINER_ID curl --version > /dev/null 2>&1"

# Test 3: Features (Go)
run_test "Features (Go)" "$PROJECT_ROOT/tests/features-go" \
    "podman exec $CONTAINER_ID go version > /dev/null 2>&1"

# Test 4: Docker in Docker
run_test "Docker in Docker" "$PROJECT_ROOT/tests/docker-in-docker" \
    "podman exec $CONTAINER_ID docker run --rm hello-world > /dev/null 2>&1"

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

