{
  writeShellApplication,
  ...
}:
writeShellApplication {
  name = "why-depends";

  meta = {
    mainProgram = "why-depends";
  };

  checkPhase = "";

  text = # bash
    ''
      # Usage: ./why-depends.sh <flake-output> <partial-pname>
      # Example: ./why-depends.sh .#nixosConfigurations.khanelinix.config.system.build.toplevel chromium-unwrapped

      FLAKE_OUTPUT="$1"
      DEPENDENCY_MATCH="$2"

      echo "🔨 Building $FLAKE_OUTPUT..."
      nix build "$FLAKE_OUTPUT" >/dev/null

      TOPLEVEL_PATH=$(readlink -f result)
      echo "📦 Toplevel path: $TOPLEVEL_PATH"

      echo "🔍 Searching for dependency matching '$DEPENDENCY_MATCH'..."
      mapfile -t MATCHING <<<"$(nix-store -qR "$TOPLEVEL_PATH" | grep "$DEPENDENCY_MATCH" || true)"

      if [[ "''${#MATCHING[@]}" -eq 0 ]]; then
        echo "❌ No match found for '$DEPENDENCY_MATCH' in the closure."
        exit 1
      fi

      echo "✅ Found match(es):"
      printf '%s\n' "''${MATCHING[@]}"

      if [[ "''${#MATCHING[@]}" -gt 1 ]]; then
        echo
        echo "⚠️ Multiple matches found. Please select one:"
        select MATCH in "''${MATCHING[@]}"; do
          if [[ -n "$MATCH" ]]; then
            DEP_PATH="$MATCH"
            break
          fi
        done
      else
        DEP_PATH="''${MATCHING[0]}"
      fi

      if [[ -z "$MATCHING" ]]; then
        echo "❌ No match found for '$DEPENDENCY_MATCH' in the closure."
        exit 1
      fi

      echo "✅ Found match:"
      echo "$MATCHING"

      # If multiple matches, ask the user
      MATCH_COUNT=$(echo "$MATCHING" | wc -l)
      if [[ "$MATCH_COUNT" -gt 1 ]]; then
        echo
        echo "⚠️ Multiple matches found. Please select one:"
        select MATCH in "''${MATCHING[@]}"; do
          if [[ -n "$MATCH" ]]; then
            DEP_PATH="$MATCH"
            break
          fi
        done
      else
        DEP_PATH="$MATCHING"
      fi

      echo "🔎 Running nix why-depends:"
      nix why-depends "$TOPLEVEL_PATH" "$DEP_PATH"
    '';
}
