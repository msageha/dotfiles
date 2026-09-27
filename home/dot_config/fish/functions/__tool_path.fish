function __tool_path -d 'Print the path of a tool, falling back to mise which'
    # mise activate (fish) の PATH 反映は fish_prompt 時のため、fresh シェルでは command -v が失敗しうる
    if not command -v $argv[1] 2>/dev/null
        type -q mise; and mise which $argv[1] 2>/dev/null
    end
end
