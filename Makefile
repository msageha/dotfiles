DOCKER_REPOSITORY ?= msageha/dotfiles

# 1 バリアントをビルドする共通レシピ。
# $(1)=タグ suffix, $(2)=ベースイメージ, $(3)=skip_cli_tools
# $(4)=Dockerfile (省略時は docker/Dockerfile.debian)
# GUI ツールはどのバリアントでもインストールしないため SKIP_GUI_TOOLS=true 固定。
# GitHub のレート制限回避のため gh のトークンを BuildKit secret で渡す。
define build_variant
	GITHUB_TOKEN="$$(gh auth token -h github.com)" && \
	export GITHUB_TOKEN && \
	DOCKER_BUILDKIT=1 docker build \
		--secret id=github_token,env=GITHUB_TOKEN \
		-f $(if $(4),$(4),docker/Dockerfile.debian) \
		--build-arg "BASE_IMAGE=$(2)" \
		--build-arg "SKIP_CLI_TOOLS=$(3)" \
		--build-arg "SKIP_GUI_TOOLS=true" \
		-t $(DOCKER_REPOSITORY):$(1) .
endef

# 1 バリアントを amd64/arm64 マルチアーキでビルドし registry に push する共通レシピ。
# 引数は build_variant と同じ ($(1)=タグ suffix, $(2)=ベースイメージ, $(3)=skip_cli_tools,
# $(4)=Dockerfile (省略時は docker/Dockerfile.debian))。
# GUI ツールはどのバリアントでもインストールしないため SKIP_GUI_TOOLS=true 固定。
# マルチアーキ manifest list はローカル docker に
# load できないため --push 一択 (事前に docker login 済みであること)。
# 呼び出し側で buildx ビルダー (mybuilder) を有効化しておくこと。
define build_variant_multi
	GITHUB_TOKEN="$$(gh auth token -h github.com)" && \
	export GITHUB_TOKEN && \
	docker buildx build -f $(if $(4),$(4),docker/Dockerfile.debian) \
		--builder mybuilder \
		--secret id=github_token,env=GITHUB_TOKEN \
		--build-arg "BASE_IMAGE=$(2)" \
		--build-arg "SKIP_CLI_TOOLS=$(3)" \
		--build-arg "SKIP_GUI_TOOLS=true" \
		--platform linux/amd64,linux/arm64 \
		--provenance=false \
		--push \
		-t $(DOCKER_REPOSITORY):$(1) .
endef

# ベースイメージ別 / 役割別のビルドマトリクス。
# 役割: -min=CLI ツールも省く最小構成 / 無印=CLI のみ (GUI 省略) / -full=CLI+GUI
.PHONY: build-ubuntu-min
build-ubuntu-min:
	$(call build_variant,ubuntu-min,ubuntu:26.04,true)

.PHONY: build-ubuntu
build-ubuntu:
	$(call build_variant,ubuntu,ubuntu:26.04,false)

.PHONY: build-debian-min
build-debian-min:
	$(call build_variant,debian-min,debian:trixie,true)

.PHONY: build-debian
build-debian:
	$(call build_variant,debian,debian:trixie,false)

.PHONY: build-debian-slim-min
build-debian-slim-min:
	$(call build_variant,debian-slim-min,debian:trixie-slim,true)

.PHONY: build-ubuntu-gpu
build-ubuntu-gpu:
	$(call build_variant,ubuntu-gpu,nvidia/cuda:13.3.0-base-ubuntu26.04,false)

# Alpine は musl 環境のため最小構成 (skip_cli_tools=true) でビルドする。
.PHONY: build-alpine
build-alpine:
	$(call build_variant,alpine,alpine:latest,true,docker/Dockerfile.alpine)

# buildx ビルダー (mybuilder) を用意して有効化する。
.PHONY: buildx-setup
buildx-setup:
	if ! docker buildx inspect mybuilder >/dev/null 2>&1; then \
		docker buildx create --name mybuilder --use --bootstrap; \
	else \
		docker buildx use mybuilder; \
	fi

# GPU (amd64 のみ) と GUI フル構成 (ubuntu-full) を除く 6 バリアントを
# amd64/arm64 マルチアーキでビルドし registry に push する。
.PHONY: build-multi-platform
build-multi-platform: buildx-setup
	$(call build_variant_multi,alpine,alpine:latest,true,docker/Dockerfile.alpine)
	$(call build_variant_multi,ubuntu-min,ubuntu:26.04,true)
	$(call build_variant_multi,ubuntu,ubuntu:26.04,false)
	$(call build_variant_multi,debian-min,debian:trixie,true)
	$(call build_variant_multi,debian,debian:trixie,false)
	$(call build_variant_multi,debian-slim-min,debian:trixie-slim,true)

# ビルド済みの全タグを push する。
.PHONY: push
push:
	for tag in alpine ubuntu-min ubuntu debian-min debian debian-slim-min ubuntu-gpu; do \
		docker push $(DOCKER_REPOSITORY):$$tag; \
	done

.PHONY: test
test:
	bats -r tests/

.PHONY: pre-commit
pre-commit:
	prek run --all-files

.PHONY: dry_run
dry_run:
	chezmoi apply --dry-run --verbose --force

.PHONY: apply
apply:
	chezmoi apply --verbose

.PHONY: encrypt_google_ime
encrypt_google_ime:
	chezmoi encrypt settings/common/google.ime.txt > settings/common/encrypted_google.ime.txt.age

.PHONY: decrypt_google_ime
decrypt_google_ime:
	chezmoi decrypt settings/common/encrypted_google.ime.txt.age > settings/common/google.ime.txt
