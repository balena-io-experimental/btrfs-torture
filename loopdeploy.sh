#!/bin/bash
set -e

function print_help() {
    echo "Command line options:"
    echo "-h|--help: this help"
    echo "-d|--device <uuid>: device UUID to torture"
    echo "-r|--remote <remote>: the git remote to push to on resin.io"
}

while [[ $# -gt 1 ]]
do
key="$1"
case $key in
    -h|--help)
        print_help
        exit 0
        ;;
    -d|--device)
        DEVICE="$2"
        shift
        ;;
    -r|--remote)
        REMOTE="$2"
        shift
        ;;
    *)
        echo "Unknown option: $1"
        print_help
        exit 1
        ;;
esac
shift # past argument or value
done

if [ -z "${DEVICE}" ] || [ -z "${REMOTE}" ]; then
    echo "Missing device or remote!"
    print_help
    exit 2
fi

echo "Device: ${DEVICE}"
echo "Remote: ${REMOTE}"
echo "==============================="

PROJECTS=(
    # Debian Go
    https://github.com/resin-io-projects/resin-go-hello-world
    # Fedora
    https://github.com/imrehg/resin-fedora-test
    # Debian
    https://github.com/resin-io-projects/resin-rust-hello-world
    # Alpine
    https://github.com/resin-io-playground/nodejs-multistage-docker
    # Debian
    https://github.com/resin-io-projects/resin-cpp-hello-world
    # Alpine
    https://github.com/imrehg/beast
    # Debian Python
    https://github.com/resin-io-projects/rpi3-bluetooth
    # Alpine Node
    https://github.com/resin-io-playground/piglow-workshop
    # Debian Node
    https://github.com/resin-io-projects/resin-node-red
    # Debian Python
    https://github.com/resin-io-projects/flick-remote
)

while : ; do
    for project in "${PROJECTS[@]}"; do
        echo "$project"
        DIR=$(basename "$project")
        if [ ! -d "$DIR" ]; then
            git clone "$project"
        fi
        cd "$DIR" || exit
        git remote rm debug || true
        git remote add debug "${REMOTE}"
        echo "pushing"
        git push --force debug master
        echo "pushing done"
        OUTPUT="";
        while [ "$(echo "$OUTPUT" | grep -c idle)" = 0 ]; do
            echo "Waiting"
            sleep 60
            OUTPUT=$(resin device "${DEVICE}" | grep STATUS | awk '{ print $2 }')
        done
        cd ..
        echo "Next project!"
        echo
    done
done
