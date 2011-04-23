#!/usr/bin/env bash

# Most actions performed by heru require elevated privileges.
if test `whoami` != "root"; then
  echo "You need to be root"; exit 1
fi

# We put everything into ~/.heru, the runtime goes into ~/.heru/runtime.
RUNTIME="$HOME/.heru/runtime" && mkdir -p "$RUNTIME"

# Download a tarball with the latest source and unpack it.
BOOTSTRAP="https://github.com/downloads/wereHamster/heru/bootstrap.tar.gz"
curl -sL "$BOOTSTRAP" | tar -xzf - -C "$RUNTIME"

# Linux does not appear to set TMPDIR, fall back to /tmp.
TMPDIR="${TMPDIR:-/tmp}" && cd "$TMPDIR"

# A Node.js version which is compatible with heru.
NODE="node-v0.4.6"

# Build Node.js and put it into the runtime bin/ folder.
curl -sL "http://nodejs.org/dist/$NODE.tar.gz" | tar -xzf -
cd "$NODE" && ./configure --without-ssl && make && cp node "$RUNTIME/bin"

# Now we are done!
echo ""
echo "Heru runtime installed into $RUNTIME. Please add $RUNTIME/bin to your PATH."
echo ""

