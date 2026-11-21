function __fenv_fnox_inline_profiles -d 'カレントディレクトリの fnox の設定の [profiles.<名前>] で定義した profile の名前を出す'
    path is -f fnox.toml fnox.local.toml; and type -q fnox; or return 0
    # fnox profiles は default と [profiles.<名前>] の profile を `  <名前> (<件数> secrets)` の形で列挙し、
    # fnox.<名前>.toml の profile は列挙しない (fnox 1.48.0)。secret を解決しないので、signin をする fnox wrapper を通さない
    command fnox profiles 2>/dev/null | string replace -rf '^\s+(.+) \(\d+ secrets?\)$' '$1'
end
