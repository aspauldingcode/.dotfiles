{
  pkgs,
  lib,
  ...
}: let
  # Helper function to determine OS-specific keymap
  osKeymap =
    if pkgs.stdenv.isDarwin
    then "<D-p>"
    else "<C-p>";

  # Create the print script content
  printScript = ''
    #!/usr/bin/env bash
    # Print script for converting files to PDF with format detection

    set -euo pipefail

    # Colors for output
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    # Function to print colored output
    print_status() {
        echo -e "''${BLUE}[PRINT]''${NC} $1"
    }

    print_success() {
        echo -e "''${GREEN}[SUCCESS]''${NC} $1"
    }

    print_warning() {
        echo -e "''${YELLOW}[WARNING]''${NC} $1"
    }

    print_error() {
        echo -e "''${RED}[ERROR]''${NC} $1"
    }

    # Function to detect file type
    detect_file_type() {
        local file="$1"
        local extension="''${file##*.}"
        local mime_type=$(file --mime-type "$file" | cut -d: -f2 | tr -d ' ')

        # Check if it's a binary file
        if [[ "$mime_type" == application/* ]] && [[ "$mime_type" != application/pdf ]] && [[ "$mime_type" != application/json ]]; then
            echo "binary"
            return
        fi

        # Check file extension and content
        case "$extension" in
            md|markdown)
                echo "markdown"
                ;;
            adoc|asciidoc)
                echo "asciidoc"
                ;;
            tex|latex)
                echo "latex"
                ;;
            *)
                # Check first few lines for shebang or content hints
                local first_line=$(head -n 1 "$file" 2>/dev/null || echo "")
                if [[ "$first_line" =~ ^#! ]]; then
                    echo "script"
                elif [[ "$first_line" =~ ^--- ]] || [[ "$first_line" =~ ^\s*# ]]; then
                    echo "markdown"
                else
                    echo "text"
                fi
                ;;
        esac
    }

    # Function to print markdown to PDF
    print_markdown() {
        local input_file="$1"
        local output_file="$2"

        print_status "Converting markdown to PDF using Pandoc..."

        # Create a temporary CSS file for styling
        local css_file=$(mktemp)
        cat > "$css_file" << 'EOF'
    @page {
        size: A4;
        margin: 2cm;
        @top-center {
            content: string(title);
        }
        @bottom-center {
            content: counter(page);
        }
    }

    body {
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        line-height: 1.6;
        color: #333;
        max-width: 100%;
    }

    h1, h2, h3, h4, h5, h6 {
        color: #2c3e50;
        margin-top: 1.5em;
        margin-bottom: 0.5em;
    }

    h1 { font-size: 2em; border-bottom: 2px solid #3498db; padding-bottom: 0.3em; }
    h2 { font-size: 1.5em; border-bottom: 1px solid #bdc3c7; padding-bottom: 0.2em; }
    h3 { font-size: 1.3em; }
    h4 { font-size: 1.1em; }

    code {
        background-color: #f8f9fa;
        padding: 0.2em 0.4em;
        border-radius: 3px;
        font-family: 'Courier New', monospace;
        font-size: 0.9em;
    }

    pre {
        background-color: #f8f9fa;
        padding: 1em;
        border-radius: 5px;
        overflow-x: auto;
        border-left: 4px solid #3498db;
    }

    pre code {
        background-color: transparent;
        padding: 0;
    }

    blockquote {
        border-left: 4px solid #3498db;
        margin: 1em 0;
        padding-left: 1em;
        color: #666;
        font-style: italic;
    }

    table {
        border-collapse: collapse;
        width: 100%;
        margin: 1em 0;
    }

    th, td {
        border: 1px solid #ddd;
        padding: 8px;
        text-align: left;
    }

    th {
        background-color: #f2f2f2;
        font-weight: bold;
    }

    img {
        max-width: 100%;
        height: auto;
        display: block;
        margin: 1em auto;
    }

    a {
        color: #3498db;
        text-decoration: none;
    }

    a:hover {
        text-decoration: underline;
    }

    hr {
        border: none;
        border-top: 1px solid #ddd;
        margin: 2em 0;
    }
    EOF

        pandoc "$input_file" -o "$output_file" --pdf-engine=xelatex --css="$css_file" \
            -V geometry:margin=1in -V fontsize=11pt

        rm "$css_file"
    }

    # Function to print asciidoc to PDF
    print_asciidoc() {
        local input_file="$1"
        local output_file="$2"

        print_status "Converting AsciiDoc to PDF..."

        # First convert markdown to asciidoc if needed
        local temp_adoc="$input_file"
        if [[ "''${input_file##*.}" != "adoc" ]] && [[ "''${input_file##*.}" != "asciidoc" ]]; then
            temp_adoc=$(mktemp --suffix=.adoc)
            pandoc "$input_file" -t asciidoc -o "$temp_adoc"
        fi

        asciidoctor-pdf "$temp_adoc" -o "$output_file"

        # Clean up temp file if we created one
        if [[ "$temp_adoc" != "$input_file" ]]; then
            rm "$temp_adoc"
        fi
    }

    # Function to print LaTeX to PDF
    print_latex() {
        local input_file="$1"
        local output_file="$2"

        print_status "Converting LaTeX to PDF..."

        # Use xelatex for better Unicode support
        xelatex -interaction=nonstopmode -output-directory="$(dirname "$output_file")" \
            -job-name="$(basename "$output_file" .pdf)" "$input_file" > /dev/null 2>&1

        # Move the output to the desired location
        local generated_pdf="$(dirname "$output_file")/$(basename "$output_file" .pdf).pdf"
        if [[ -f "$generated_pdf" ]]; then
            mv "$generated_pdf" "$output_file"
        fi
    }

    # Function to print text with syntax highlighting
    print_text_with_highlighting() {
        local input_file="$1"
        local output_file="$2"

        print_status "Converting text to PDF with syntax highlighting..."

        # Create a temporary HTML file
        local html_file=$(mktemp --suffix=.html)

        # Generate HTML with syntax highlighting using bat
        {
            echo "<!DOCTYPE html>"
            echo "<html><head>"
            echo "<meta charset='utf-8'>"
            echo "<title>$(basename "$input_file")</title>"
            echo "<style>"
            echo "body { font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace; font-size: 12px; line-height: 1.4; margin: 2cm; }"
            echo "pre { background-color: #f8f9fa; padding: 1em; border-radius: 5px; overflow-x: auto; }"
            echo "</style>"
            echo "</head><body>"
            echo "<h1>$(basename "$input_file")</h1>"
            echo "<pre><code>"
            bat --color=always --style=full --language="$(basename "$input_file")" "$input_file" | ansi2html
            echo "</code></pre>"
            echo "</body></html>"
        } > "$html_file"

        # Convert HTML to PDF using pandoc only
        pandoc "$html_file" -o "$output_file" --pdf-engine=xelatex

        rm "$html_file"
    }

    # Function to print plain text
    print_plain_text() {
        local input_file="$1"
        local output_file="$2"

        print_status "Converting plain text to PDF..."

        # Create a temporary HTML file
        local html_file=$(mktemp --suffix=.html)

        {
            echo "<!DOCTYPE html>"
            echo "<html><head>"
            echo "<meta charset='utf-8'>"
            echo "<title>$(basename "$input_file")</title>"
            echo "<style>"
            echo "body { font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace; font-size: 12px; line-height: 1.4; margin: 2cm; }"
            echo "pre { background-color: #f8f9fa; padding: 1em; border-radius: 5px; overflow-x: auto; white-space: pre-wrap; }"
            echo "</style>"
            echo "</head><body>"
            echo "<h1>$(basename "$input_file")</h1>"
            echo "<pre>"
            cat "$input_file" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
            echo "</pre>"
            echo "</body></html>"
        } > "$html_file"

        # Convert HTML to PDF
        pandoc "$html_file" -o "$output_file" --pdf-engine=xelatex

        rm "$html_file"
    }

    # Function to print binary file info
    print_binary_info() {
        local input_file="$1"
        local output_file="$2"

        print_warning "Binary file detected. Creating information summary..."

        # Create a temporary HTML file with binary file information
        local html_file=$(mktemp --suffix=.html)

        {
            echo "<!DOCTYPE html>"
            echo "<html><head>"
            echo "<meta charset='utf-8'>"
            echo "<title>Binary File: $(basename "$input_file")</title>"
            echo "<style>"
            echo "body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; font-size: 12px; line-height: 1.6; margin: 2cm; }"
            echo "h1 { color: #2c3e50; border-bottom: 2px solid #3498db; padding-bottom: 0.3em; }"
            echo "pre { background-color: #f8f9fa; padding: 1em; border-radius: 5px; overflow-x: auto; }"
            echo ".info { background-color: #e8f4fd; padding: 1em; border-radius: 5px; margin: 1em 0; }"
            echo "</style>"
            echo "</head><body>"
            echo "<h1>Binary File Information</h1>"
            echo "<div class='info'>"
            echo "<strong>File:</strong> $(basename "$input_file")<br>"
            echo "<strong>Path:</strong> $(realpath "$input_file")<br>"
            echo "<strong>Size:</strong> $(du -h "$input_file" | cut -f1)<br>"
            echo "<strong>Type:</strong> $(file "$input_file")<br>"
            echo "<strong>Modified:</strong> $(stat -c %y "$input_file" 2>/dev/null || stat -f %Sm "$input_file")<br>"
            echo "</div>"
            echo "<h2>File Details</h2>"
            echo "<pre>"
            file -b "$input_file"
            echo ""
            echo "File size: $(stat -c %s "$input_file" 2>/dev/null || stat -f %z "$input_file") bytes"
            echo "Permissions: $(stat -c %A "$input_file" 2>/dev/null || stat -f %Sp "$input_file")"
            echo "Owner: $(stat -c %U "$input_file" 2>/dev/null || stat -f %Su "$input_file")"
            echo "Group: $(stat -c %G "$input_file" 2>/dev/null || stat -f %Sg "$input_file")"
            echo "</pre>"
            echo "</body></html>"
        } > "$html_file"

        # Convert HTML to PDF
        pandoc "$html_file" -o "$output_file" --pdf-engine=xelatex

        rm "$html_file"
    }

    # Main function
    main() {
        if [[ $# -eq 0 ]]; then
            print_error "Usage: $0 <input_file> [output_file]"
            exit 1
        fi

        local input_file="$1"
        local output_file

        # Check if input file exists
        if [[ ! -f "$input_file" ]]; then
            print_error "File not found: $input_file"
            exit 1
        fi

        # Determine output file
        if [[ $# -eq 2 ]]; then
            output_file="$2"
        else
            output_file="''${input_file%.*}.pdf"
        fi

        print_status "Processing: $input_file"
        print_status "Output: $output_file"

        # Detect file type
        local file_type=$(detect_file_type "$input_file")
        print_status "Detected file type: $file_type"

        # Process based on file type
        case "$file_type" in
            markdown)
                print_markdown "$input_file" "$output_file"
                ;;
            asciidoc)
                print_asciidoc "$input_file" "$output_file"
                ;;
            latex)
                print_latex "$input_file" "$output_file"
                ;;
            script|text)
                print_text_with_highlighting "$input_file" "$output_file"
                ;;
            binary)
                print_binary_info "$input_file" "$output_file"
                ;;
            *)
                print_warning "Unknown file type, treating as plain text"
                print_plain_text "$input_file" "$output_file"
                ;;
        esac

        if [[ -f "$output_file" ]]; then
            print_success "PDF generated successfully: $output_file"

            # Open the PDF if we're in a graphical environment
            if command -v xdg-open >/dev/null 2>&1; then
                xdg-open "$output_file" >/dev/null 2>&1 &
            elif command -v open >/dev/null 2>&1; then
                open "$output_file" >/dev/null 2>&1 &
            fi
        else
            print_error "Failed to generate PDF"
            exit 1
        fi
    }

    # Run main function with all arguments
    main "$@"
  '';
in {
  # Add required packages for printing functionality
  home.packages = with pkgs; [
    pandoc
    texlive.combined.scheme-full
    asciidoctor
    bat
    file
    ansi2html
    # Add the nvim-print script as a package
    (writeShellScriptBin "nvim-print" printScript)
  ];

  # Add custom commands and keymaps for printing
  programs.nixvim.extraConfigLua = ''
    -- Print function that detects file type and converts to PDF
    _G.print_to_pdf = function()
      local current_file = vim.fn.expand('%')

      if current_file == "" then
        vim.notify('No file is currently open', vim.log.levels.ERROR)
        return
      end

      local output_file = vim.fn.expand('%:r') .. '.pdf'

      vim.notify('Starting PDF conversion...', vim.log.levels.INFO)

      -- Use the external print script
      local cmd = string.format('nvim-print "%s" "%s"',
        current_file, output_file)

      vim.fn.jobstart(cmd, {
        on_stdout = function(_, data, _)
          if data then
            for _, line in ipairs(data) do
              if line ~= "" then
                -- Strip ANSI color codes for console display
                local clean_line = line:gsub(string.char(27) .. "%[%d+;?%d*;?%d*;?%d*;?%d*m", "")
                print(clean_line)
              end
            end
          end
        end,
        on_stderr = function(_, data, _)
          if data then
            for _, line in ipairs(data) do
              if line ~= "" then
                -- Strip ANSI color codes for console display
                local clean_line = line:gsub(string.char(27) .. "%[%d+;?%d*;?%d*;?%d*;?%d*m", "")
                print("[ERROR] " .. clean_line)
              end
            end
          end
        end,
        on_exit = function(_, code)
          if code == 0 then
            vim.notify('PDF generated successfully: ' .. output_file, vim.log.levels.INFO)
            -- Open the PDF
            vim.fn.jobstart('open "' .. output_file .. '"')
          else
            vim.notify('Failed to generate PDF', vim.log.levels.ERROR)
          end
        end
      })
    end

    -- Create command
    vim.api.nvim_create_user_command('Print', _G.print_to_pdf, {})
  '';

  # Add keymaps for printing
  programs.nixvim.keymaps = [
    {
      mode = "n";
      key = osKeymap;
      action = "<cmd>lua print_to_pdf()<CR>";
      options = {
        desc = "Print current file to PDF";
      };
    }
  ];
}
