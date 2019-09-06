#!/usr/bin/env bash

function build_images() {
    docker build -t "pauly/laravel-study-test:${VERSION}" -f build/laravel-study-test.dockerfile .
    docker rmi $(docker images -q -f dangling=true)
}

if [[ $# -ne 1 ]]; then
    echo "Usage: $(basename $0) <VERSION>"
    echo "       $(basename $0) \"echo 'hello' && <BASH COMMAND>\""
    exit 1
else
    if [ `echo "$@" | cut -c1-4` == 'echo' ]; then
        bash -c "$@";
    else
        VERSION="$1"
        build_images
        exit 0
    fi
fi
