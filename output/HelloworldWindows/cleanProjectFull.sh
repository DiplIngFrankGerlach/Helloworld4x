#!/usr/bin/env bash
#
# clean_vs_project.sh
#
# Cleans build artifacts from a Visual Studio C++ project/solution tree.
# Designed to run under Cygwin bash.
#
# Removes:
#   - Build output dirs:  Debug/ Release/ x64/ Win32/ ARM/ ARM64/ (and any
#     Configuration|Platform combo dirs) at any depth
#   - .vs/ hidden cache folder (solution-level IntelliSense + settings)
#   - ipch/ (IntelliSense precompiled header cache)
#   - Object/intermediate files: *.obj *.ilk *.pdb *.idb *.exp *.iobj *.ipdb
#                                 *.tlog *.lastbuildstate *.log *.res *.aps
#   - Precompiled headers: *.pch
#   - User-specific / cache files: *.suo *.user *.sdf *.opendb *.VC.db *.VC.VC.opendb
#
# Leaves alone:
#   - Source: *.cpp *.h *.hpp *.c *.cc
#   - Project/solution files: *.vcxproj *.vcxproj.filters *.sln
#   - Anything under a "packages" (NuGet) folder unless -p is given
#
# Usage:
#   ./clean_vs_project.sh [-n] [-y] [-p] [PATH]
#
#   -n        Dry run — show what would be deleted, delete nothing.
#   -y        Don't ask for confirmation before deleting.
#   -p        Also remove the NuGet "packages" folder.
#   PATH      Root of the project/solution to clean (default: current directory).
#
# Examples:
#   ./clean_vs_project.sh -n                 # preview cleanup of cwd
#   ./clean_vs_project.sh -y /cygdrive/c/src/MyApp
#   ./clean_vs_project.sh -y -p .            # also nuke NuGet packages

set -euo pipefail

DRY_RUN=0
ASSUME_YES=0
CLEAN_PACKAGES=0
TARGET="."

usage() {
    grep '^#' "$0" | sed -e '1d' -e 's/^# \{0,1\}//'
    exit 1
}

while getopts ":nyph" opt; do
    case "$opt" in
        n) DRY_RUN=1 ;;
        y) ASSUME_YES=1 ;;
        p) CLEAN_PACKAGES=1 ;;
        h) usage ;;
        \?) echo "Unknown option: -$OPTARG" >&2; usage ;;
    esac
done
shift $((OPTIND - 1))

if [ $# -ge 1 ]; then
    TARGET="$1"
fi

if [ ! -d "$TARGET" ]; then
    echo "Error: '$TARGET' is not a directory." >&2
    exit 1
fi

TARGET="$(cd "$TARGET" && pwd)"
echo "Project root: $TARGET"

# Directory names to remove wholesale (any depth).
DIR_PATTERNS=(
    "Debug" "Release" "x64" "Win32" "ARM" "ARM64"
    "Debug-*" "Release-*"     # e.g. custom configs like "Release-Static"
    ".vs" "ipch"
)

# File glob patterns to remove (any depth).
FILE_PATTERNS=(
    "*.obj" "*.ilk" "*.pdb" "*.idb" "*.exp" "*.iobj" "*.ipdb"
    "*.tlog" "*.lastbuildstate" "*.log" "*.res" "*.aps" "*.pch"
    "*.suo" "*.user" "*.sdf" "*.opendb" "*.VC.db" "*.VC.VC.opendb"
)

if [ "$CLEAN_PACKAGES" -eq 1 ]; then
    DIR_PATTERNS+=("packages")
fi

echo
if [ "$DRY_RUN" -eq 1 ]; then
    echo "*** DRY RUN — nothing will be deleted ***"
else
    echo "*** LIVE RUN — matching files/folders WILL be deleted ***"
fi
echo

# --- Collect directories to remove -----------------------------------------
DIR_FIND_ARGS=()
for i in "${!DIR_PATTERNS[@]}"; do
    if [ "$i" -gt 0 ]; then
        DIR_FIND_ARGS+=(-o)
    fi
    DIR_FIND_ARGS+=(-iname "${DIR_PATTERNS[$i]}")
done

mapfile -t DIRS_TO_DELETE < <(
    find "$TARGET" -type d \( "${DIR_FIND_ARGS[@]}" \) -prune -print
)

# --- Collect files to remove (skip anything already inside a doomed dir) ---
FILE_FIND_ARGS=()
for i in "${!FILE_PATTERNS[@]}"; do
    if [ "$i" -gt 0 ]; then
        FILE_FIND_ARGS+=(-o)
    fi
    FILE_FIND_ARGS+=(-iname "${FILE_PATTERNS[$i]}")
done

mapfile -t FILES_TO_DELETE < <(
    find "$TARGET" -type f \( "${FILE_FIND_ARGS[@]}" \) -print
)

TOTAL_DIRS=${#DIRS_TO_DELETE[@]}
TOTAL_FILES=${#FILES_TO_DELETE[@]}

if [ "$TOTAL_DIRS" -eq 0 ] && [ "$TOTAL_FILES" -eq 0 ]; then
    echo "Nothing to clean — the project already looks tidy."
    exit 0
fi

echo "Folders to remove ($TOTAL_DIRS):"
if [ "$TOTAL_DIRS" -gt 0 ]; then
    printf '  %s\n' "${DIRS_TO_DELETE[@]}"
else
    echo "  (none)"
fi
echo

echo "Files to remove ($TOTAL_FILES):"
if [ "$TOTAL_FILES" -gt 0 ]; then
    printf '  %s\n' "${FILES_TO_DELETE[@]}"
else
    echo "  (none)"
fi
echo

if [ "$DRY_RUN" -eq 1 ]; then
    echo "Dry run complete. Re-run without -n to actually delete."
    exit 0
fi

if [ "$ASSUME_YES" -ne 1 ]; then
    read -r -p "Proceed with deletion? [y/N] " reply
    case "$reply" in
        [Yy]|[Yy][Ee][Ss]) ;;
        *) echo "Aborted."; exit 1 ;;
    esac
fi

for d in "${DIRS_TO_DELETE[@]}"; do
    rm -rf -- "$d"
done

for f in "${FILES_TO_DELETE[@]}"; do
    rm -f -- "$f"
done

echo
echo "Cleanup complete: removed $TOTAL_DIRS folder(s) and $TOTAL_FILES file(s)."
