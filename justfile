# Update external dependencies
update-deps:
    #!/bin/bash
    cd deps/raylib
    LATEST_RAYLIB=$(curl --silent https://api.github.com/repos/raysan5/raylib/commits | jq -r .[0].sha)
    LATEST_RAYGUI=$(curl --silent https://api.github.com/repos/raysan5/raygui/commits | jq -r .[0].sha)
    zig fetch --save=raylib "https://github.com/raysan5/raylib/archive/${LATEST_RAYLIB}.tar.gz"
    zig fetch --save=raygui "https://github.com/raysan5/raygui/archive/${LATEST_RAYGUI}.tar.gz"

# Build Windows release
release-win32:
    zig build --release=fast -Dtarget=x86_64-windows --prefix release/windows
    zip -j release/win32.zip release/windows/bin/*

# Build web version
web-build:
    zig build web -Dtarget=wasm32-emscripten --sysroot "$EMSDK/upstream/emscripten" --verbose --release=fast

# Create flat copy of source files with paths encoded in filenames
flat-copy:
    #!/bin/bash
    rm -rf flat-copy
    mkdir -p flat-copy
    fd . -t f -e "zig" -E "flat-copy" -E "tests" | while read -r file; do
        # Remove leading ./ from path
        clean_path=${file#./}
        # Copy file to flat directory with path encoded in name
        cp "$file" "flat-copy/${clean_path//\//__}"
    done
