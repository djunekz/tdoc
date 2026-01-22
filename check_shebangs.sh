#!/usr/bin/env bash
# check_shebangs.sh — Quick CI compliance check

echo "Checking shebangs and permissions..."

# files that should be executable
EXEC_FILES=("tdoc" "install.sh" "uninstall.sh")

# all core scripts
CORE_FILES=(core/*.sh)

# 1️⃣ Fix line endings & remove BOM
for f in "${EXEC_FILES[@]}" "${CORE_FILES[@]}"; do
  sed -i '1s/^\xEF\xBB\xBF//' "$f"   # remove BOM
  sed -i 's/\r$//' "$f"             # remove CRLF
done

# 2️⃣ Fix shebangs
for f in "${EXEC_FILES[@]}" "${CORE_FILES[@]}"; do
  head -n 1 "$f" | grep -q '^#!/usr/bin/env bash' || {
    echo "Fixing shebang for $f"
    tail -n +2 "$f" > "$f.tmp"
    printf '#!/usr/bin/env bash\n' > "$f"
    cat "$f.tmp" >> "$f"
    rm "$f.tmp"
  }
done

# 3️⃣ Fix permissions
for f in "${EXEC_FILES[@]}"; do
  chmod +x "$f"
done
for f in "${CORE_FILES[@]}"; do
  chmod -x "$f"
done

# 4️⃣ Report
echo
echo "Executable files:"
ls -l "${EXEC_FILES[@]}"
echo
echo "Non-executable core files:"
ls -l "${CORE_FILES[@]}"
echo
echo "Shebangs check (first line of each file):"
for f in "${EXEC_FILES[@]}" "${CORE_FILES[@]}"; do
  printf "%-25s: %s\n" "$f" "$(head -n 1 "$f")"
done

echo
echo "✅ Check complete. All files should now comply with CI rules."
