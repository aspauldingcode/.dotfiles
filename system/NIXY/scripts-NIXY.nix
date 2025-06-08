{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tokei
    jq

    (writeShellScriptBin "rebuild" ''
      echo "Rebuilding..."
      cd ~/.dotfiles
      sudo darwin-rebuild switch --show-trace --flake .#NIXY

      echo "Fetching latest erase-install pkg."
      ${bash}/bin/bash ${../../erase-install-fetcher.sh}

      echo "Updating readme.md with tokei..."
      DATE=$(date)

      TOKEI_JSON=$(tokei . --output json | jq '{ CSS, JSON, Lua, Markdown, Nix, Python, Shell, "Plain Text", TOML, "Vim script", YAML }')

      TABLE="<!-- BEGIN CODE STATS -->\n"
      TABLE+="## How much code?\n"
      TABLE+="👨‍💻 Code Statistics:\n\n"
      TABLE+="| Language | Files | Lines | Code | Comments | Blanks |\n"
      TABLE+="|----------|-------|-------|------|----------|--------|"

      TOTAL_FILES=0
      TOTAL_CODE=0
      TOTAL_COMMENTS=0
      TOTAL_BLANKS=0

      while IFS=$'\t' read -r LANG FILES CODE COMMENTS BLANKS; do
        LINES=$((CODE + COMMENTS + BLANKS))
        TABLE+=$'\n'"| $LANG | $FILES | $LINES | $CODE | $COMMENTS | $BLANKS |"
        TOTAL_FILES=$((TOTAL_FILES + FILES))
        TOTAL_CODE=$((TOTAL_CODE + CODE))
        TOTAL_COMMENTS=$((TOTAL_COMMENTS + COMMENTS))
        TOTAL_BLANKS=$((TOTAL_BLANKS + BLANKS))
      done < <(echo "$TOKEI_JSON" | jq -r '
        to_entries[]
        | select(.key | IN("CSS", "JSON", "Lua", "Markdown", "Nix", "Python", "Shell", "Plain Text", "TOML", "Vim script", "YAML"))
        | [.key, (.value.reports | length), .value.code, .value.comments, .value.blanks]
        | @tsv')

      TOTAL_LINES=$((TOTAL_CODE + TOTAL_COMMENTS + TOTAL_BLANKS))
      TABLE+=$'\n'"| **Total** | $TOTAL_FILES | $TOTAL_LINES | $TOTAL_CODE | $TOTAL_COMMENTS | $TOTAL_BLANKS |"
      TABLE+=$'\n\n'"Last updated: $DATE"
      TABLE+=$'\n'"<!-- END CODE STATS -->"

      TMPFILE=$(mktemp)
      echo -e "$TABLE" > "$TMPFILE"

      perl -0777 -i -pe "
        my \$table = do { local \$/; open my \$fh, '<', '$TMPFILE' or die \$!; <\$fh> };
        \$table =~ s/\n+\z//;  # Remove trailing newlines
        s|<!-- BEGIN CODE STATS -->.*?<!-- END CODE STATS -->|\$table|s;
      " README.md

      rm "$TMPFILE"

      echo "Formatting all nix files..."
      ${treefmt2}/bin/treefmt ~/.dotfiles

      echo "Done."
      date +"%I:%M:%S %p"
    '')
  ];
}
