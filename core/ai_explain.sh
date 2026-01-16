#!/bin/bash

source "$TDOC_ROOT/core/ui.sh"
source "$TDOC_ROOT/core/ai_engine.sh"

ai_explain_item() {
  local item="$1"

  print_header "🤖 AI Diagnosis: $item"
  ai_diagnose "$item"
  echo
}
