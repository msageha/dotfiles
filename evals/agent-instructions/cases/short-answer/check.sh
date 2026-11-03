check tree-intact '作業ツリーが変わっていない' tree_unchanged
check two-lines '応答 (複数あれば合計) が 4 行・300 文字以内' bash -c 't=$(jq -rs "map(select(.type == \"result\") | .result // \"\" | select(length > 0)) | join(\"\\n\")" "$RUN_DIR/stream.jsonl"); [[ -n $t && $(grep -c . <<< "$t") -le 4 && ${#t} -le 300 ]]'
