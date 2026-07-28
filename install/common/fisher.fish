#!/usr/bin/env fish

function install
    echo (set_color blue)"Installing Fisher..."(set_color normal)
    curl -fsL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher install jorgebucaran/fisher
end

function update
    echo (set_color blue)"Updating Fisher..."(set_color normal)
    fisher update
end

function main
    if not type -q fisher
        install
        or return
    end

    update
    set -l update_status $status

    fish_update_completions

    return $update_status
end

if not status --is-interactive
    main
end
