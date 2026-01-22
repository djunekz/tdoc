#!/usr/bin/env bash
# check_fix_permissions.sh
# Versi bersih untuk Termux: cek shebang, permissions, dan line endings

# Warna untuk output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fungsi untuk cek shebang
check_shebang() {
    local file="$1"
    if [[ ! -f "$file" ]]; then return; fi
    local first_line
    first_line=$(head -n1 "$file")
    if [[ "$first_line" != "#!/usr/bin/env bash" ]]; then
        echo -e "${YELLOW}⚠ Shebang mismatch in $file${NC}"
        # Perbaiki shebang otomatis
        sed -i "1s|.*|#!/usr/bin/env bash|" "$file"
        echo -e "${GREEN}✅ Shebang fixed in $file${NC}"
    else
        echo -e "${GREEN}✅ Shebang OK in $file${NC}"
    fi
}

# Fungsi untuk cek permission
check_permission() {
    local file="$1"
    if [[ ! -f "$file" ]]; then return; fi
    if [[ ! -x "$file" ]]; then
        chmod +x "$file"
        echo -e "${GREEN}✅ Permission fixed (executable) for $file${NC}"
    else
        echo -e "${GREEN}✅ Permission OK for $file${NC}"
    fi
}

# Fungsi untuk cek line endings (convert CRLF -> LF)
check_line_endings() {
    local file="$1"
    if [[ ! -f "$file" ]]; then return; fi
    if file "$file" | grep -q CRLF; then
        sed -i 's/\r$//' "$file"
        echo -e "${GREEN}✅ Converted CRLF -> LF in $file${NC}"
    else
        echo -e "${GREEN}✅ Line endings OK in $file${NC}"
    fi
}

# Fungsi utama: scan folder
scan_folder() {
    local folder="$1"
    echo -e "${YELLOW}🔎 Scanning $folder ...${NC}"
    # Temukan semua file .sh dan file executable utama
    local files
    files=$(find "$folder" -type f)
    for f in $files; do
        check_shebang "$f"
        check_permission "$f"
        check_line_endings "$f"
    done
    echo -e "${GREEN}✅ Scan complete for $folder${NC}"
}

# Mulai scan dari folder sekarang
scan_folder "."
