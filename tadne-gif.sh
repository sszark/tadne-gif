#!/bin/sh
#   / _ \    author : sszark
# \_\(_)/_/  email  : sszark@protonmail.com
#  _//"\\_   github : https://github.com/sszark/tadne-gif
#   /   \
# download AI generated images from https://thisanimedoesnotexist.ai/ as gifs.

error() {
    echo "[error]: ${@}"
    exit 1
}

dep_check() {
    read deps
    while IFS= read -r dep; do
        which $dep 1> /dev/null 2> /dev/null || error "dependency missing: $dep"
    done <<< "$deps"
}

help() {
cat << EndOfMessage
USAGE:
    tadne-gif <ID>

OPTIONS:
    --all       Generate gifs from all seeds
    --random    Generate gif from a random seed
    --help      Shows help information

EndOfMessage
}

download() {
    # check that seed is within the availible range.
    if (($1 < 0 || $1 > 99999)); then
        echo "Invalid ID '$1', must be between 0-99999"
        return
    fi

    # convert seed to be zero padded. example: '00001' (required by webserver)
    seed=$(printf "%05d" $1)

    # create temporary directory for seed frames
    mkdir $seed

    # download all frames from seed
    for psi in $(seq 0.3 .1 2.0)
    do
        curl \
        https://thisanimedoesnotexist.ai/results/psi-$psi/seed$seed.png \
        1> /dev/null 2> /dev/null > $seed/$psi.png \
        || error "Failed to download frame $psi for $seed" \
            /
    done

    # create gif from frames
    convert -delay 10 -loop 0 ./$seed/*.png $seed.gif \
    || error "Failed to generate gif" \
        /

    # remove frames after building gif
    rm -r $seed

    echo "$PWD/$seed.gif"
}

archive() {
    # download all the seeds
    for i in $(seq -f "%05g" 1 99999)
    do
        download $i
    done
}

# check dependencies (coreutils is assumed to be installed)
dep_check << EndOfMessage
convert
curl
EndOfMessage

case "$1" in
    "--help"|"")
        help
        ;;
    "--all")
        archive
        ;;
    "--random")
        download $(shuf -i 0-99999 -n 1)
        ;;
    *)
        download $1
esac
