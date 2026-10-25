# --------------------------------------------------
set -euxo pipefail

if [ -d "deps" ]; then
  sudo rm -r deps
fi
if [ -d "prefix" ]; then
  sudo rm -r prefix
fi

. ./include/depinfo.sh

# Artifact version is v<engine-version>+<build-number>; see README (Versioning).
# The engine part must match depinfo.sh (the version actually built); the build
# number comes from the release tag passed as VERSION (CI), 0 for local builds.
version="${VERSION:-}"
if [ -n "$version" ]; then
  [ "${version%%+*}" = "v$v_mpv" ] || { echo "ERROR: VERSION=$version does not match depinfo v_mpv=$v_mpv" >&2; exit 1; }
else
  version="v$v_mpv+0"
fi

./download.sh
./patch.sh

# --------------------------------------------------

if [ -f "scripts/ffmpeg" ]; then
  rm scripts/ffmpeg.sh
fi
cp flavors/full.sh scripts/ffmpeg.sh

# --------------------------------------------------

./build.sh

zip -r "libmpv-symbols_${version}_full.zip" prefix/*/lib

./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/arm64-v8a/usr/local/lib/libmpv.so
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/armeabi-v7a/usr/local/lib/libmpv.so
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/x86/usr/local/lib/libmpv.so
./sdk/android-sdk-linux/ndk/$v_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip --strip-all prefix/x86_64/usr/local/lib/libmpv.so

# --------------------------------------------------

mkdir -p artifacts/full
for abi in arm64-v8a armeabi-v7a x86 x86_64; do
	mkdir -p "artifacts/full/lib/$abi"
	cp "prefix/$abi/usr/local/lib/libmpv.so" "artifacts/full/lib/$abi/"
	(cd artifacts/full && zip -r "libmpv_${version}_android-$abi-full.jar" "lib/$abi")
done
rm -r artifacts/full/lib

(cd artifacts/full && md5sum libmpv_*.jar > md5.txt)
