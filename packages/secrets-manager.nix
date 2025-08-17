# Secrets Manager Package
{
  pkgs,
  lib,
  stdenv,
  makeWrapper,
  dialog,
  sops,
  age,
  yq-go,
  jq,
  coreutils,
  findutils,
  gnused,
  gnugrep,
  gawk,
  bash,
}:
stdenv.mkDerivation rec {
  pname = "sops-secrets-manager";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [
    dialog
    sops
    age
    yq-go
    jq
    coreutils
    findutils
    gnused
    gnugrep
    gawk
    bash
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
        runHook preInstall

        mkdir -p $out/bin
        cat > $out/bin/secrets-manager << 'EOF'
    #!/usr/bin/env bash

    # Nix-based Secrets Manager with Dialog UI
    # Production-ready sops-nix secrets management tool

    set -euo pipefail

    # Configuration
    SCRIPT_DIR="''${DOTFILES_DIR:-$HOME/.dotfiles}"
    SECRETS_DIR="$SCRIPT_DIR/secrets"
    SOPS_CONFIG="$SCRIPT_DIR/.sops.yaml"
    LOG_FILE="$SCRIPT_DIR/secrets-audit.log"
    TEMP_DIR=$(mktemp -d)
    trap "rm -rf $TEMP_DIR" EXIT

    # Colors and UI
    export DIALOGRC=""
    DIALOG_HEIGHT=20
    DIALOG_WIDTH=70

    # Logging function
    log_action() {
        local action="$1"
        local user="''${USER:-unknown}"
        local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        echo "''${timestamp} [''${user}] ''${action}" >> "''${LOG_FILE}"
    }

    # Check if we're in the right directory
    check_environment() {
        if [[ ! -d "$SECRETS_DIR" ]]; then
            dialog --title "Error" --msgbox "Secrets directory not found: $SECRETS_DIR\n\nPlease run from your dotfiles directory or set DOTFILES_DIR environment variable." 10 60
            exit 1
        fi

        if [[ ! -f "$SOPS_CONFIG" ]]; then
            dialog --title "Error" --msgbox "SOPS configuration not found: $SOPS_CONFIG\n\nPlease ensure .sops.yaml exists in your dotfiles directory." 10 60
            exit 1
        fi

        local age_key_file="''${HOME}/.config/sops/age/keys.txt"
        if [[ ! -f "$age_key_file" ]]; then
            dialog --title "Error" --msgbox "Age key file not found: $age_key_file\n\nPlease generate age keys first:\nmkdir -p ~/.config/sops/age\nage-keygen -o ~/.config/sops/age/keys.txt" 12 70
            exit 1
        fi
    }

    # Get list of environments
    get_environments() {
        find "$SECRETS_DIR" -maxdepth 1 -type d ! -path "$SECRETS_DIR" -exec basename {} \; | sort
    }

    # Get list of secret files in an environment
    get_secret_files() {
        local env="$1"
        find "$SECRETS_DIR/$env" -name "*.yaml" -exec basename {} .yaml \; 2>/dev/null | sort || true
    }

    # Get list of secret keys in a file
    get_secret_keys() {
        local env="$1"
        local file="$2"
        local file_path="$SECRETS_DIR/$env/$file.yaml"

        if [[ -f "$file_path" ]] && sops -d "$file_path" >/dev/null 2>&1; then
            sops -d "$file_path" | yq eval 'keys | .[]' - 2>/dev/null || true
        fi
    }

    # Environment selection menu
    select_environment() {
        local title="$1"
        local envs=($(get_environments))
        local menu_items=()

        for env in "''${envs[@]}"; do
            menu_items+=("$env" "")
        done

        if [[ ''${#menu_items[@]} -eq 0 ]]; then
            dialog --title "Error" --msgbox "No environments found in $SECRETS_DIR" 8 50
            return 1
        fi

        dialog --title "$title" --menu "Select environment:" $DIALOG_HEIGHT $DIALOG_WIDTH 10 "''${menu_items[@]}" 2>"$TEMP_DIR/env"
        cat "$TEMP_DIR/env"
    }

    # Secret file selection menu
    select_secret_file() {
        local env="$1"
        local title="$2"
        local files=($(get_secret_files "$env"))
        local menu_items=()

        for file in "''${files[@]}"; do
            menu_items+=("$file" "")
        done

        if [[ ''${#menu_items[@]} -eq 0 ]]; then
            dialog --title "Error" --msgbox "No secret files found in $env environment" 8 50
            return 1
        fi

        dialog --title "$title" --menu "Select secret file:" $DIALOG_HEIGHT $DIALOG_WIDTH 10 "''${menu_items[@]}" 2>"$TEMP_DIR/file"
        cat "$TEMP_DIR/file"
    }

    # Secret key selection menu
    select_secret_key() {
        local env="$1"
        local file="$2"
        local title="$3"
        local keys=($(get_secret_keys "$env" "$file"))
        local menu_items=()

        for key in "''${keys[@]}"; do
            menu_items+=("$key" "")
        done

        if [[ ''${#menu_items[@]} -eq 0 ]]; then
            dialog --title "Info" --msgbox "No secrets found in $env/$file.yaml\n\nFile may be empty or encrypted with different keys." 10 60
            return 1
        fi

        dialog --title "$title" --menu "Select secret key:" $DIALOG_HEIGHT $DIALOG_WIDTH 10 "''${menu_items[@]}" 2>"$TEMP_DIR/key"
        cat "$TEMP_DIR/key"
    }

    # List all secrets with dialog
    list_secrets() {
        local output="$TEMP_DIR/secrets_list"
        echo "SECRETS OVERVIEW" > "$output"
        echo "================" >> "$output"
        echo "" >> "$output"

        for env in $(get_environments); do
            echo "📁 $env/" >> "$output"
            for file in $(get_secret_files "$env"); do
                echo "  📄 $file.yaml" >> "$output"
                for key in $(get_secret_keys "$env" "$file"); do
                    echo "    🔑 $key" >> "$output"
                done
            done
            echo "" >> "$output"
        done

        dialog --title "All Secrets" --textbox "$output" $DIALOG_HEIGHT $DIALOG_WIDTH
    }

    # Add or update secret
    add_secret() {
        local env file key value

        env=$(select_environment "Add Secret - Select Environment") || return
        file=$(select_secret_file "$env" "Add Secret - Select File") || return

        dialog --title "Add Secret" --inputbox "Enter secret key name:" 10 50 2>"$TEMP_DIR/key" || return
        key=$(cat "$TEMP_DIR/key")

        if [[ -z "$key" ]]; then
            dialog --title "Error" --msgbox "Secret key cannot be empty" 8 40
            return
        fi

        dialog --title "Add Secret" --passwordbox "Enter secret value for '$key':" 10 50 2>"$TEMP_DIR/value" || return
        value=$(cat "$TEMP_DIR/value")

        if [[ -z "$value" ]]; then
            dialog --title "Error" --msgbox "Secret value cannot be empty" 8 40
            return
        fi

        # Update the secret file
        local file_path="$SECRETS_DIR/$env/$file.yaml"
        local temp_file="$TEMP_DIR/secret_update.yaml"

        if sops -d "$file_path" > "$temp_file" 2>/dev/null; then
            yq eval ".$key = \"$value\"" -i "$temp_file"
        else
            echo "$key: \"$value\"" > "$temp_file"
        fi

        if sops -e "$temp_file" > "$file_path"; then
            log_action "ADD: $env/$file/$key"
            dialog --title "Success" --msgbox "Secret '$key' added successfully to $env/$file.yaml" 8 60
        else
            dialog --title "Error" --msgbox "Failed to encrypt and save secret" 8 50
        fi
    }

    # View secret
    view_secret() {
        local env file key value

        env=$(select_environment "View Secret - Select Environment") || return
        file=$(select_secret_file "$env" "View Secret - Select File") || return
        key=$(select_secret_key "$env" "$file" "View Secret - Select Key") || return

        local file_path="$SECRETS_DIR/$env/$file.yaml"

        if value=$(sops -d "$file_path" | yq eval ".$key" - 2>/dev/null); then
            log_action "VIEW: $env/$file/$key"
            dialog --title "Secret Value" --msgbox "Environment: $env\nFile: $file.yaml\nKey: $key\n\nValue: $value" 12 60
        else
            dialog --title "Error" --msgbox "Failed to decrypt or find secret '$key'" 8 50
        fi
    }

    # Remove secret
    remove_secret() {
        local env file key

        env=$(select_environment "Remove Secret - Select Environment") || return
        file=$(select_secret_file "$env" "Remove Secret - Select File") || return
        key=$(select_secret_key "$env" "$file" "Remove Secret - Select Key") || return

        dialog --title "Confirm Removal" --yesno "Are you sure you want to remove:\n\nEnvironment: $env\nFile: $file.yaml\nKey: $key\n\nThis action cannot be undone!" 12 60 || return

        local file_path="$SECRETS_DIR/$env/$file.yaml"
        local temp_file="$TEMP_DIR/secret_remove.yaml"

        if sops -d "$file_path" > "$temp_file" 2>/dev/null; then
            yq eval "del(.$key)" -i "$temp_file"
            if sops -e "$temp_file" > "$file_path"; then
                log_action "REMOVE: $env/$file/$key"
                dialog --title "Success" --msgbox "Secret '$key' removed successfully from $env/$file.yaml" 8 60
            else
                dialog --title "Error" --msgbox "Failed to encrypt and save changes" 8 50
            fi
        else
            dialog --title "Error" --msgbox "Failed to decrypt file" 8 40
        fi
    }

    # View audit log
    view_audit_log() {
        if [[ -f "$LOG_FILE" ]]; then
            dialog --title "Audit Log" --textbox "$LOG_FILE" $DIALOG_HEIGHT $DIALOG_WIDTH
        else
            dialog --title "Audit Log" --msgbox "No audit log found" 8 40
        fi
    }

    # Main menu
    main_menu() {
        while true; do
            local choice
            choice=$(dialog --title "🔐 Secrets Manager" --menu "Choose an action:" $DIALOG_HEIGHT $DIALOG_WIDTH 8 \
                "1" "📋 List all secrets" \
                "2" "➕ Add/Update secret" \
                "3" "👁️  View secret" \
                "4" "🗑️  Remove secret" \
                "5" "📜 View audit log" \
                "6" "❌ Exit" \
                2>&1 >/dev/tty) || exit 0

            case "$choice" in
                1) list_secrets ;;
                2) add_secret ;;
                3) view_secret ;;
                4) remove_secret ;;
                5) view_audit_log ;;
                6) exit 0 ;;
                *) dialog --title "Error" --msgbox "Invalid choice" 8 30 ;;
            esac
        done
    }

    # Main execution
    main() {
        check_environment
        main_menu
    }

    main "$@"
    EOF

        chmod +x $out/bin/secrets-manager

        runHook postInstall
  '';

  postFixup = ''
    wrapProgram $out/bin/secrets-manager \
      --prefix PATH : ${lib.makeBinPath buildInputs}
  '';

  meta = with lib; {
    description = "Dialog-based secrets manager for sops-nix";
    longDescription = ''
      A user-friendly, dialog-based interface for managing secrets with sops-nix.
      Provides secure secret management with audit logging and environment separation.
    '';
    homepage = "https://github.com/alex/.dotfiles";
    license = licenses.mit;
    maintainers = [ "alex" ];
    platforms = platforms.unix;
  };
}
