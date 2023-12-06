{ lib, config, pkgs, ... }:
# NIXY-specific packages

{
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnsupportedSystem = false;
      allowBroken = false;
    };
  };

  home.packages = with pkgs; [
    calcurse
    chatgpt-cli
    cowsay
    qemu
    discord
    spotify 
    vscode
    utm 
    mas
    vscode
    yazi #somehow it's back? what?
    nil #rnix-lsp apparently is vulnerable? 
    zoom-us
    (pkgs.python311.withPackages(ps: [ 
      ps.pygame 
      ps.matplotlib 
    ]))
    
    #json2nix converter
    (pkgs.writeScriptBin "json2nix" ''
      ${pkgs.python3}/bin/python ${pkgs.fetchurl {
      url = "https://gist.githubusercontent.com/Scoder12/0538252ed4b82d65e59115075369d34d/raw/e86d1d64d1373a497118beb1259dab149cea951d/json2nix.py";
      hash = "sha256-ROUIrOrY9Mp1F3m+bVaT+m8ASh2Bgz8VrPyyrQf9UNQ=";
      }} $@
    '')
    
    #fix-wm
    (pkgs.writeShellScriptBin "fix-wm" ''
      yabai --stop-service && yabai --start-service #helps with adding initial service
      skhd --stop-service && skhd --start-service #otherwise, I have to run manually first time.
      brew services restart felixkratz/formulae/sketchybar 
      '')

    #analyze-output
    (pkgs.writeShellScriptBin "analyze-output" '' 
      # Counter for variable names
      count=1
      # Specify the output file path
      output_file=~/.dotfiles/users/alex/NIXY/sketchybar/cal-output.txt
      
# Delimiter to replace spaces
delimiter="⌇"

# Read input from the pipe
while IFS= read -r line; do
    # Replace spaces with the specified delimiter
    formatted_line=$(echo "$line" | tr ' ' "$delimiter")

    # Assign each formatted line to a numbered variable
    var_name="line_$count"
    declare "$var_name=$formatted_line"

    # Print the variable name and formatted value
    echo "$var_name: $formatted_line"

    # Increment the counter
    ((count++))
done > "$output_file"

echo "Output saved to: $output_file"

    '')

    #assign-inputs
    (pkgs.writeShellScriptBin "assign-inputs" ''
# Specify the input file path
input_file=~/.dotfiles/users/alex/NIXY/sketchybar/cal-output.txt

# Read input from the file
while IFS= read -r line; do
    # Extract variable name and content
    var_name=$(echo "$line" | cut -d ':' -f 1)
    var_content="$(echo "$line" | cut -d ':' -f 2- | sed 's/^[[:space:]]*//')"

    # Assign content to variable
    declare "$var_name=$var_content"

    # Print variable name and content
    echo "Variable: $var_name"
    echo "Content: $var_content"
done < "$input_file"

    '')
  ];
}
