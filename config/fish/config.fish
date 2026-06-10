if status is-interactive
    set fish_greeting

    # # Starship prompt
    # function starship_transient_prompt_func
    #     starship module character
    # end
    # if test "$TERM" != "linux"
    #     starship init fish | source
    #     enable_transience
    # end

    # QuickShell terminal colors
    if test -f ~/.local/state/quickshell/user/generated/terminal/sequences.txt
        cat ~/.local/state/quickshell/user/generated/terminal/sequences.txt
    end

    # Aliases
    alias clear "printf '\033[2J\033[3J\033[1;1H'"
    alias celar "printf '\033[2J\033[3J\033[1;1H'"
    alias claer "printf '\033[2J\033[3J\033[1;1H'"
    alias pamcan pacman
    alias q 'qs -c ii'
    alias inst 'yay -S'
    alias uninst 'yay -R'
    alias dir 'ls -a'
    alias vi 'nvim'
    alias vim 'nvim'
    alias nano 'nvim'
    alias doom '~/.config/emacs/bin/doom'
    alias clonecard 'sudo sh __HOME__/.config/hypr/custom/scripts/clonecard.sh'
    alias xssh 'TERM=xterm ssh'
    alias condainit 'eval "$(__HOME__/anaconda3/bin/conda shell.fish hook)"'
    if test "$TERM" != "linux"
        alias ls 'eza --icons -a --group-directories-first -l'
    end
    if test "$TERM" = "xterm-kitty"
        alias ssh 'kitten ssh'
    end
end

set -gx EDITOR nvim

# BEGIN opam configuration
test -r '__HOME__/.opam/opam-init/init.fish' && source '__HOME__/.opam/opam-init/init.fish' > /dev/null 2> /dev/null; or true
# END opam configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$PATH:/opt/anaconda/bin"
