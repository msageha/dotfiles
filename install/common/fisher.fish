#!/usr/bin/env fish

function install
    echo (set_color blue)"Installing Fisher..."(set_color normal)
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
end

function update
    echo (set_color blue)"Updating Fisher..."(set_color normal)
    fisher update
end

function main
    if not type -q fisher
        install
    end

    update

    fish_update_completions

    rm $HOME/.cache/fish/config.fish 2> /dev/null || true
end

if not status --is-interactive
    main
end
