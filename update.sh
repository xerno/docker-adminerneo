#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */ )
fi
versions=( "${versions[@]%/}" )

read -r commit_hash fullVersion << EOF
$(git ls-remote --tags https://github.com/adminerneo/adminerneo.git \
	| awk '{gsub(/refs\/tags\/v/, "", $2); print}' \
	| sort -rVk2 \
	| head -1)
EOF

# Use GNU sed if available (install: brew install gnu-sed), otherwise fallback to sed
if command -v gsed &>/dev/null; then
    SED="gsed"
else
    SED="sed"
fi

echo "Using: $SED"

for version in "${versions[@]}"; do
	if [[ "$fullVersion" != $version* ]]; then
		echo >&2 "error: cannot determine full version for '$version'"
	fi

	echo "$version: $fullVersion"

	downloadSha256="$(
		curl -fsSL "https://github.com/adminerneo/adminerneo/releases/download/v${fullVersion}/adminer-${fullVersion}.php" \
			| sha256sum \
			| cut -d' ' -f1
	)"
	echo "  - adminer-${fullVersion}.php: $downloadSha256"

    $SED -ri \
        -e 's/^(ENV\s+ADMINER_VERSION)=.*/\1='"$fullVersion"'/' \
        -e 's/^(ENV\s+ADMINER_DOWNLOAD_SHA256)=.*/\1='"$downloadSha256"'/' \
        -e 's/^(ENV\s+ADMINER_COMMIT)=.*/\1='"$commit_hash"'/' \
        "$version/fastcgi/Dockerfile" \
        "$version/Dockerfile" || echo "Error modifying files with sed!"

done
