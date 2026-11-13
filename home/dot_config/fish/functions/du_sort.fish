function du_sort --description "直下のファイルとディレクトリ (dotfile を含む) の容量を大きい順に出す"
    du -h -d 1 $argv | sort -hr
end
