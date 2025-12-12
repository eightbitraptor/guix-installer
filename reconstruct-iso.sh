#!/bin/bash
set -e

RELEASE_TAG="${1:-}"

ISO_FILE="guix-installer-${RELEASE_TAG}.iso.xz"
BASE_URL="https://github.com/eightbitraptor/guix-installer/releases/download/v${RELEASE_TAG}"

echo "Downloading checksums..."
curl -fSL --progress-bar -o "${ISO_FILE}.sha256" "${BASE_URL}/${ISO_FILE}.sha256"
curl -fSL --progress-bar -o "${ISO_FILE}.parts.sha256" "${BASE_URL}/${ISO_FILE}.parts.sha256"

echo "Downloading parts..."
while read -r _ part; do
  curl -fSL --progress-bar -o "$part" "${BASE_URL}/${part}"
done < "${ISO_FILE}.parts.sha256"

echo "Verifying parts..."
sha256sum -c "${ISO_FILE}.parts.sha256"

echo "Reconstructing ${ISO_FILE}..."
cat ${ISO_FILE}.part.* > "$ISO_FILE"

echo "Verifying final checksum..."
sha256sum -c "${ISO_FILE}.sha256"

rm -f ${ISO_FILE}.part.* "${ISO_FILE}.sha256" "${ISO_FILE}.parts.sha256"
echo "Done: ${ISO_FILE}"
