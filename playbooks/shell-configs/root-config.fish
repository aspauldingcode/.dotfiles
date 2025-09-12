# Root Fish Configuration
# Basic shell configuration for root user

# Set up basic aliases
alias ll 'ls -la'
alias la 'ls -A'
alias l 'ls -CF'

# Root-specific prompt (red)
function fish_prompt
    set_color red
    echo -n (whoami)'@'(hostname)':'(pwd)'# '
    set_color normal
end

# History settings
set -g fish_history_size 1000
