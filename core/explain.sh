#!/usr/bin/env bash
# ==============================
# TDOC — Explanation Runner
# ==============================

source "$TDOC_ROOT/core/ai_explain.sh"

echo -e "🧠 Termux Doctor — Explanation Mode\n"

if [ ! -f "$STATE_FILE" ]; then
    echo "❌ STATE_FILE not found: $STATE_FILE"
    exit 1
fi

while IFS='=' read -r key value; do
    if [ "$value" = "OK" ]; then
        continue
    fi

    echo -e "🔹 Issue Detected: $key\n"

    case "$key" in
        Repository)
            ai_explain "Repository"
            ;;
        Storage)
            ai_explain "Storage"
            ;;
        Python)
            ai_explain "Python"
            ;;
        NodeJS)
            ai_explain "NodeJS"
            ;;
        Git)
            ai_explain "Git"
            ;;
        TermuxVersion)
            ai_explain "TermuxVersion"
            ;;
        *)
            ai_explain "Unknown"
            ;;
    esac

    echo "--------------------------------"
done < "$STATE_FILE"

echo -e "\n✅ All explanations processed."
