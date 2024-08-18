#!/usr/bin/env bash

# Requires jq

# The purpose of this script is to ensure an up-to-date manifest
# that contains the names of all current dynamic wallpapers, and
# a list of tags for each, in order to allow correct themeing by
# the wall-tools script in nixos

# TO-DO: Implement prune option, to remove entries that are no 
# longer present in the wallpaper directory


wallpaper_dir="./dynamic"
manifest="./manifest.json"
should_prune=false

while getopts "d:p" opt; do

    case $opt in 
        d)
            wallpaper_dir=${OPTARG}
            ;;
        p)
            should_prune=true
            ;;
    esac
done


main() {

    if ! which jq > /dev/null 2>&1; then
        echo
        echo "jq not found"
        echo "install jq, or run with nix-shell -p jq"
        echo "Exiting"; exit 1;
    fi

    echo "Ensuring manifest contains all wallpapers in $wallpaper_dir ..."
    manifest_current=$(jq -r "keys[]" ./manifest.json)

    for i in "$wallpaper_dir"/*.mp4; do
        wallpaper=$(basename "$i" .mp4)
        if [[ ! "$manifest_current" =~ $wallpaper ]]; then
            echo "Did not find $wallpaper in manifest"
            echo "Adding $wallpaper to manifest"
            jq --arg wallpaper "$wallpaper" '. += {($wallpaper): []} | to_entries | sort_by(.key) | from_entries' \
                $manifest > $manifest-tmp.json && mv $manifest-tmp.json $manifest

        fi
    done

    echo "Completed: manifest-builder.sh"
}

main
