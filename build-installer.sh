#!/usr/bin/env bash
# build-installer.sh
set -e

OUTPUT="dist/zaanet-install.sh"

echo "Building single-file ZaaNet installer..."
mkdir -p dist
cat > "$OUTPUT" << 'EOF'
#!/usr/bin/env bash
set -e
# ============================================================
#  ZaaNet Captive Portal Auto-Installer (Bundled)
#  Generated build — Do not edit manually.
# ============================================================

EOF

# Add the main installer first
cat install.sh >> "$OUTPUT"

# Inline all function files
echo "" >> "$OUTPUT"
echo "# --- Included Functions ---" >> "$OUTPUT"
for f in functions/*.sh; do
  echo "" >> "$OUTPUT"
  echo "# >>> Including $f <<<" >> "$OUTPUT"
  cat "$f" >> "$OUTPUT"
done

chmod +x "$OUTPUT"
echo "Combined installer created at: $OUTPUT"
