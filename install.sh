#!/usr/bin/env bash
set -Eeuo pipefail

LEANIN_VERSION='0.1.1'
if [[ ! -v LEANIN_REPO ]]; then
    LEANIN_REPO=https://github.com/uswl/leanin
fi
if [[ ! -v LEANIN_BRANCH ]]; then
    LEANIN_BRANCH=main
fi
LEANIN_BOOTSTRAPPED=${LEANIN_BOOTSTRAPPED:-0}

initial_banner() {
    local plan_mode=${1:-0}
    printf '\nleanin %s\n' "$LEANIN_VERSION"
    if (( plan_mode )); then
        printf '\n'
    else
        printf 'Bootstrap pessoal para Arch Linux\n'
    fi
}

EARLY_PLAN=0
EARLY_VERSION=0
EARLY_VERBOSE=0
EARLY_HELP=0
for argument in "$@"; do
    case $argument in
        --version) EARLY_VERSION=1 ;;
        --plan) EARLY_PLAN=1 ;;
        --verbose) EARLY_VERBOSE=1 ;;
        --doctor|--dry-run|--yes|--no-packages|--no-pacman|--no-flatpak|--no-aur|\
            --no-services|--no-codex|--no-git|--no-ssh|--no-github) ;;
        --help|-h) EARLY_HELP=1 ;;
        *)
            printf '> [error] opção desconhecida: %s\n' "$argument" >&2
            exit 2
            ;;
    esac
done
if (( EARLY_VERSION )); then
    if [[ -z ${BASH_SOURCE[0]:-} && ! -t 0 ]]; then
        while IFS= read -r _; do :; done
    fi
        printf 'leanin %s\n' "$LEANIN_VERSION"
    exit 0
fi

if (( EARLY_HELP )); then
    cat <<'EOF'
Uso: bash install.sh [opções]

  --dry-run       mostra ações sem alterar o sistema
  --verbose       mostra comandos e saída completa
  --plan          mostra somente o plano resumido
  --doctor        verifica o ambiente sem alterar o sistema
  --version       mostra a versão instalada
  --yes           usa defaults seguros sem prompts
  --no-packages   pula pacman, Flatpak e AUR
  --no-pacman     pula pacotes pacman
  --no-flatpak    pula Flatpak, Flathub e seus apps
  --no-aur        pula AUR helper e pacotes AUR
  --no-services   pula serviços system e user
  --no-codex      pula Codex CLI
  --no-git        pula identidade e preferências Git
  --no-ssh        pula SSH local e integração GitHub SSH
  --no-github     pula integração e autenticação GitHub
  --help          mostra esta ajuda
EOF
    exit 0
fi

bootstrap_fail() {
    printf '> [error] %s\n' "$*" >&2
    exit 1
}

validate_bootstrap_repo() {
    local repo=${1:-}
    [[ $repo =~ ^https://github\.com/[A-Za-z0-9][A-Za-z0-9_.-]*/[A-Za-z0-9][A-Za-z0-9_.-]*(\.git)?/?$ ]]
}

validate_bootstrap_branch() {
    local branch=${1:-}
    [[ -n $branch \
        && $branch =~ ^[A-Za-z0-9_][A-Za-z0-9._/-]*$ \
        && $branch != *..* \
        && $branch != */ \
        && $branch != *//* ]]
}

bootstrap_project() {
    local script_path script_dir repo_url archive_url temp_dir='' archive
    local extract_dir listing project_root root_name='' archive_size=0 entry='' entry_root=''
    local -a roots=()

    script_path=${BASH_SOURCE[0]:-}
    if [[ -n $script_path && -f $script_path ]]; then
        script_dir=${script_path%/*}
        [[ $script_dir == "$script_path" ]] && script_dir=.
        script_dir=$(cd -- "$script_dir" && pwd)
        if [[ -d $script_dir/lib && -d $script_dir/apps && -d $script_dir/services ]]; then
            LEANIN_ROOT=$script_dir
            export LEANIN_ROOT
            return 0
        fi
    fi

    if [[ $LEANIN_BOOTSTRAPPED == 1 ]]; then
        bootstrap_fail 'bootstrap concluído, mas lib/, apps/ ou services/ não foram encontrados'
    fi

    validate_bootstrap_repo "$LEANIN_REPO" \
        || bootstrap_fail 'LEANIN_REPO inválido; use https://github.com/OWNER/REPO'
    validate_bootstrap_branch "$LEANIN_BRANCH" \
        || bootstrap_fail 'LEANIN_BRANCH inválida'
    command -v bash >/dev/null 2>&1 \
        || bootstrap_fail 'bash é necessário para executar o projeto completo'
    command -v curl >/dev/null 2>&1 \
        || bootstrap_fail 'curl é necessário para baixar o projeto completo'
    command -v tar >/dev/null 2>&1 \
        || bootstrap_fail 'tar é necessário para extrair o projeto completo'
    command -v mktemp >/dev/null 2>&1 \
        || bootstrap_fail 'mktemp é necessário para criar um diretório temporário seguro'

    repo_url=${LEANIN_REPO%/}
    repo_url=${repo_url%.git}
    archive_url="$repo_url/archive/refs/heads/$LEANIN_BRANCH.tar.gz"
    if ! temp_dir=$(mktemp -d); then
        bootstrap_fail 'não foi possível criar diretório temporário seguro'
    fi
    # Invocada indiretamente pelo trap.
    # shellcheck disable=SC2317,SC2329
    cleanup_bootstrap() {
        [[ -n $temp_dir && -d $temp_dir ]] && rm -rf -- "$temp_dir"
    }
    trap cleanup_bootstrap EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    if ! chmod 700 "$temp_dir"; then
        bootstrap_fail 'não foi possível proteger o diretório temporário'
    fi
    archive="$temp_dir/leanin.tar.gz"
    listing="$temp_dir/archive.list"
    extract_dir="$temp_dir/extract"
    (( EARLY_VERBOSE )) && printf '> [info] diretório temporário: %s\n' "$temp_dir"

    printf '> [info] baixando projeto completo\n'
    if ! curl -fsSL --retry 3 --connect-timeout 10 --max-time 120 \
        "$archive_url" -o "$archive"; then
        bootstrap_fail "falha ao baixar o tarball: $archive_url"
    fi
    if [[ ! -s $archive ]]; then
        bootstrap_fail 'tarball baixado está vazio'
    fi
    archive_size=$(wc -c <"$archive")
    if (( archive_size < 1024 )); then
        bootstrap_fail 'tarball inválido: arquivo menor que 1 KiB'
    fi

    if ! tar -tzf "$archive" >"$listing"; then
        bootstrap_fail 'tarball inválido ou corrompido'
    fi
    while IFS= read -r entry || [[ -n $entry ]]; do
        [[ -n $entry && $entry != /* ]] \
            || bootstrap_fail 'tarball contém caminho absoluto ou vazio'
        case "/$entry/" in
            */../*|*/./*) bootstrap_fail 'tarball contém caminho inseguro' ;;
        esac
        entry_root=${entry%%/*}
        [[ -n $entry_root && $entry_root != . && $entry_root != .. ]] \
            || bootstrap_fail 'tarball contém diretório raiz inválido'
        roots+=("$entry_root")
    done <"$listing"
    ((${#roots[@]} > 0)) || bootstrap_fail 'tarball não contém arquivos'
    mapfile -t roots < <(printf '%s\n' "${roots[@]}" | sort -u)
    if ((${#roots[@]} != 1)); then
        bootstrap_fail 'tarball deve conter exatamente um diretório raiz'
    fi
    root_name=${roots[0]}

    mkdir -p "$extract_dir"
    if ! tar -xzf "$archive" --no-same-owner --no-same-permissions -C "$extract_dir"; then
        bootstrap_fail 'falha ao extrair o projeto'
    fi
    [[ -d $extract_dir/$root_name && ! -L $extract_dir/$root_name ]] \
        || bootstrap_fail 'estrutura extraída inválida'
    project_root=$(cd -- "$extract_dir/$root_name" && pwd -P) \
        || bootstrap_fail 'não foi possível resolver o projeto extraído'
    [[ $project_root == "$extract_dir/"* ]] \
        || bootstrap_fail 'projeto extraído fora do diretório temporário'
    for entry in install.sh lib apps services; do
        if [[ $entry == install.sh ]]; then
            [[ -s $project_root/$entry && ! -L $project_root/$entry ]] \
                || bootstrap_fail 'install.sh ausente ou inválido no tarball'
        else
            [[ -d $project_root/$entry && ! -L $project_root/$entry ]] \
                || bootstrap_fail "diretório $entry/ ausente ou inválido no tarball"
        fi
    done

    printf '> [ok] projeto carregado em diretório temporário\n'
    set +e
    LEANIN_BOOTSTRAPPED=1 \
        LEANIN_REPO="$LEANIN_REPO" \
        LEANIN_BRANCH="$LEANIN_BRANCH" \
        bash "$project_root/install.sh" "$@"
    local status=$?
    set -e
    exit "$status"
}

if [[ $LEANIN_BOOTSTRAPPED != 1 ]]; then
    initial_banner "$EARLY_PLAN"
fi
bootstrap_project "$@"

# shellcheck source=lib/log
source "$LEANIN_ROOT/lib/log"
# shellcheck source=lib/ask
source "$LEANIN_ROOT/lib/ask"
# shellcheck source=lib/env
source "$LEANIN_ROOT/lib/env"
# shellcheck source=lib/doctor
source "$LEANIN_ROOT/lib/doctor"
# shellcheck source=lib/run
source "$LEANIN_ROOT/lib/run"
# shellcheck source=lib/apps
source "$LEANIN_ROOT/lib/apps"
# shellcheck source=lib/service
source "$LEANIN_ROOT/lib/service"
# shellcheck source=lib/pkg
source "$LEANIN_ROOT/lib/pkg"
# shellcheck source=lib/flatpak
source "$LEANIN_ROOT/lib/flatpak"
# shellcheck source=lib/aur
source "$LEANIN_ROOT/lib/aur"
# shellcheck source=lib/codex
source "$LEANIN_ROOT/lib/codex"
# shellcheck source=lib/git
source "$LEANIN_ROOT/lib/git"
# shellcheck source=lib/ssh
source "$LEANIN_ROOT/lib/ssh"
# shellcheck source=lib/gh
source "$LEANIN_ROOT/lib/gh"
# shellcheck source=lib/options
source "$LEANIN_ROOT/lib/options"
# shellcheck source=lib/control
source "$LEANIN_ROOT/lib/control"

leanin_main "$@"
