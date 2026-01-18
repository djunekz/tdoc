#!/data/data/com.termux/files/usr/bin/bash
# ==============================
# TDOC — Explanation Runner (UI-compliant)
# ==============================

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/ai_explain.sh"

print_header "🧠 Termux Doctor — Explanation Mode"

# Check STATE_FILE exists
if [ ! -f "$STATE_FILE" ]; then
    print_err "STATE_FILE not found: $STATE_FILE"
    exit 1
fi

while IFS='=' read -r key value; do
    # Skip OK items
    [[ "$value" == "OK" ]] && continue

    print_warn "Issue Detected: $key"

    case "$key" in
        Repository|Storage|Python|NodeJS|Git|TermuxVersion)
            ai_explain "$key" | while IFS= read -r line; do
                print_info "$line"
            done
            ;;
        *)
            ai_explain "Unknown" | while IFS= read -r line; do
                print_info "$line"
            done
            ;;
    esac

    echo
done < "$STATE_FILE"

print_ok "All explanations processed"
