#!/usr/bin/env bash
set -Eeuo pipefail

ARCHBOOT_REPO=${ARCHBOOT_REPO:-https://github.com/ilikehercauseherpussypink/archboot}
ARCHBOOT_BRANCH=${ARCHBOOT_BRANCH:-main}

initial_banner() {
    printf '\narchboot\n'
    printf 'Bootstrap modular para Arch Linux\n\n'
}

bootstrap_project() {
    local script_path script_dir repo_url archive_url temp_dir archive

    script_path=${BASH_SOURCE[0]:-}
    if [[ -n $script_path && -f $script_path ]]; then
        script_dir=$(cd -- "$(dirname -- "$script_path")" && pwd)
        if [[ -d $script_dir/lib && -d $script_dir/apps && -d $script_dir/services ]]; then
            ARCHBOOT_ROOT=$script_dir
            export ARCHBOOT_ROOT
            return 0
        fi
    fi

    if [[ ${ARCHBOOT_BOOTSTRAPPED:-0} == 1 ]]; then
        printf '> [error] bootstrap concluído, mas lib/, apps/ ou services/ não foram encontrados\n' >&2
        exit 1
    fi
    command -v curl >/dev/null 2>&1 || {
        printf '> [error] curl é necessário para baixar o projeto completo\n' >&2
        exit 1
    }
    command -v tar >/dev/null 2>&1 || {
        printf '> [error] tar é necessário para extrair o projeto completo\n' >&2
        exit 1
    }

    repo_url=${ARCHBOOT_REPO%/}
    repo_url=${repo_url%.git}
    archive_url="$repo_url/archive/refs/heads/$ARCHBOOT_BRANCH.tar.gz"
    temp_dir=$(mktemp -d)
    chmod 700 "$temp_dir"
    archive="$temp_dir/archboot.tar.gz"

    # shellcheck disable=SC2329
    cleanup_bootstrap() {
        rm -rf -- "$temp_dir"
    }
    trap cleanup_bootstrap EXIT INT TERM

    printf '> [info] baixando projeto completo\n'
    if ! curl -fsSL "$archive_url" -o "$archive"; then
        printf '> [error] falha ao baixar: %s\n' "$archive_url" >&2
        exit 1
    fi
    mkdir -p "$temp_dir/project"
    if ! tar -xzf "$archive" --strip-components=1 -C "$temp_dir/project"; then
        printf '> [error] falha ao extrair o projeto\n' >&2
        exit 1
    fi
    if [[ ! -f $temp_dir/project/install.sh ]]; then
        printf '> [error] install.sh não encontrado no tarball\n' >&2
        exit 1
    fi

    printf '> [ok] projeto carregado em diretório temporário\n'
    set +e
    ARCHBOOT_BOOTSTRAPPED=1 \
        ARCHBOOT_REPO="$ARCHBOOT_REPO" \
        ARCHBOOT_BRANCH="$ARCHBOOT_BRANCH" \
        bash "$temp_dir/project/install.sh" "$@"
    local status=$?
    set -e
    exit "$status"
}

if [[ ${ARCHBOOT_BOOTSTRAPPED:-0} != 1 ]]; then
    initial_banner
fi
bootstrap_project "$@"

# shellcheck source=lib/log
source "$ARCHBOOT_ROOT/lib/log"
# shellcheck source=lib/ask
source "$ARCHBOOT_ROOT/lib/ask"
# shellcheck source=lib/env
source "$ARCHBOOT_ROOT/lib/env"
# shellcheck source=lib/run
source "$ARCHBOOT_ROOT/lib/run"
# shellcheck source=lib/apps
source "$ARCHBOOT_ROOT/lib/apps"
# shellcheck source=lib/service
source "$ARCHBOOT_ROOT/lib/service"
# shellcheck source=lib/pkg
source "$ARCHBOOT_ROOT/lib/pkg"
# shellcheck source=lib/flatpak
source "$ARCHBOOT_ROOT/lib/flatpak"
# shellcheck source=lib/aur
source "$ARCHBOOT_ROOT/lib/aur"
# shellcheck source=lib/codex
source "$ARCHBOOT_ROOT/lib/codex"
# shellcheck source=lib/git
source "$ARCHBOOT_ROOT/lib/git"
# shellcheck source=lib/open
source "$ARCHBOOT_ROOT/lib/open"
# shellcheck source=lib/ssh
source "$ARCHBOOT_ROOT/lib/ssh"
# shellcheck source=lib/gh
source "$ARCHBOOT_ROOT/lib/gh"

VERBOSE=0
DRY_RUN=0
TOTAL_STEPS=13
PACMAN_BLOCKED=0
LOG_FILE=/dev/null
declare -ag FAILURES=()
declare -ag VALIDATION_FAILURES=() CONFIGS_PLANNED=()

usage() {
    cat <<'EOF'
Uso: bash install.sh [opções]

  --verbose   mostra comandos e saída completa
  --dry-run   mostra o plano sem alterar o sistema
  --help      mostra esta ajuda
EOF
}

parse_args() {
    while (($#)); do
        case $1 in
            --verbose) VERBOSE=1 ;;
            --dry-run) DRY_RUN=1 ;;
            --help|-h) usage; exit 0 ;;
            *) die "opção desconhecida: $1" ;;
        esac
        shift
    done
}

summary_line() {
    local label=$1
    shift
    local joined='' item
    if (($#)); then
        for item in "$@"; do
            [[ -n $joined ]] && joined+=', '
            joined+=$item
        done
        printf '> [info] %s: %s\n' "$label" "$joined"
    else
        printf '> [info] %s: nenhum\n' "$label"
    fi
}

log_list() {
    local label=$1
    shift
    local item
    for item in "$@"; do
        printf '%s: %s\n' "$label" "$item" >>"$LOG_FILE"
    done
}

has_failure() {
    local expected=$1 failure
    for failure in "${FAILURES[@]}"; do
        [[ $failure == "$expected" ]] && return 0
    done
    return 1
}

show_summary() {
    local codex_command='' expected_codex="$HOME/.codex/bin/codex"
    local failure_count=${#FAILURES[@]}

    log_list 'pacman installed' "${PACMAN_INSTALLED[@]}"
    log_list 'pacman skipped' "${PACMAN_SKIPPED[@]}"
    log_list 'flatpak installed' "${FLATPAK_INSTALLED[@]}"
    log_list 'flatpak skipped' "${FLATPAK_SKIPPED[@]}"
    log_list 'AUR installed' "${AUR_INSTALLED[@]}"
    log_list 'AUR skipped' "${AUR_SKIPPED[@]}"
    log_list 'service activated' "${SERVICES_ACTIVATED[@]}"
    log_list 'service already active' "${SERVICES_ALREADY[@]}"
    log_list 'service skipped' "${SERVICES_SKIPPED[@]}"
    log_list 'failure' "${FAILURES[@]}"

    if (( failure_count == 0 )); then
        ok 'concluído'
    else
        warn "concluído com $failure_count falha(s)"
    fi

    if (( DRY_RUN )); then
        info "pacman: ${#PACMAN_PLANNED[@]} planejados, ${#PACMAN_SKIPPED[@]} pulados"
        info "flatpak: ${#FLATPAK_PLANNED[@]} planejados, ${#FLATPAK_SKIPPED[@]} pulados"
        info "aur: ${#AUR_PLANNED[@]} planejados, ${#AUR_SKIPPED[@]} pulados"
        info "serviços: ${#SERVICES_PLANNED[@]} planejados, ${#SERVICES_ALREADY[@]} ativos, ${#SERVICES_SKIPPED[@]} pulados"
    else
        info "pacman: ${#PACMAN_INSTALLED[@]} instalados, ${#PACMAN_SKIPPED[@]} pulados"
        info "flatpak: ${#FLATPAK_INSTALLED[@]} instalados, ${#FLATPAK_SKIPPED[@]} pulados"
        info "aur: ${#AUR_INSTALLED[@]} instalados, ${#AUR_SKIPPED[@]} pulados"
        info "serviços: $((${#SERVICES_ACTIVATED[@]} + ${#SERVICES_ALREADY[@]})) ativos, ${#SERVICES_SKIPPED[@]} pulados"
    fi

    info "GitHub SSH: ${GITHUB_NEW_KEY_STATUS:-fallback manual}"
    codex_command=$(command -v codex 2>/dev/null || true)
    if [[ -n $codex_command && $codex_command != "$expected_codex" ]]; then
        warn 'Codex encontrado fora de ~/.codex. Abra novo terminal ou revise PATH antigo.'
    fi
    info "Codex: ${codex_command:-não encontrado}"

    if (( failure_count > 0 )); then
        summary_line 'falhas' "${FAILURES[@]}"
        info "veja log: $LOG_FILE"
    else
        info "log: $LOG_FILE"
    fi

    if (( VERBOSE )); then
        summary_line 'pacman instalados' "${PACMAN_INSTALLED[@]}"
        summary_line 'pacman pulados' "${PACMAN_SKIPPED[@]}"
        summary_line 'Flatpak instalados' "${FLATPAK_INSTALLED[@]}"
        summary_line 'Flatpak pulados' "${FLATPAK_SKIPPED[@]}"
        summary_line 'AUR instalados' "${AUR_INSTALLED[@]}"
        summary_line 'AUR pulados' "${AUR_SKIPPED[@]}"
        summary_line 'serviços ativados' "${SERVICES_ACTIVATED[@]}"
        summary_line 'serviços já ativos' "${SERVICES_ALREADY[@]}"
        summary_line 'serviços pulados' "${SERVICES_SKIPPED[@]}"
        info "Git: ${GIT_NAME:-não configurado} <${GIT_EMAIL:-não configurado}>"
        info "chave SSH pública: ${SSH_PUBLIC_KEY:-não configurada}"
        info "GitHub SSH keys antigas: ${GITHUB_OLD_KEYS_STATUS:-não verificadas}"
        info "título GitHub SSH key: ${GITHUB_KEY_TITLE:-person}"
        info "teste SSH GitHub: ${SSH_GITHUB_RESULT:-não testado}"
    fi

    if [[ ${GITHUB_NEW_KEY_STATUS:-} == 'fallback manual' ]]; then
        info "próximo passo: cadastre a chave em $GITHUB_KEYS_URL"
    fi
    if (( CODEX_PATH_CHANGED )); then
        info 'próximo passo: abra um novo terminal para ativar o PATH do Codex'
    fi
    if has_failure 'aur:wootility'; then
        info 'próximo passo: consulte as regras udev da Wootility no README'
    fi
}

main() {
    parse_args "$@"

    step 1 "$TOTAL_STEPS" 'validando sistema'
    arch || die 'este instalador suporta apenas Arch Linux'
    ok 'Arch Linux detectado'
    root && die 'não execute o archboot como root'
    ok 'execução como usuário comum'
    sudo
    ok 'sudo disponível'
    net
    ok 'internet disponível'
    state
    ok "log criado: $LOG_FILE"
    lock

    step 2 "$TOTAL_STEPS" 'lendo plano'
    read_pacman
    read_flatpak
    read_aur
    read_services
    if ! validate_apps; then
        warn 'há entradas com formato improvável; a instalação continuará'
        VALIDATION_FAILURES+=('formato de apps')
    fi
    print_plan
    print_services_plan

    step 3 "$TOTAL_STEPS" 'instalando pacotes oficiais essenciais'
    pacman_install "${PACMAN_CORE[@]}"

    step 4 "$TOTAL_STEPS" 'configurando Flatpak'
    flatpak_setup || true

    step 5 "$TOTAL_STEPS" 'instalando pacotes oficiais restantes'
    pacman_install "${PACMAN_REST[@]}"

    step 6 "$TOTAL_STEPS" 'instalando Flatpaks'
    flatpak_install "${FLATPAK_APPS[@]}"

    step 7 "$TOTAL_STEPS" 'instalando pacotes AUR'
    if ((${#AUR_APPS[@]} == 0)); then
        skip 'nenhum pacote AUR configurado'
    elif (( PACMAN_BLOCKED )); then
        install "${AUR_APPS[@]}"
    elif ! detect; then
        if yesno 'Nenhum AUR helper encontrado. Instalar paru?' n; then
            bootstrap_paru || true
        else
            skip 'instalação de AUR helper recusada'
        fi
        install "${AUR_APPS[@]}"
    else
        install "${AUR_APPS[@]}"
    fi

    step 8 "$TOTAL_STEPS" 'ativando serviços'
    activate_services

    step 9 "$TOTAL_STEPS" 'configurando Codex CLI'
    if configure_prefix; then
        install_codex || true
    fi
    configure_path

    step 10 "$TOTAL_STEPS" 'configurando Git'
    configure_git || true

    step 11 "$TOTAL_STEPS" 'ssh/github'
    if configure_ssh; then
        github_manage_ssh_key "$SSH_PUBLIC_KEY"
        test_github_ssh || true
    fi

    step 12 "$TOTAL_STEPS" 'finalizando integrações'
    configure_gh || true

    step 13 "$TOTAL_STEPS" 'resumo'
    show_summary
}

main "$@"
