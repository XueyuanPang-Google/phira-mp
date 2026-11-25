#!/usr/bin/env bash
# Build a .deb for phira-mp-server from an already-compiled static binary.
# usage: make-deb.sh <binary> <version> <outdir>
set -euo pipefail

BIN_PATH="${1:?binary path required}"
VERSION="${2:?version required}"
OUT_DIR="${3:-dist}"
ARCH="amd64"
PKG="phira-mp"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STAGE="$(mktemp -d)"
trap 'rm -rf "$STAGE"' EXIT

install -Dm0755 "$BIN_PATH"                                "$STAGE/usr/bin/phira-mp-server"
install -Dm0644 "$ROOT_DIR/systemd/phira-mp.service"       "$STAGE/lib/systemd/system/phira-mp.service"
install -Dm0755 "$ROOT_DIR/systemd/phira-mp.postinst"      "$STAGE/DEBIAN/postinst"
install -Dm0755 "$ROOT_DIR/systemd/phira-mp.prerm"         "$STAGE/DEBIAN/prerm"
install -Dm0755 "$ROOT_DIR/systemd/phira-mp.postrm"        "$STAGE/DEBIAN/postrm"

mkdir -p "$STAGE/DEBIAN"
cat > "$STAGE/DEBIAN/control" <<EOF
Package: ${PKG}
Version: ${VERSION}
Section: net
Priority: optional
Architecture: ${ARCH}
Maintainer: XueyuanPang-Google <xueyuanpang@users.noreply.github.com>
Homepage: https://github.com/TeamFlos/phira-mp
Description: Phira multiplayer server
 Rust implementation of the Phira multiplayer server (phira-mp).
 Listens on TCP port 32346 and speaks the Phira multiplayer protocol.
EOF

mkdir -p "$OUT_DIR"
dpkg-deb --build --root-owner-group "$STAGE" "$OUT_DIR/${PKG}_${VERSION}_${ARCH}.deb"
dpkg-deb --info "$OUT_DIR/${PKG}_${VERSION}_${ARCH}.deb"
