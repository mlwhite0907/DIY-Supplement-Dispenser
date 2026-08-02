#!/usr/bin/env bash
# Export Phase 1 OpenSCAD sources to STL.
# Usage: from repo root or 3d_models/:  ./scripts/export_stls.sh
# Requires OpenSCAD CLI (openscad) or macOS OpenSCAD.app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SCAD_DIR="${ROOT}/openscad"
STL_DIR="${ROOT}/stl"

mkdir -p "${STL_DIR}"

# Resolve OpenSCAD binary
OPENSCAD=""
if command -v openscad >/dev/null 2>&1; then
  OPENSCAD="openscad"
elif command -v OpenSCAD >/dev/null 2>&1; then
  OPENSCAD="OpenSCAD"
elif [[ -x "/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD" ]]; then
  OPENSCAD="/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD"
elif [[ -x "/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD" ]]; then
  OPENSCAD="/Applications/OpenSCAD-2021.01.app/Contents/MacOS/OpenSCAD"
fi

if [[ -z "${OPENSCAD}" ]]; then
  cat <<EOF
ERROR: OpenSCAD CLI not found.

Install options:
  • macOS: brew install --cask openscad
  • Download: https://openscad.org/downloads.html
  • Linux:  sudo apt install openscad   (or distro equivalent)

Then re-run:  ${SCRIPT_DIR}/export_stls.sh

Manual export: open each .scad in the GUI → F6 → File → Export as STL → stl/
EOF
  exit 1
fi

echo "Using: ${OPENSCAD}"
echo "Sources: ${SCAD_DIR}"
echo "Output:  ${STL_DIR}"
echo

PARTS=(
  powder_hopper_v01
  auger_screw_v01
  auger_housing_v01
  test_stand_v01
  scale_platform_v01
  hopper_lid_v01
  loadcell_fixed_base_v01
)

FAILED=0
for part in "${PARTS[@]}"; do
  src="${SCAD_DIR}/${part}.scad"
  dst="${STL_DIR}/${part}.stl"
  if [[ ! -f "${src}" ]]; then
    echo "SKIP (missing source): ${src}"
    FAILED=1
    continue
  fi
  echo "Rendering ${part} ..."
  if "${OPENSCAD}" -o "${dst}" "${src}"; then
    # Basic sanity: non-empty STL
    if [[ -s "${dst}" ]]; then
      size=$(wc -c <"${dst}" | tr -d ' ')
      echo "  OK  → ${dst}  (${size} bytes)"
    else
      echo "  FAIL empty STL: ${dst}"
      FAILED=1
    fi
  else
    echo "  FAIL openscad exit on ${part}"
    FAILED=1
  fi
done

echo
if [[ "${FAILED}" -ne 0 ]]; then
  echo "Completed with errors."
  exit 1
fi
echo "All STLs written to ${STL_DIR}"
ls -la "${STL_DIR}"
