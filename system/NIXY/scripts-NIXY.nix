{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Required packages for scripts
    tokei
    jq

    # rebuild
    (pkgs.writeShellScriptBin "rebuild" ''
      # NIXY(aarch64-darwin)
      echo "Rebuilding..."
      cd ~/.dotfiles
      darwin-rebuild switch --show-trace --flake .#NIXY

      echo "fetching latest erase-install pkg."
      ${pkgs.bash}/bin/bash ${../../erase-install-fetcher.sh}
      echo "Updating readme.md with tokei..."

      # Generate code statistics with tokei and format as markdown table
      STATS=$(${pkgs.tokei}/bin/tokei --output json .)
      DATE=$(date)

      # Process tokei output with jq to create markdown table
      TABLE=$(echo "$STATS" | ${pkgs.jq}/bin/jq -r '
        "| Language | Files | Lines | Code | Comments | Blanks |\n| ---------- | ----- | ----- | ----- | -------- | ------ |" +
        (to_entries[] | "| " + .key + " | " + (.value.stats.n_files | tostring) + 
        " | " + (.value.stats.n_lines | tostring) + 
        " | " + (.value.stats.code | tostring) + 
        " | " + (.value.stats.comments | tostring) + 
        " | " + (.value.stats.blanks | tostring) + " |") +
        "| **Total** | " + 
        (reduce .[] as $item (0; . + $item.stats.n_files) | tostring) + " | " +
        (reduce .[] as $item (0; . + $item.stats.n_lines) | tostring) + " | " +
        (reduce .[] as $item (0; . + $item.stats.code) | tostring) + " | " +
        (reduce .[] as $item (0; . + $item.stats.comments) | tostring) + " | " +
        (reduce .[] as $item (0; . + $item.stats.blanks) | tostring) + " |"
      ')

      # Update README.md with new table
      ${pkgs.perl}/bin/perl -i -pe "s/👨‍💻 There are .* lines of code in this repo.*/👨‍💻 Code Statistics:\n\n$TABLE\n\nLast updated: $DATE/" README.md

      echo "Formatting all nix files..."
      ${pkgs.treefmt2}/bin/treefmt ${
        if pkgs.stdenv.isDarwin then "/Users/alex/.dotfiles" else "/home/alex/.dotfiles"
      }

      echo "Done."
      date +"%I:%M:%S %p"
    '')
  ];
}
