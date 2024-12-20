#!/bin/bash

## Array to string conversion with given separator
join_list_items_by() {
    local d=${1-} f=${2-}
    if shift 2; then
        printf %s "$f" "${@/#/$d}"
    fi
}

## Normalize build related environment variables
normalize_build_env() {
    local path_parts=$(echo $LD_LIBRARY_PATH | tr ":" "\n" | sort | uniq)
    path_parts=$(join_list_items_by ':' ${path_parts[@]})
    export LD_LIBRARY_PATH="$path_parts"

    path_parts=$(echo $PKG_CONFIG_PATH | tr ":" "\n" | sort | uniq)
    path_parts=$(join_list_items_by ':' ${path_parts[@]})
    export PKG_CONFIG_PATH="$path_parts"

    path_parts=$(echo $CPATH | tr ":" "\n" | sort | uniq)
    path_parts=$(join_list_items_by ':' ${path_parts[@]})
    export CPATH="$path_parts"

    path_parts=$(echo $PATH | tr ":" "\n" | sort | uniq)
    path_parts=$(join_list_items_by ':' ${path_parts[@]})
    path_parts="$(echo $path_parts | sed -e 's|^/bin:||')"
    export PATH="${path_parts}:/bin"

    unset path_parts
}

# Function to print messages
echo_info() {
    echo -e "\e[34m[INFO]\e[0m $1"
}

echo_error() {
    echo -e "\e[31m[ERROR]\e[0m $1"
}

is_url_valid() {
    local url=$1

    curl -Is --max-time 10 "$url" | head -n 1 | grep -q "200\|301\|302\|307"
    return $?
}

zip_pkgbase() {
    filename=$1

    # Extract the root directory name from the zip file
    local pkgbase=$(unzip -Z1 "${filename}" | head -1 | awk -F "/" {'print $1'})
    echo "$pkgbase"
}

tar_gz_pkgbase() {
    filename=$1

    # Extract the root directory name from the tar file
    local pkgbase=$(tar -ztf "${filename}" | head -1 | awk -F "/" {'print $1'})
    echo "$pkgbase"
}

tar_pkgbase() {
    filename=$1

    # Extract the root directory name from the tar file
    local pkgbase=$(tar -tf "${filename}" | head -1 | awk -F "/" {'print $1'})
    echo "$pkgbase"
}
