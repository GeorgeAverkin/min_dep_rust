#!/bin/sh
set -e

PROJECT_DIR="$(git rev-parse --show-toplevel)"
RUST_LIB="$HOME/Documents/projects/rust/build/x86_64-unknown-linux-gnu/lib"

clean() {
    if [ -e "$PROJECT_DIR/min_dep_rust.o" ]; then
        rm "$PROJECT_DIR/min_dep_rust.o"
    fi

    if [ -e "$PROJECT_DIR/min_dep_rust" ]; then
        rm "$PROJECT_DIR/min_dep_rust"
    fi

    if [ -d "$PROJECT_DIR/target" ]; then
        rm -r "$PROJECT_DIR/target"
    fi
}

compile() {
    local args=(
        --crate-name=min_dep_rust
        --crate-type=bin
        --out-dir="$PROJECT_DIR"
        -C panic=abort
        --emit obj
        src/main.rs
    )
    RUSTC_LOG=info rustc ${args[@]}
}

find_one() {
    find /usr -type d ! -perm -g+r,u+r,o+r -prune -o -type f -name "$1" -print -quit
    test $(basename "$1") = "$1"
}

link() {
    local collect2=$(find_one 'collect2')
    local scrt1=$(find_one 'Scrt1.o')
    local liblto_plugin=$(find_one 'liblto_plugin.so')
    local crtbegins=$(find_one 'crtbeginS.o')
    local crtends=$(find_one 'crtendS.o')
    
    # echo $scrt1
    # echo $liblto_plugin
    # echo $collect2
    # echo $crtbegins
    # echo $crtends
    local args=(
        -plugin $liblto_plugin
        -plugin-opt=/usr/libexec/gcc/x86_64-redhat-linux/11/lto-wrapper
        -plugin-opt=-fresolution=/tmp/ccyBs6M4.res
        --build-id
        --no-add-needed
        --eh-frame-hdr
        --hash-style=gnu
        -m elf_x86_64
        -dynamic-linker /lib64/ld-linux-x86-64.so.2
        -pie
        -o /home/owl/Documents/projects/min_dep_rust/min_dep_rust
        $scrt1
        /usr/lib64/crti.o
        $crtbegins
        -L/usr/lib/gcc/x86_64-redhat-linux/11
        -L/usr/lib64
        -L/usr/lib
        -lc
        --as-needed
        --eh-frame-hdr
        --gc-sections
        -znoexecstack
        -znow
        -zrelro
        /home/owl/Documents/projects/min_dep_rust/min_dep_rust.o
        $crtends
        /usr/lib64/crtn.o
    )

    $collect2 ${args[@]}
}

clean
compile
link
./min_dep_rust