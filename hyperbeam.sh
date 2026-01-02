#!/usr/bin/env bash

set -e

# https://docs.wao.eco/book
# https://hyperbeam.ar.io/run/configuring-your-machine.html

HYPERBEAM_DIR="${HYPERBEAM_DIR:-.hyperbeam}"
HYPERBEAM_TAG="v0.9-milestone-3-beta-3"
HYPERBEAM_REPO="https://github.com/permaweb/HyperBEAM"

apply_makefile_patches() {
    local makefile="$HYPERBEAM_DIR/Makefile"
    
    if [ ! -f "$makefile" ]; then
        echo "Error: Makefile not found at $makefile"
        return 1
    fi
    
    echo "Applying Makefile patches for macOS compatibility..."
    
    # Check if already patched
    if grep -q "perl -i -pe" "$makefile"; then
        echo "Makefile already patched"
        return 0
    fi
    
    # Patch 1: Replace GNU sed with BSD sed + perl for macOS compatibility
    # Original line: sed -i '742a tbl_inst->is_table64 = 1;' ./_build/wamr/core/iwasm/aot/aot_runtime.c; \
    # New lines: 
    #   sed -i '' 's/cmake_minimum_required (VERSION 3.0)/cmake_minimum_required (VERSION 3.5)/' ./_build/wamr/CMakeLists.txt; \
    #   perl -i -pe 'print "    tbl_inst->is_table64 = 1;\n" if $$.==742' ./_build/wamr/core/iwasm/aot/aot_runtime.c; \
    
    sed -i '' \
        "s|sed -i '742a tbl_inst->is_table64 = 1;' ./_build/wamr/core/iwasm/aot/aot_runtime.c; \\\\|sed -i '' 's/cmake_minimum_required (VERSION 3.0)/cmake_minimum_required (VERSION 3.5)/' ./_build/wamr/CMakeLists.txt; \\\\\
	perl -i -pe 'print \"    tbl_inst->is_table64 = 1;\\\\n\" if \$\$.==742' ./_build/wamr/core/iwasm/aot/aot_runtime.c; \\\\|" \
        "$makefile"
    
    echo "Makefile patches applied successfully"
}

install_hyperbeam() {
    echo "Installing HyperBEAM dependencies..."
    
    # https://hyperbeam.ar.io/run/running-a-hyperbeam-node.html
    brew install cmake git pkg-config openssl ncurses
    brew install erlang@27
    brew install rebar3

    if [ ! -e "$HOME/.cargo/env" ]; then
        echo "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
    fi

    # Ensure Rust/cargo is in PATH
    if [ -e "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
    
    # Clone HyperBEAM if not already cloned
    if [ ! -d "$HYPERBEAM_DIR" ]; then
        echo "Cloning HyperBEAM ${HYPERBEAM_TAG}..."
        git clone --branch "$HYPERBEAM_TAG" --depth 1 "$HYPERBEAM_REPO" "$HYPERBEAM_DIR"
        
        # Apply patches after cloning
        apply_makefile_patches
    else
        echo "HyperBEAM directory already exists at $HYPERBEAM_DIR"
    fi

    # Compile if not already compiled
    cd "$HYPERBEAM_DIR"
    if [ ! -d "_build" ]; then
        echo "Compiling HyperBEAM..."
        rebar3 compile
    else
        echo "HyperBEAM already compiled"
    fi
    
    echo "HyperBEAM installation complete!"
}

run_hyperbeam() {

    if [ ! -e "$HOME/.cargo/env" ]; then
        echo "Error: cargo not found at $HOME/.cargo/env"
        echo "Run 'hyperbeam install' first"
        exit 1
    fi

    source "$HOME/.cargo/env"

    if [ ! -d "$HYPERBEAM_DIR" ]; then
        echo "Error: HyperBEAM not found at $HYPERBEAM_DIR"
        echo "Run 'hyperbeam install' first"
        exit 1
    fi

    cd "$HYPERBEAM_DIR"
    echo "Starting HyperBEAM shell..."
    rebar3 shell
}

case "${1:-}" in
    install)
        install_hyperbeam
        ;;
    run)
        run_hyperbeam
        ;;
    *)
        echo "Usage: $0 {install|run}"
        echo ""
        echo "Commands:"
        echo "  install  - Install HyperBEAM dependencies and clone/compile the node"
        echo "  run      - Start the HyperBEAM shell"
        exit 1
        ;;
esac