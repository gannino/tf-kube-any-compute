#!/bin/sh
set -e

echo "=== Node-RED Palette Installer ==="
echo "Installing ${length(palette_packages)} packages: ${join(", ", palette_packages)}"
echo "This may take 10-20 minutes on ARM64 devices..."
echo ""

# Configure npm for reliability
npm config set progress true
npm config set loglevel info

# Install packages one by one with progress
TOTAL=${length(palette_packages)}
CURRENT=0

%{ for package in palette_packages ~}
CURRENT=$((CURRENT + 1))
echo "[$CURRENT/$TOTAL] Checking ${package}..."

# Determine if this is a git/https package or npm registry package
if echo "${package}" | grep -E '^(https?://|git\+|.*\.git$)' >/dev/null; then
  # Git/HTTPS package - extract name for checking
  PKG_NAME=$(echo "${package}" | sed 's|.*/||' | sed 's|\.git$||' | sed 's|#.*||')
  echo "Git/HTTPS package detected: ${package} -> $PKG_NAME"

  if [ -d "node_modules/$PKG_NAME" ]; then
    echo "✓ $PKG_NAME already installed from git, reinstalling to get updates..."
  else
    echo "Installing git package ${package}..."
  fi

  echo "Started at: $(date)"
  npm install --no-audit --no-fund "${package}" && {
    echo "✓ Successfully installed ${package}"
  } || {
    echo "✗ Failed to install ${package}"
  }
  echo "Completed at: $(date)"
else
  # Regular npm package
  if npm list "${package}" >/dev/null 2>&1; then
    echo "✓ ${package} already installed, checking for updates..."
    npm update --no-audit --no-fund "${package}" && {
      echo "✓ ${package} updated successfully"
    } || {
      echo "→ ${package} is up to date"
    }
  else
    echo "Installing ${package}..."
    echo "Started at: $(date)"

    npm install --no-audit --no-fund "${package}" && {
      echo "✓ Successfully installed ${package}"
    } || {
      echo "✗ Failed to install ${package}"
    }

    echo "Completed at: $(date)"
  fi
fi
echo ""
%{ endfor ~}

echo "=== Installation Summary ==="
echo "Completed at: $(date)"
echo "Installed packages:"
ls -la node_modules/ | grep node-red || echo "No node-red packages found"
echo "=== End of Installation ==="
