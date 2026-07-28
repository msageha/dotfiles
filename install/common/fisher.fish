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

    # キャッシュ削除は best-effort だが、最後に置くと関数全体の status を上書きして
    # fisher の失敗を握りつぶすため、終了ステータスは update の結果を明示的に返す
    rm $HOME/.cache/fish/config.fish 2> /dev/null
    return $update_status
end

if not status --is-interactive
    main
end
