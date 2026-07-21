#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
COMMAND_DIR="${ROOT_DIR}/src/bin"
COMPLETION_SOURCE="${ROOT_DIR}/completions/clipboard-utils.bash"
CONFIG_DIR="${CLIPBOARD_UTILS_CONFIG_DIR:-${XDG_CONFIG_HOME:-${HOME}/.config}/clipboard-utils}"
CONFIG_FILE="${CLIPBOARD_UTILS_CONFIG_FILE:-${CONFIG_DIR}/config}"
BIN_DIR="${CLIPBOARD_UTILS_BIN_DIR:-${HOME}/.local/bin}"
COMPLETION_DIR="${CLIPBOARD_UTILS_COMPLETION_DIR:-${XDG_DATA_HOME:-${HOME}/.local/share}/bash-completion/completions}"
CHECK_ONLY=0
UNINSTALL=0

COMMANDS=(
  co
  coc
  cof
  cob
  cowd
  cor
  hclip-secret
  hclip-service
  hclip-start
  hclip-stop
  hclip-status
  hclip-tunnel
  hclip-tunnel-service
)

REMOVED_COMMANDS=(
  c
  cobf
  cpwd
  copy-xclip
  copy-hclip
  hclip-handle-connection
)

INTERNAL_FILES=(
  hclip-handle-connection
)

usage() {
  cat <<USAGE
Usage: ./install.sh [options]

Options:
  --check, check, doctor    Check dependencies and install state only.
  uninstall, --uninstall    Remove installed command symlinks.
  -h, --help                Show this help.

Environment:
  CLIPBOARD_UTILS_BIN_DIR       Command install directory. Defaults to ~/.local/bin.
  CLIPBOARD_UTILS_COMPLETION_DIR Bash completion directory. Defaults to ~/.local/share/bash-completion/completions.
  CLIPBOARD_UTILS_CONFIG_DIR    Config directory. Defaults to ~/.config/clipboard-utils.
  CLIPBOARD_UTILS_CONFIG_FILE   Config file. Defaults to \$CLIPBOARD_UTILS_CONFIG_DIR/config.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check|check|doctor)
      CHECK_ONLY=1
      shift
      ;;
    uninstall|--uninstall)
      UNINSTALL=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REQUIRED_MISSING=0
WARNINGS=0

report_ok() {
  printf '  [ok]   %s\n' "$1"
}

report_warn() {
  printf '  [warn] %s\n' "$1"
  WARNINGS=$((WARNINGS + 1))
}

report_fail() {
  printf '  [miss] %s\n' "$1"
  REQUIRED_MISSING=$((REQUIRED_MISSING + 1))
}

command_status() {
  local command_name="$1"
  local label="$2"

  if command -v "${command_name}" >/dev/null 2>&1; then
    report_ok "${label}: $(command -v "${command_name}")"
  else
    report_warn "${label}: ${command_name} not found"
  fi
}

check_project_files() {
  local command_name
  local source_path
  local missing_commands=0
  local missing_internal=0

  echo "Project files"
  for command_name in "${COMMANDS[@]}"; do
    source_path="${COMMAND_DIR}/${command_name}"
    if [[ -x "${source_path}" ]]; then
      continue
    elif [[ -f "${source_path}" ]]; then
      report_fail "${command_name} exists but is not executable"
      missing_commands=$((missing_commands + 1))
    else
      report_fail "${command_name} is missing"
      missing_commands=$((missing_commands + 1))
    fi
  done

  if [[ "${missing_commands}" -eq 0 ]]; then
    report_ok "command sources found: ${COMMAND_DIR}"
  fi

  for command_name in "${INTERNAL_FILES[@]}"; do
    source_path="${ROOT_DIR}/src/libexec/${command_name}"
    if [[ -x "${source_path}" ]]; then
      continue
    elif [[ -f "${source_path}" ]]; then
      report_fail "internal ${command_name} exists but is not executable"
      missing_internal=$((missing_internal + 1))
    else
      report_fail "internal ${command_name} is missing"
      missing_internal=$((missing_internal + 1))
    fi
  done

  if [[ "${missing_internal}" -eq 0 ]]; then
    report_ok "internal helpers found: ${ROOT_DIR}/src/libexec"
  fi

  if [[ -f "${COMPLETION_SOURCE}" ]]; then
    report_ok "bash completion source found"
  else
    report_fail "bash completion source is missing"
  fi
}

check_config() {
  echo "Config"

  if [[ -d "${CONFIG_DIR}" ]]; then
    report_ok "config directory exists: ${CONFIG_DIR}"
  else
    report_warn "config directory does not exist yet: ${CONFIG_DIR}"
  fi

  if [[ -f "${CONFIG_FILE}" ]]; then
    report_ok "config file exists: ${CONFIG_FILE}"
  else
    report_warn "config file does not exist yet: ${CONFIG_FILE}"
  fi
}

check_commands() {
  echo "System commands"
  command_status bash "Bash"
  command_status xclip "xclip backend"
  command_status wl-copy "wl-copy backend"
  command_status xsel "xsel backend"
  command_status socat "hclip server"
  command_status openssl "hclip secret generation"
  command_status systemctl "hclip user service"
  command_status ssh "hclip SSH tunnel"
}

check_install_links() {
  local command_name
  local installed_path
  local source_path
  local legacy_source_path
  local completion_path

  echo "Installed commands"
  for command_name in "${COMMANDS[@]}"; do
    installed_path="${BIN_DIR}/${command_name}"
    source_path="${COMMAND_DIR}/${command_name}"
    legacy_source_path="${ROOT_DIR}/${command_name}"
    if [[ -L "${installed_path}" && "$(readlink -- "${installed_path}")" == "${source_path}" ]]; then
      report_ok "${command_name} -> ${source_path}"
    elif [[ -L "${installed_path}" && "$(readlink -- "${installed_path}")" == "${legacy_source_path}" ]]; then
      report_warn "${command_name} points at old root script path"
    elif [[ -e "${installed_path}" ]]; then
      report_warn "${installed_path} exists but is not managed by this install"
    else
      report_warn "${command_name} is not installed in ${BIN_DIR}"
    fi

    completion_path="${COMPLETION_DIR}/${command_name}"
    if [[ -L "${completion_path}" && "$(readlink -- "${completion_path}")" == "${COMPLETION_SOURCE}" ]]; then
      continue
    elif [[ -e "${completion_path}" ]]; then
      report_warn "${completion_path} exists but is not managed by this install"
    else
      report_warn "${command_name} completion is not installed in ${COMPLETION_DIR}"
    fi
  done

  for command_name in "${REMOVED_COMMANDS[@]}"; do
    installed_path="${BIN_DIR}/${command_name}"
    legacy_source_path="${ROOT_DIR}/${command_name}"
    if [[ -L "${installed_path}" ]]; then
      case "$(readlink -- "${installed_path}")" in
        "${COMMAND_DIR}/${command_name}"|"${legacy_source_path}")
          report_warn "${command_name} is an old managed command and can be removed by reinstalling"
          ;;
      esac
    fi
  done
}

check_path() {
  echo "PATH"
  case ":${PATH}:" in
    *":${BIN_DIR}:"*)
      report_ok "${BIN_DIR} is on PATH"
      ;;
    *)
      report_warn "${BIN_DIR} is not on PATH"
      ;;
  esac
}

run_dependency_report() {
  REQUIRED_MISSING=0
  WARNINGS=0

  echo "clipboard-utils dependency check"
  echo "Repository: ${ROOT_DIR}"
  echo "Commands: ${COMMAND_DIR}"
  echo "Command directory: ${BIN_DIR}"
  echo "Completion directory: ${COMPLETION_DIR}"
  echo "Config file: ${CONFIG_FILE}"
  echo

  check_project_files
  echo
  check_config
  echo
  check_commands
  echo
  check_install_links
  echo
  check_path
  echo

  if [[ "${REQUIRED_MISSING}" -eq 0 ]]; then
    echo "Required files: ok"
  else
    echo "Required files missing: ${REQUIRED_MISSING}"
  fi

  if [[ "${WARNINGS}" -gt 0 ]]; then
    echo "Warnings: ${WARNINGS}"
  fi

  return "${REQUIRED_MISSING}"
}

install_config_file() {
  mkdir -p "${CONFIG_DIR}"

  if [[ -f "${CONFIG_FILE}" ]]; then
    return 0
  fi

  umask 077
  cat >"${CONFIG_FILE}" <<CONFIG
# clipboard-utils config
# CLIPBOARD_BACKEND can be: local, xclip, wl-copy, xsel, hclip
CLIPBOARD_BACKEND=local

# Required only when CLIPBOARD_BACKEND=hclip
HCLIP_HOST=
HCLIP_PORT=23143
HCLIP_SECRET=
CONFIG
}

install_commands() {
  local command_name
  local installed_path
  local source_path
  local completion_path

  mkdir -p "${BIN_DIR}"
  mkdir -p "${COMPLETION_DIR}"
  remove_old_commands

  for command_name in "${COMMANDS[@]}"; do
    installed_path="${BIN_DIR}/${command_name}"
    source_path="${COMMAND_DIR}/${command_name}"
    if [[ -e "${installed_path}" && ! -L "${installed_path}" ]]; then
      echo "Refusing to replace non-symlink: ${installed_path}" >&2
      return 1
    fi
    ln -sfn "${source_path}" "${installed_path}"

    completion_path="${COMPLETION_DIR}/${command_name}"
    if [[ -e "${completion_path}" && ! -L "${completion_path}" ]]; then
      echo "Refusing to replace non-symlink: ${completion_path}" >&2
      return 1
    fi
    ln -sfn "${COMPLETION_SOURCE}" "${completion_path}"
  done
}

remove_old_commands() {
  local command_name
  local installed_path
  local legacy_source_path

  for command_name in "${REMOVED_COMMANDS[@]}"; do
    installed_path="${BIN_DIR}/${command_name}"
    legacy_source_path="${ROOT_DIR}/${command_name}"
    if [[ ! -L "${installed_path}" ]]; then
      continue
    fi
    case "$(readlink -- "${installed_path}")" in
      "${COMMAND_DIR}/${command_name}"|"${legacy_source_path}")
        rm -f "${installed_path}"
        echo "Removed old command ${installed_path}"
        ;;
    esac
  done
}

perform_uninstall() {
  local command_name
  local installed_path
  local source_path
  local legacy_source_path
  local completion_path

  for command_name in "${COMMANDS[@]}"; do
    installed_path="${BIN_DIR}/${command_name}"
    source_path="${COMMAND_DIR}/${command_name}"
    legacy_source_path="${ROOT_DIR}/${command_name}"
    if [[ -L "${installed_path}" && "$(readlink -- "${installed_path}")" == "${source_path}" ]]; then
      rm -f "${installed_path}"
      echo "Removed ${installed_path}"
    elif [[ -L "${installed_path}" && "$(readlink -- "${installed_path}")" == "${legacy_source_path}" ]]; then
      rm -f "${installed_path}"
      echo "Removed ${installed_path}"
    fi

    completion_path="${COMPLETION_DIR}/${command_name}"
    if [[ -L "${completion_path}" && "$(readlink -- "${completion_path}")" == "${COMPLETION_SOURCE}" ]]; then
      rm -f "${completion_path}"
      echo "Removed ${completion_path}"
    fi
  done

  remove_old_commands
}

if [[ "${UNINSTALL}" -eq 1 ]]; then
  perform_uninstall
  exit 0
fi

if [[ "${CHECK_ONLY}" -eq 1 ]]; then
  run_dependency_report
  exit $?
fi

install_config_file
install_commands

echo
if run_dependency_report; then
  echo
  echo "Install complete."
  echo "Config: ${CONFIG_FILE}"
  echo "Try:"
  echo "  co config show"
  echo "  co config backend local"
  echo "  printf hello | co"
else
  echo
  echo "Install finished, but checks still found missing required files." >&2
  exit 1
fi
