#!/usr/bin/env bash
set -Eeuo pipefail

ARCHBOOT_VERSION='0.1.1'
ARCHBOOT_REPO=${ARCHBOOT_REPO-https://github.com/ilikehercauseherpussypink/archboot}
ARCHBOOT_BRANCH=${ARCHBOOT_BRANCH-main}

initial_banner() {
    local plan_mode=${1:-0}
    printf '\narchboot %s\n' "$ARCHBOOT_VERSION"
    if (( plan_mode )); then
        printf '\n'
    else
        printf 'Bootstrap modular para Arch Linux\n'
    fi
}

EARLY_PLAN=0
EARLY_VERSION=0
EARLY_VERBOSE=0
for argument in "$@"; do
    case $argument in
        --version) EARLY_VERSION=1 ;;
        --plan) EARLY_PLAN=1 ;;
        --verbose) EARLY_VERBOSE=1 ;;
        --doctor|--dry-run|--yes|--no-packages|--no-pacman|--no-flatpak|--no-aur|\
            --no-services|--no-codex|--no-git|--no-ssh|--no-github|--help|-h) ;;
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
    printf 'archboot %s\n' "$ARCHBOOT_VERSION"
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
            ARCHBOOT_ROOT=$script_dir
            export ARCHBOOT_ROOT
            return 0
        fi
    fi

    if [[ ${ARCHBOOT_BOOTSTRAPPED:-0} == 1 ]]; then
        bootstrap_fail 'bootstrap concluído, mas lib/, apps/ ou services/ não foram encontrados'
    fi

    validate_bootstrap_repo "$ARCHBOOT_REPO" \
        || bootstrap_fail 'ARCHBOOT_REPO inválido; use https://github.com/OWNER/REPO'
    validate_bootstrap_branch "$ARCHBOOT_BRANCH" \
        || bootstrap_fail 'ARCHBOOT_BRANCH inválida'
    command -v bash >/dev/null 2>&1 \
        || bootstrap_fail 'bash é necessário para executar o projeto completo'
    command -v curl >/dev/null 2>&1 \
        || bootstrap_fail 'curl é necessário para baixar o projeto completo'
    command -v tar >/dev/null 2>&1 \
        || bootstrap_fail 'tar é necessário para extrair o projeto completo'
    command -v mktemp >/dev/null 2>&1 \
        || bootstrap_fail 'mktemp é necessário para criar um diretório temporário seguro'

    repo_url=${ARCHBOOT_REPO%/}
    repo_url=${repo_url%.git}
    archive_url="$repo_url/archive/refs/heads/$ARCHBOOT_BRANCH.tar.gz"
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
    archive="$temp_dir/archboot.tar.gz"
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
    ARCHBOOT_BOOTSTRAPPED=1 \
        ARCHBOOT_REPO="$ARCHBOOT_REPO" \
        ARCHBOOT_BRANCH="$ARCHBOOT_BRANCH" \
        bash "$project_root/install.sh" "$@"
    local status=$?
    set -e
    exit "$status"
}

if [[ ${ARCHBOOT_BOOTSTRAPPED:-0} != 1 ]]; then
    initial_banner "$EARLY_PLAN"
fi
bootstrap_project "$@"

# shellcheck source=lib/log
source "$ARCHBOOT_ROOT/lib/log"
# shellcheck source=lib/ask
source "$ARCHBOOT_ROOT/lib/ask"
# shellcheck source=lib/env
source "$ARCHBOOT_ROOT/lib/env"
# shellcheck source=lib/doctor
source "$ARCHBOOT_ROOT/lib/doctor"
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
PLAN_ONLY=0
DOCTOR_ONLY=0
ASSUME_YES=0
CI_MODE=${ARCHBOOT_CI:-0}
SKIP_PACMAN=0
SKIP_FLATPAK=0
SKIP_AUR=0
SKIP_SERVICES=0
SKIP_CODEX=0
SKIP_GIT=0
SKIP_SSH=0
SKIP_GITHUB=0
TOTAL_STEPS=0
STEP_CURRENT=0
PACMAN_BLOCKED=0
LOG_FILE=/dev/null
declare -ag FAILURES=()
declare -ag DISABLED_FEATURES=()
PLAN_LOADED=0

usage() {
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
}

parse_args() {
    while (($#)); do
        case $1 in
            --verbose) VERBOSE=1 ;;
            --dry-run) DRY_RUN=1 ;;
            --plan) PLAN_ONLY=1 ;;
            --doctor) DOCTOR_ONLY=1 ;;
            --yes) ASSUME_YES=1 ;;
            --no-packages)
                SKIP_PACMAN=1
                SKIP_FLATPAK=1
                SKIP_AUR=1
                ;;
            --no-pacman) SKIP_PACMAN=1 ;;
            --no-flatpak) SKIP_FLATPAK=1 ;;
            --no-aur) SKIP_AUR=1 ;;
            --no-services) SKIP_SERVICES=1 ;;
            --no-codex) SKIP_CODEX=1 ;;
            --no-git) SKIP_GIT=1 ;;
            --no-ssh)
                SKIP_SSH=1
                SKIP_GITHUB=1
                ;;
            --no-github) SKIP_GITHUB=1 ;;
            --version) ;;
            --help|-h) usage; exit 0 ;;
            *) die "opção desconhecida: $1" ;;
        esac
        shift
    done
}

collect_disabled_features() {
    (( SKIP_PACMAN )) && DISABLED_FEATURES+=('pacman')
    (( SKIP_FLATPAK )) && DISABLED_FEATURES+=('flatpak')
    (( SKIP_AUR )) && DISABLED_FEATURES+=('aur')
    (( SKIP_SERVICES )) && DISABLED_FEATURES+=('serviços')
    (( SKIP_CODEX )) && DISABLED_FEATURES+=('codex')
    (( SKIP_GIT )) && DISABLED_FEATURES+=('git')
    (( SKIP_SSH )) && DISABLED_FEATURES+=('ssh')
    (( SKIP_GITHUB )) && DISABLED_FEATURES+=('github')
    return 0
}

plan_status() {
    local disabled=$1
    (( disabled )) && printf 'disabled' || printf 'enabled'
}

show_plan_only() {
    local key item
    load_plan

    printf 'plan\n\n'
    if (( SKIP_PACMAN )); then
        printf 'pacman: disabled (%s configurados)\n' "$(count_apps pacman)"
    else
        printf 'pacman: %s pacotes\n' "$(count_apps pacman)"
    fi
    if (( SKIP_FLATPAK )); then
        printf 'flatpak: disabled (%s configurados)\n' "$(count_apps flatpak)"
    else
        printf 'flatpak: %s apps\n' "$(count_apps flatpak)"
    fi
    if (( SKIP_AUR )); then
        printf 'aur: disabled (%s configurados)\n' "$(count_apps aur)"
    else
        printf 'aur: %s pacotes\n' "$(count_apps aur)"
    fi
    if (( SKIP_SERVICES )); then
        printf 'system services: disabled (%s configurados)\n' "${#SYSTEM_SERVICES[@]}"
        printf 'user services: disabled (%s configurados)\n' "${#USER_SERVICES[@]}"
    else
        if ((${#SYSTEM_SERVICES[@]} == 1)); then
            printf 'system services: 1 serviço\n'
        else
            printf 'system services: %s serviços\n' "${#SYSTEM_SERVICES[@]}"
        fi
        if ((${#USER_SERVICES[@]} == 1)); then
            printf 'user services: 1 serviço\n'
        else
            printf 'user services: %s serviços\n' "${#USER_SERVICES[@]}"
        fi
    fi
    printf 'codex: %s\n' "$(plan_status "$SKIP_CODEX")"
    printf 'git: %s\n' "$(plan_status "$SKIP_GIT")"
    if (( SKIP_SSH || SKIP_GITHUB )); then
        printf 'ssh/github: ssh=%s github=%s\n' \
            "$(plan_status "$SKIP_SSH")" "$(plan_status "$SKIP_GITHUB")"
    else
        printf 'ssh/github: enabled\n'
    fi

    if (( VERBOSE )); then
        printf '\ncategories\n'
        while IFS= read -r key; do
            [[ -n $key ]] && printf '%s: %s\n' "$key" "${APP_COUNTS[$key]}"
        done < <(printf '%s\n' "${!APP_COUNTS[@]}" | sort)
        printf '\napps\n'
        for item in "${PACMAN_APPS[@]}"; do printf 'pacman: %s\n' "$item"; done
        for item in "${FLATPAK_APPS[@]}"; do printf 'flatpak: %s\n' "$item"; done
        for item in "${AUR_APPS[@]}"; do printf 'aur: %s\n' "$item"; done
        for item in "${SYSTEM_SERVICES[@]}"; do printf 'system service: %s\n' "$item"; done
        for item in "${USER_SERVICES[@]}"; do printf 'user service: %s\n' "$item"; done
    fi
}

load_plan() {
    (( PLAN_LOADED )) && return 0
    read_pacman
    read_flatpak
    read_aur
    read_services
    PLAN_LOADED=1
}

calculate_total_steps() {
    TOTAL_STEPS=3 # sistema, plano e resumo
    if (( ! SKIP_PACMAN && ${#PACMAN_CORE[@]} > 0 )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_FLATPAK )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_PACMAN && ${#PACMAN_REST[@]} > 0 )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_AUR && ${#AUR_APPS[@]} > 0 )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_SERVICES && (${#SYSTEM_SERVICES[@]} + ${#USER_SERVICES[@]} > 0) )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_CODEX )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_GIT )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_SSH )); then
        ((TOTAL_STEPS += 1))
    fi
    if (( ! SKIP_GITHUB )); then
        ((TOTAL_STEPS += 1))
    fi
}

next_step() {
    ((STEP_CURRENT += 1))
    step "$STEP_CURRENT" "$TOTAL_STEPS" "$1"
}

print_disabled_plan() {
    (( SKIP_PACMAN )) && skip 'pacman desativado por flag'
    (( SKIP_FLATPAK )) && skip 'Flatpak desativado por flag'
    (( SKIP_AUR )) && skip 'AUR desativado por flag'
    (( SKIP_SERVICES )) && skip 'serviços desativados por flag'
    (( SKIP_CODEX )) && skip 'Codex desativado por flag'
    (( SKIP_GIT )) && skip 'Git desativado por flag'
    (( SKIP_SSH )) && skip 'SSH desativado por flag'
    (( SKIP_GITHUB )) && skip 'GitHub desativado por flag'
    return 0
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

count_failures() {
    local prefix=$1 failure count=0
    for failure in "${FAILURES[@]}"; do
        [[ $failure == "$prefix"* ]] && ((count += 1))
    done
    printf '%s' "$count"
}

summary_counts() {
    local label=$1 action_count=$2 action_label=$3 skipped_count=$4 failure_prefix=$5
    local failed_count line
    failed_count=$(count_failures "$failure_prefix")
    line="$label: $action_count $action_label, $skipped_count pulados"
    (( failed_count > 0 )) && line+=", $failed_count falhas"
    info "$line"
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

    printf '\n> Pacotes:\n'
    if (( DRY_RUN )); then
        summary_counts pacman "${#PACMAN_PLANNED[@]}" planejados "${#PACMAN_SKIPPED[@]}" 'pacman:'
        summary_counts flatpak "${#FLATPAK_PLANNED[@]}" planejados "${#FLATPAK_SKIPPED[@]}" 'flatpak:'
        summary_counts aur "${#AUR_PLANNED[@]}" planejados "${#AUR_SKIPPED[@]}" 'aur:'
    else
        summary_counts pacman "${#PACMAN_INSTALLED[@]}" instalados "${#PACMAN_SKIPPED[@]}" 'pacman:'
        summary_counts flatpak "${#FLATPAK_INSTALLED[@]}" instalados "${#FLATPAK_SKIPPED[@]}" 'flatpak:'
        summary_counts aur "${#AUR_INSTALLED[@]}" instalados "${#AUR_SKIPPED[@]}" 'aur:'
    fi

    printf '\n> Configuração:\n'
    if (( DRY_RUN )); then
        summary_counts serviços "${#SERVICES_PLANNED[@]}" planejados \
            "$((${#SERVICES_ALREADY[@]} + ${#SERVICES_SKIPPED[@]}))" 'service:'
    else
        summary_counts serviços "$((${#SERVICES_ACTIVATED[@]} + ${#SERVICES_ALREADY[@]}))" ativos \
            "${#SERVICES_SKIPPED[@]}" 'service:'
    fi
    if (( SKIP_GITHUB )); then
        info 'GitHub SSH: desativado por flag'
    else
        info "GitHub SSH: ${GITHUB_NEW_KEY_STATUS:-fallback manual}"
    fi
    if (( SKIP_CODEX )); then
        info 'Codex: desativado por flag'
    else
        codex_command=$(command -v codex 2>/dev/null || true)
        if [[ -n $codex_command && $codex_command != "$expected_codex" ]]; then
            warn 'Codex encontrado fora de ~/.codex. Abra novo terminal ou revise PATH antigo.'
        fi
        info "Codex: ${codex_command:-não encontrado}"
    fi

    if (( failure_count > 0 )); then
        summary_line 'falhas' "${FAILURES[@]}"
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

    if ((${#DISABLED_FEATURES[@]})); then
        summary_line 'desativados por flag' "${DISABLED_FEATURES[@]}"
    fi

    if [[ $LOG_FILE != /dev/null ]]; then
        printf '\n> Logs:\n'
        if (( failure_count > 0 )); then
            info "veja log: $LOG_FILE"
        else
            info "$LOG_FILE"
        fi
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
    local ssh_ready=0

    parse_args "$@"
    collect_disabled_features

    if [[ $CI_MODE != 0 && $CI_MODE != 1 ]]; then
        die 'ARCHBOOT_CI deve ser 0 ou 1'
    fi
    if [[ $CI_MODE == 1 && $DRY_RUN != 1 && $PLAN_ONLY != 1 && $DOCTOR_ONLY != 1 ]]; then
        die 'ARCHBOOT_CI=1 exige --dry-run, --plan ou --doctor'
    fi
    if (( DOCTOR_ONLY )); then
        doctor_run
        return $?
    fi
    if (( PLAN_ONLY )); then
        show_plan_only
        return 0
    fi

    load_plan
    calculate_total_steps

    next_step 'validando sistema'
    if [[ $CI_MODE == 1 ]]; then
        LOG_FILE=/dev/null
        PACMAN_BLOCKED=0
        ok 'modo CI dry-run'
    else
        arch || die 'este instalador suporta apenas Arch Linux'
        ok 'Arch Linux detectado'
        root && die 'não execute o archboot como root'
        ok 'execução como usuário comum'
        sudo
        ok 'sudo disponível'
        net
        ok 'internet disponível'
        lock
        state
        ok "log criado: $LOG_FILE"
    fi

    next_step 'lendo plano'
    if ! validate_apps; then
        warn 'há entradas com formato improvável; a instalação continuará'
    fi
    print_plan
    print_services_plan
    print_disabled_plan

    if (( ! SKIP_PACMAN && ${#PACMAN_CORE[@]} > 0 )); then
        next_step 'pacman essenciais'
        pacman_install "${PACMAN_CORE[@]}"
    fi

    if (( ! SKIP_FLATPAK )); then
        next_step 'Flatpak'
        flatpak_setup || true
        flatpak_install "${FLATPAK_APPS[@]}"
    fi

    if (( ! SKIP_PACMAN && ${#PACMAN_REST[@]} > 0 )); then
        next_step 'pacman restantes'
        pacman_install "${PACMAN_REST[@]}"
    fi

    if (( ! SKIP_AUR && ${#AUR_APPS[@]} > 0 )); then
        next_step 'AUR'
        if (( PACMAN_BLOCKED )); then
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
    fi

    if (( ! SKIP_SERVICES && (${#SYSTEM_SERVICES[@]} + ${#USER_SERVICES[@]} > 0) )); then
        next_step 'serviços'
        activate_services
    fi

    if (( ! SKIP_CODEX )); then
        next_step 'Codex'
        if configure_prefix; then
            install_codex || true
            configure_path
        else
            skip 'PATH do Codex não foi alterado'
        fi
    fi

    if (( ! SKIP_GIT )); then
        next_step 'Git'
        configure_git || true
    fi

    if (( ! SKIP_SSH )); then
        next_step 'SSH'
        if configure_ssh; then
            ssh_ready=1
        fi
    fi

    if (( ! SKIP_GITHUB )); then
        next_step 'GitHub'
        if (( ssh_ready )); then
            github_manage_ssh_key "$SSH_PUBLIC_KEY"
            test_github_ssh || true
        else
            skip 'GitHub SSH pulado: chave local indisponível'
            configure_gh || true
        fi
    fi

    next_step 'resumo'
    show_summary
    ((${#FAILURES[@]} == 0))
}

main "$@"
