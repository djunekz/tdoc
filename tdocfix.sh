#!/data/data/com.termux/files/usr/bin/bash
# -- Authors: Jean-Luc NAIL & Gemini
# -- Version: 1.01
# -- Description: Automatic and strict cleanup of orphan dpkg/apt locks

# 1. Security check: is there any active process?
ACTIVE_PROCS=$(ps aux | grep -E "apt|dpkg" | grep -v -E "grep|docfix.sh" | wc -l)

if [ "$ACTIVE_PROCS" -gt 0 ]; then
    echo "[-] Error: An apt or dpkg process is currently running."
    echo "    Please wait or terminate the task cleanly."
    exit 1
fi

echo "[+] No active process detected. Cleaning up residual locks..."

# 2. List of potential lock files
LOCKS=(
    "$PREFIX/var/lib/dpkg/lock"
    "$PREFIX/var/lib/dpkg/lock-frontend"
    "$PREFIX/var/cache/apt/archives/lock"
)

DELETED_COUNT=0

for LOCK_FILE in "${LOCKS[@]}"; do
    if [ -f "$LOCK_FILE" ]; then
        rm "$LOCK_FILE" && echo "    [✔] Removed: $(basename "$LOCK_FILE")"
        ((DELETED_COUNT++))
    fi
done

if [ "$DELETED_COUNT" -eq 0 ]; then
    echo "[~] No orphan lock files found. The system is already clean."
else
    echo "[+] $DELETED_COUNT lock(s) cleaned up."
    # Give the system a brief moment to release descriptors
    sleep 0.5
fi

# 3. Final validation with tdoc
echo "[+] Validating global status:"
tdoc doctor --json | grep -E "dpkglock|broken"
