#!/usr/bin/env bash


wallpaper_dir="./dynamic"
manifest="./manifest.json"

should_build=true
should_prune=false

usage() {
cat <<EOU

Description: 

This script  ensures an up-to-date manifest that contains the 
names of all current dynamic wallpapers. This manifest exists to
maintain the tags (xattrs) for each wallpaper, in order to allow 
correct themeing by the wall-tools script in my nixos configuration.
The script can also prune entries from the manifest in the case 
that wallpapers have been removed from the target directory.

Requires jq

Usage: 
    ./manifest-builder.sh | -d <directory> | -p | -h

    -d: sets wallpaper directory (defaults to ./dynamic)
    -p: prune entries from manifest that are not present in wallpaper directory (defaults to false)
    -h: display this help and exit

EOU
}


while getopts "d:hp" opt; do

    case $opt in 
        d)
            wallpaper_dir=${OPTARG}
            ;;
        p)
            should_prune=true
            ;;
        h)
            usage
            ;;
        \?)
			usage
			exit 1
			;;
    esac
done



build_manifest() {
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
    echo "Done"
    echo

}

prune_manifest() {
    echo "Pruning entries from $manifest that no longer exist in $wallpaper_dir ..."
    manifest_keys=$(jq -r "keys[]" $manifest)
    wallpapers_current=$(ls "$wallpaper_dir" | xargs -I {} basename "{}" .mp4 )

    for i in $manifest_keys; do
        if [[ ! "$wallpapers_current" =~ "$i" ]]; then
            echo "Pruning: $i from manifest"
            jq --arg key "$i" 'del(.[$key])' $manifest > $manifest-tmp.json && \
                mv $manifest-tmp.json $manifest
        fi  

    done
    echo "Done"
    echo
}

main() {

    if ! which jq > /dev/null 2>&1; then
        echo
        echo "jq not found"
        echo "install jq, or run with nix-shell -p jq"
        echo "Exiting"; exit 1;
    fi

    if [[ $should_build == true ]]; then
        build_manifest
    fi 

    if [[ $should_prune == true ]]; then
        prune_manifest
    fi

    
    echo "Completed: manifest-builder.sh"
}

main
