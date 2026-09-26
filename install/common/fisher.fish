#!/usr/bin/env fish

function install_fisher
    echo (set_color blue)"Installing Fisher..."(set_color normal)
    curl -fsL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher install jorgebucaran/fisher
end

function update_fisher
    echo (set_color blue)"Updating Fisher..."(set_color normal)
    fisher update
end

function main
    if not type -q fisher
        install_fisher
        or return
    end

    update_fisher
    set -l update_status $status

    fish_update_completions

    return $update_status
end

if not status --is-interactive
    main
end
