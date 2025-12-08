#!/usr/bin/env bash

set -euo pipefail

# Main bootstrap script
# Detects OS and calls the appropriate OS-specific bootstrap script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            echo "linux"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Main execution
main() {
    local os_type
    os_type=$(detect_os)

    case "$os_type" in
        macos)
            echo "Detected macOS. Running macOS bootstrap..."
            exec "$SCRIPT_DIR/bootstrap-macos.sh" "$@"
            ;;
        linux)
            echo "Detected Linux. Running Linux bootstrap..."
            exec "$SCRIPT_DIR/bootstrap-linux.sh" "$@"
            ;;
        *)
            echo "Error: Unsupported operating system: $(uname -s)"
            echo "Please run the appropriate bootstrap script manually:"
            echo "  - macOS: ./bootstrap-macos.sh"
            echo "  - Linux: ./bootstrap-linux.sh"
            exit 1
            ;;
    esac
}

main "$@"
