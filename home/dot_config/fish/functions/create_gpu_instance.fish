function create_gpu_instance
    # 変数の初期設定。インスタンス名は引数で指定でき、省略時はタイムスタンプ付き
    # (固定名だと再実行で名前衝突エラーになるため)
    set -l INSTANCE_NAME $argv[1]
    if test -z "$INSTANCE_NAME"
        set INSTANCE_NAME my-gpu-instance-(date +%Y%m%d-%H%M%S)
    end
    set -l IMAGE_PROJECT nvidia-ngc-public  # NVIDIAが提供するイメージプロジェクト
    set -l IMAGE_FAMILY nvidia-gpu-optimized-ubuntu-2204-lts  # 22.04のイメージ

    # GPU 構成を選択
    # N1 + T4: 汎用VMにGPUを追加 (--accelerator が必要)
    # G2 (L4), A2 (A100), A3 (H100): accelerator-optimized VM (GPUはマシンタイプに内包)
    set -l GPU_CONFIGS \
        "n1-standard-8  / nvidia-tesla-t4 / asia-northeast1-c / 1 / standard" \
        "n1-standard-16 / nvidia-tesla-t4 / asia-northeast1-c / 1 / standard" \
        "n1-highmem-8   / nvidia-tesla-t4 / asia-northeast1-c / 1 / standard" \
        "n1-highmem-16  / nvidia-tesla-t4 / asia-northeast1-c / 1 / standard" \
        "g2-standard-8  / nvidia-l4       / asia-northeast1-b / 0 / standard" \
        "g2-standard-16 / nvidia-l4       / asia-northeast1-b / 0 / standard" \
        "a2-highgpu-1g  / nvidia-a100-40gb / asia-northeast1-c / 0 / standard" \
        "a3-highgpu-1g  / nvidia-h100-80gb / asia-northeast1-b / 0 / spot"
    set -l SELECTED (printf '%s\n' $GPU_CONFIGS | fzf --prompt="Select configuration: ")

    if test -z "$SELECTED"
        echo "No configuration selected. Exiting."
        return 1
    end

    set -l MACHINE_TYPE (echo $SELECTED | awk -F' / ' '{ gsub(/^ +| +$/, "", $1); print $1 }')
    set -l GPU_TYPE (echo $SELECTED | awk -F' / ' '{ gsub(/^ +| +$/, "", $2); print $2 }')
    set -l ZONE (echo $SELECTED | awk -F' / ' '{ gsub(/^ +| +$/, "", $3); print $3 }')
    set -l NEEDS_ACCELERATOR (echo $SELECTED | awk -F' / ' '{ gsub(/^ +| +$/, "", $4); print $4 }')
    set -l PROVISIONING (echo $SELECTED | awk -F' / ' '{ gsub(/^ +| +$/, "", $5); print $5 }')

    # VMインスタンスの作成
    set -l cmd gcloud compute instances create $INSTANCE_NAME \
        --zone $ZONE \
        --machine-type $MACHINE_TYPE \
        --image-family $IMAGE_FAMILY \
        --image-project $IMAGE_PROJECT \
        --boot-disk-size 100GB \
        --maintenance-policy TERMINATE

    # N1 系は --accelerator でGPUを追加
    if test "$NEEDS_ACCELERATOR" = "1"
        set -a cmd --accelerator type=$GPU_TYPE,count=1
    end

    # SPOT プロビジョニング (A3 等) — SPOT VM では --restart-on-failure は使用不可
    if test "$PROVISIONING" = "spot"
        set -a cmd --provisioning-model=SPOT
    else
        set -a cmd --restart-on-failure
    end

    # 課金を伴う操作のため、実行するコマンド全文を提示して確認を取る
    echo "About to create instance '$INSTANCE_NAME': $MACHINE_TYPE ($GPU_TYPE) in $ZONE"
    printf '  %s\n' "$cmd"
    read -l -P "Create this instance (billing applies)? [y/N] " ans
    string match -qi y -- $ans; or return 1

    $cmd
end
