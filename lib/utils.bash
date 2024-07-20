#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/vectordotdev/vector"
TOOL_NAME="vector"
TOOL_TEST="vector --version"

fail() {
	echo >&2 -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

if [ -n "${GITHUB_API_TOKEN:-}" ]; then
	curl_opts=("${curl_opts[@]}" -H "Authorization: token $GITHUB_API_TOKEN")
fi

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
		sed 's/^v//'
}

list_all_versions() {
	list_github_tags
}

github_api_curl() {
	local gh_opts
	local gh_url="${1}"

	# Prepare options to do GH api requests
	gh_opts=("--location")
	gh_opts+=("--header" "Accept: application/vnd.github+json")
	gh_opts+=("--header" "X-GitHub-Api-Version: 2022-11-28")

	# Make the call
	curl "${curl_opts[@]}" "${gh_opts[@]}" "$gh_url"
}

check_rosetta_installed() {
	if [[ -n "${ASDF_VECTOR_DISABLE_ROSETTA:-}" ]] || \
			! [[ -x /usr/bin/pgrep ]] || \
			! [[ -x /usr/bin/arch ]] || \
			! [[ -x /usr/bin/uname ]]; then
		return 1
	fi

	local platform=$(uname -s | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
	if [[ "$platform" != "darwin" ]]; then
		return 1
	fi

	local oahd_pid=$(/usr/bin/pgrep oahd || true)
	if [[ -z "$oahd_pid" ]]; then
		return 1
	fi

	local arch=$(/usr/bin/arch -x86_64 /usr/bin/uname -m 2>/dev/null || true)
	if [[ "$arch" != "x86_64" ]]; then
		return 1
	fi

	return 0
}

get_compatible_asset() {
	if [[ $# -eq 0 ]]; then
		echo >&2 "usage: get_compatible_asset <version>"
		exit 1
	fi

	local version="${1}"

	# Prepare a grep depending on the current platform
	local platform_grep
	local platform=$(uname -s | tr '[:upper:]' '[:lower:]')
	case "$platform" in
	darwin)
		platform_grep='\b(apple|darwin)\b'
		;;
	linux)
		platform_grep='\b(linux)\b'
		;;
	*)
		echo >&2 "Platform '$platform' not supported"
		exit 1
		;;
	esac

	# Prepare a grep depending on the current architecture
	local arch_grep
	local arch_grep_rosetta=""
	local arch=$(uname -m | tr '[:upper:]' '[:lower:]')
	case "$arch" in
	aarch64 | arm64)
		arch_grep='\b(aarch64|arm64)\b'
		if [[ "$platform" == "darwin" ]] && check_rosetta_installed; then
			arch_grep_rosetta='\b(x64|x86_64|x86-64)\b'
		fi
		;;
	x86_64 | x64 | x86-64)
		arch_grep='\b(x64|x86_64|x86-64)\b'
		;;
	*)
		echo >&2 "Architecture '${arch}' not supported"
		exit 1
		;;
	esac

	# Get the assets from the release version
	set +e
	local release_json
	release_json=$(github_api_curl "https://api.github.com/repos/vectordotdev/vector/releases/tags/v${version}")
	[[ $? == 0 ]] || fail "Unable to get release data from GitHub"
	set -e

	# List the asset names, and filter only the .tar.gz files
	local assets
	assets=$(echo "$release_json" | jq --raw-output '.assets | map(.name) | .[] | select(endswith(".tar.gz"))' || true)
	[[ -n "$assets" ]] || fail "No asset found for release $version"

	# Go over the assets and find the ones that match both the architecture and the platform
	local matching_assets
	matching_assets=$(echo "$assets" | grep -E "$platform_grep" | grep -E "$arch_grep" || true)
	if [[ -z "$matching_assets" ]] && [[ -n "$arch_grep_rosetta" ]]; then
		echo >&2 "No asset found for release $version for $(uname -sm), trying with Rosetta"
		matching_assets=$(echo "$assets" | grep -E "$platform_grep" | grep -E "$arch_grep_rosetta" || true)
	fi
	[[ -n "$matching_assets" ]] || fail "No asset found for release $version for $(uname -sm)"

	# If more than one file, take only the first one
	echo "$matching_assets" | head -n1
}

download_release() {
	local version filename asset url checksums_url checksums_dir
	version="$1"
	filename="$2"
	asset="$3"

	url="$GH_REPO/releases/download/v${version}/${asset}"

	checksums_url="$GH_REPO/releases/download/v${version}/vector-${version}-SHA256SUMS"
	checksums_dir="$(dirname "$filename")"

	# Download the asset
	echo "* Downloading $TOOL_NAME release $version..."
	set +e
	status_code=$(curl "${curl_opts[@]}" -w "%{http_code}" -o "$filename" -C - "$url" 2>/dev/null)
	if [[ $? -ne 0 ]] && [[ "${status_code}" != "416" ]]; then
		fail "Could not download $url: status $status_code"
	fi
	set -e

	# Download the SHA256
	echo "* Verifying checksums..."
	curl "${curl_opts[@]}" -o "${checksums_dir}/all_files.sha256" "$checksums_url" || fail "Could not download checksums"
	cat "${checksums_dir}/all_files.sha256" | grep "${asset}" >"${checksums_dir}/${asset}.sha256"
	[[ -n "$(cat "${checksums_dir}/${asset}.sha256")" ]] || fail "Could not find checksum for asset ${asset}"
	sha256sum=$(command -v sha256sum || echo "shasum --algorithm 256") # from https://github.com/XaF/omni
	(cd "${checksums_dir}/" && sha256sum --check "${asset}.sha256") || fail "Checksum for asset ${asset} failed to match"
	rm -f "${checksums_dir}/"*.sha256
}

install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="$3"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "${ASDF_DOWNLOAD_PATH}"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		test -x "$install_path/bin/$tool_cmd" || fail "Expected $install_path/bin/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error ocurred while installing $TOOL_NAME $version."
	)
}
