#!/usr/bin/env bash
# =========================================
# check_shebangs.sh — TDOC CI Compliance
# =========================================

set -euo pipefail

echo "🔎 Checking shebangs, line endings, and permissions..."

# --- Define files ---
EXEC_FILES=(tdoc install.sh uninstall.sh check_shebangs.sh)
CORE_FILES=(core/*.sh)

# --- 1️⃣ Clean line endings & remove BOM ---
for f in "${EXEC_FILES[@]}" "${CORE_FILES[@]}"; do
    [ -f "$f" ] || continue
    sed -i '1s/^\xEF\xBB\xBF//' "$f"   # Remove BOM
    sed -i 's/\r$//' "$f"             # Convert CRLF -> LF
done

# --- 2️⃣ Fix shebangs ---
for f in "${EXEC_FILES[@]}" "${CORE_FILES[@]}"; do
    [ -f "$f" ] || continue
    head -n1 "$f" | grep -q '^#!/usr/bin/env bash' || {
        echo "⚡ Fixing shebang for $f"
        tail -n +2 "$f" > "$f.tmp"
        printf '#!/usr/bin/env bash\n' > "$f"
        cat "$f.tmp" >> "$f"
        rm "$f.tmp"
    }
done

# --- 3️⃣ Fix permissions ---
# Executable: main scripts
for f in "${EXEC_FILES[@]}"; do
    [ -f "$f" ] || continue
    chmod +x "$f"
done

# Non-executable: core scripts
for f in "${CORE_FILES[@]}"; do
    [ -f "$f" ] || continue
    chmod -x "$f"
done

# --- 4️⃣ Report ---
echo
echo "📄 Executable files:"
ls -l "${EXEC_FILES[@]}" 2>/dev/null || echo "No executable files found"
echo
echo "📄 Core scripts (non-executable):"
ls -l "${CORE_FILES[@]}" 2>/dev/null || echo "No core scripts found"
echo
echo "📌 Shebangs (first line of each file):"
for f in "${EXEC_FILES[@]}" "${CORE_FILES[@]}"; do
    [ -f "$f" ] || continue
    printf "%-25s : %s\n" "$f" "$(head -n1 "$f")"
done

echo
echo "✅ Check complete. All files should now comply with CI rules."
