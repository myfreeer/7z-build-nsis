#!/usr/bin/env bash

set -euo pipefail

project_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
cd "$project_root"

if [[ $(uname -s) != Linux ]]; then
  echo "error: this build script targets Linux; use 7-zip-build.bat on Windows" >&2
  exit 1
fi

sevenzip_version=${SEVENZIP_VERSION:-7z2604}
build_root=${BUILD_DIR:-$project_root/build/$sevenzip_version-linux}
dist_root=${DIST_DIR:-$project_root/dist}
source_dir=${SEVENZIP_SOURCE_DIR:-$build_root/source}
source_archive="$build_root/$sevenzip_version-src.7z"
source_url=${SEVENZIP_SOURCE_URL:-https://www.7-zip.org/a/$sevenzip_version-src.7z}

for tool in make tar install; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: required tool not found: $tool" >&2
    exit 1
  fi
done
for compiler in "${CC:-cc}" "${CXX:-c++}"; do
  if ! command -v "${compiler%% *}" >/dev/null 2>&1; then
    echo "error: required compiler not found: ${compiler%% *}" >&2
    exit 1
  fi
done

if [[ -z ${JOBS:-} ]]; then
  JOBS=$(getconf _NPROCESSORS_ONLN 2>/dev/null || printf '1')
fi
if [[ ! $JOBS =~ ^[1-9][0-9]*$ ]]; then
  echo "error: JOBS must be a positive integer" >&2
  exit 1
fi

download_file() {
  local url=$1
  local destination=$2
  local temporary="$destination.part"

  if command -v curl >/dev/null 2>&1; then
    curl --fail --location --retry 3 --output "$temporary" "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget --output-document="$temporary" "$url"
  else
    echo "error: curl or wget is required to download 7-Zip" >&2
    exit 1
  fi
  mv -f "$temporary" "$destination"
}

extract_source() {
  local extractor

  if command -v 7zz >/dev/null 2>&1; then
    extractor=7zz
  elif command -v 7z >/dev/null 2>&1; then
    extractor=7z
  else
    echo "error: 7zz or 7z is required to extract the 7-Zip source archive" >&2
    exit 1
  fi

  mkdir -p "$source_dir"
  "$extractor" x -bd -y "-o$source_dir" "$source_archive"
}

if [[ -z ${SEVENZIP_SOURCE_DIR:-} ]]; then
  mkdir -p "$build_root"
  if [[ ! -f $source_archive ]]; then
    echo "Downloading $source_url"
    download_file "$source_url" "$source_archive"
  fi
  if [[ ! -f $source_dir/CPP/7zip/Bundles/Alone2/makefile.gcc ]]; then
    echo "Extracting $source_archive"
    extract_source
  fi
fi

bundle_dir="$source_dir/CPP/7zip/Bundles/Alone2"
if [[ ! -f $bundle_dir/makefile.gcc ]]; then
  echo "error: invalid 7-Zip source tree: $source_dir" >&2
  exit 1
fi

sh "$project_root/7-zip-patch-nsis.sh" "$source_dir"

echo "Building 7zz with $JOBS parallel job(s)"
# Recent GCC versions report false-positive array-bounds diagnostics in the
# upstream source. Keep the useful warnings but do not promote them to errors.
make -C "$bundle_dir" -f makefile.gcc -j "$JOBS" \
  CFLAGS_WARN_WALL='-Wall -Wextra'

binary="$bundle_dir/_o/7zz"
if [[ ! -x $binary ]]; then
  echo "error: build completed without producing $binary" >&2
  exit 1
fi

architecture=$(uname -m | tr -c 'A-Za-z0-9._-' '_')
architecture=${architecture%_}
artifact_name="$sevenzip_version-linux-$architecture"
artifact_dir="$dist_root/$artifact_name"

mkdir -p "$artifact_dir"
install -m 0755 "$binary" "$artifact_dir/7zz"
install -m 0755 "$binary" "$dist_root/7zz"
install -m 0644 "$source_dir/DOC/License.txt" "$artifact_dir/License.txt"
install -m 0644 "$source_dir/DOC/readme.txt" "$artifact_dir/readme.txt"
tar -czf "$dist_root/$artifact_name.tar.gz" -C "$dist_root" "$artifact_name"

echo "Linux build ready: $artifact_dir/7zz"
echo "Convenience binary: $dist_root/7zz"
echo "Package ready: $dist_root/$artifact_name.tar.gz"
