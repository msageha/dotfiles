function du_sort --description "List dotfile-inclusive sizes one level deep, largest first"
    du -h -d 1 $argv | sort -hr
end
