function __git_all_run -d 'Run a git subcommand in every repository in parallel (usage: __git_all_run <verb> [args...])'
    if test (count $argv) -eq 0
        echo "usage: __git_all_run <verb> [args...]" >&2
        return 2
    end
    # パスに ' や \ を含むリポジトリで xargs が解釈しないよう NUL 区切りで渡す
    __repo_list | string join0 | xargs -0 -P 8 -I{} sh -c \
        'repo=$1; verb=$2; shift 2; git -C "$repo" "$verb" "$@" && echo "$repo: $verb done" || echo "$repo: $verb failed"' _ {} $argv
end
