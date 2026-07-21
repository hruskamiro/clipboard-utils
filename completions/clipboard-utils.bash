# bash completion for clipboard-utils

_clipboard_utils_complete_words() {
  local cur="$1"
  shift
  COMPREPLY=( $(compgen -W "$*" -- "${cur}") )
}

_clipboard_utils_co() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "${COMP_CWORD}" in
    1)
      _clipboard_utils_complete_words "${cur}" "config remote --print-config -h --help"
      return
      ;;
  esac

  case "${COMP_WORDS[1]}" in
    config)
      case "${COMP_CWORD}" in
        2)
          _clipboard_utils_complete_words "${cur}" "show path backend hclip help"
          ;;
        3)
          if [[ "${COMP_WORDS[2]}" == "backend" ]]; then
            _clipboard_utils_complete_words "${cur}" "local xclip wl-copy xsel hclip"
          fi
          ;;
      esac
      ;;
    remote)
      case "${COMP_CWORD}" in
        2)
          _clipboard_utils_complete_words "${cur}" "export import help"
          ;;
        *)
          if [[ "${COMP_WORDS[2]}" == "export" ]]; then
            case "${prev}" in
              --ssh)
                COMPREPLY=()
                ;;
              *)
                _clipboard_utils_complete_words "${cur}" "--host-select --ssh --ssh-select"
                ;;
            esac
          fi
          ;;
      esac
      ;;
  esac
}

_clipboard_utils_coc() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  case "${cur}" in
    -*)
      _clipboard_utils_complete_words "${cur}" "-f --full -h --help"
      ;;
    *)
      COMPREPLY=()
      ;;
  esac
}

_clipboard_utils_cor() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "${COMP_CWORD}" -eq 1 && "${cur}" == -* ]]; then
    _clipboard_utils_complete_words "${cur}" "-f --full -h --help"
  else
    COMPREPLY=( $(compgen -c -- "${cur}") )
  fi
}

_clipboard_utils_hclip_secret() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    _clipboard_utils_complete_words "${cur}" "generate rotate show path -h --help help"
  fi
}

_clipboard_utils_hclip_service() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  case "${COMP_CWORD}" in
    1)
      _clipboard_utils_complete_words "${cur}" "install uninstall start stop restart status enable disable daemon-reload -h --help help"
      ;;
    *)
      if [[ "${COMP_WORDS[1]}" == "install" && "${prev}" != "--bind" ]]; then
        _clipboard_utils_complete_words "${cur}" "--bind"
      fi
      ;;
  esac
}

_clipboard_utils_hclip_start() {
  local cur="${COMP_WORDS[COMP_CWORD]}"
  local prev="${COMP_WORDS[COMP_CWORD-1]}"

  if [[ "${prev}" != "--bind" && "${cur}" == -* ]]; then
    _clipboard_utils_complete_words "${cur}" "--bind --foreground -h --help"
  fi
}

_clipboard_utils_hclip_tunnel() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  case "${COMP_CWORD}" in
    1)
      _clipboard_utils_complete_words "${cur}" "print-command start stop status restart -h --help help"
      ;;
    2)
      if [[ "${COMP_WORDS[1]}" == "start" ]]; then
        _clipboard_utils_complete_words "${cur}" "--foreground"
      fi
      ;;
  esac
}

_clipboard_utils_hclip_tunnel_service() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "${COMP_CWORD}" -eq 1 ]]; then
    _clipboard_utils_complete_words "${cur}" "install uninstall start stop restart status enable disable daemon-reload check doctor -h --help help"
  fi
}

_clipboard_utils_simple_help() {
  local cur="${COMP_WORDS[COMP_CWORD]}"

  if [[ "${cur}" == -* ]]; then
    _clipboard_utils_complete_words "${cur}" "-h --help"
  fi
}

complete -o bashdefault -o default -F _clipboard_utils_co co
complete -o bashdefault -o default -F _clipboard_utils_coc coc
complete -o bashdefault -o default -F _clipboard_utils_cor cor
complete -o bashdefault -o default -F _clipboard_utils_simple_help cof cob cowd hclip-stop hclip-status
complete -o bashdefault -o default -F _clipboard_utils_hclip_secret hclip-secret
complete -o bashdefault -o default -F _clipboard_utils_hclip_service hclip-service
complete -o bashdefault -o default -F _clipboard_utils_hclip_start hclip-start
complete -o bashdefault -o default -F _clipboard_utils_hclip_tunnel hclip-tunnel
complete -o bashdefault -o default -F _clipboard_utils_hclip_tunnel_service hclip-tunnel-service
