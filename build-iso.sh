#!/bin/sh

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------

die() {
    printf '%s\n' "$@" >&2
    exit 1
}

check_substitute_server() {
    url="$1"
    echo -n "checking: " $url >&2
    if curl --silent --head --fail --max-time 10 "${url}" > /dev/null 2>&1; then
        echo " - Available" >&2
        return 0
    fi
    echo " - Unavailable" >&2
    return 1
}

get_available_substitutes() {
    primary_urls=''
    fallback_urls='https://hydra-guix-129.guix.gnu.org https://bordeaux-singapore-mirror.cbaines.net'
    nonguix_url='https://substitutes.nonguix.org'
    available=''
    primary_count=0
    for url in $primary_urls; do
        if check_substitute_server "$url"; then
            available="${available:+$available }$url"
            primary_count=$((primary_count + 1))
        fi
    done
    if [ "$primary_count" -lt 2 ]; then
        echo "Adding fallback servers for redundancy..." >&2
        for url in $fallback_urls; do
            if check_substitute_server "$url"; then
                available="${available:+$available }$url"
            fi
        done
    fi
    if check_substitute_server "$nonguix_url"; then
        available="${available:+$available }$nonguix_url"
    fi
    echo "$available"
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

if [ "$GUIX_NO_SUBSTITUTES" = "true" ]; then
    printf 'Building from source (substitutes disabled).\n'
    substitute_urls=""
else
    substitute_urls=$(get_available_substitutes)
    if [ -z "$substitute_urls" ]; then
        printf 'Warning: No substitute servers available. Building from source.\n'
    fi
fi

# Build the image
printf 'Attempting to build the image...\n\n'

if [ -n "$substitute_urls" ]; then
    image=$(guix time-machine -C './guix/channels.scm' \
              --substitute-urls="$substitute_urls"     \
              -- system image                          \
                 --image-size=16GiB                    \
                 --image-type=iso9660                  \
                 './guix/installer.scm'                \
    ) || die 'Could not create image.'
else
    image=$(guix time-machine -C './guix/channels.scm' \
              --no-substitutes                         \
              -- system image                          \
                 --image-size=16GiB                    \
                 --image-type=iso9660                  \
                 './guix/installer.scm'                \
    ) || die 'Could not create image.'
fi

release_tag=$(date +"%Y%m%d%H%M")
cp "${image}" "./guix-installer-${release_tag}.iso" ||
    die 'An error occurred while copying.'

printf 'Image was succesfully built: %s\n' "${image}"

# Export for GitHub Actions CI
if [ -n "$GITHUB_ENV" ]; then
    echo "RELEASE_TAG=${release_tag}" >> "$GITHUB_ENV"
fi

# cleanup
unset -f die check_substitute_server get_available_substitutes
unset -v image release_tag substitute_urls
