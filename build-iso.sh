#!/bin/sh

die() {
    printf '%s\n' "$@" >&2
    exit 1
}

if [ "$GUIX_NO_SUBSTITUTES" = "true" ]; then
    printf 'Building from source (substitutes disabled).\n'
    substitute_urls=""
elif [ -n "$GUIX_SUBSTITUTE_URLS" ]; then
    printf 'Using substitute servers from environment: %s\n' "$GUIX_SUBSTITUTE_URLS"
    substitute_urls="$GUIX_SUBSTITUTE_URLS"
else
    printf 'Warning: GUIX_SUBSTITUTE_URLS not set. Building from source.\n'
    substitute_urls=""
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
unset -f die
unset -v image release_tag substitute_urls
