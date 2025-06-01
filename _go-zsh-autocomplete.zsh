compdef _go go

__go_debug(){
  local file="$ZSH_GO_COMP_DEBUG_FILE"
  if [[ -n ${file} ]]; then
     echo "$*" >> "${file}"
  fi
}

_go() {
  local lastParam
  local lastChar
  local -a completions

  __go_debug "\n"
  __go_debug "CURRENT: ${CURRENT}"
  __go_debug "words[*]: ${words[*]}"

  words=("${=words[1,CURRENT]}")
  __go_debug "[processed] words[*]: ${words[*]},"

  # only autocomplete 'go get' commands
  if [ "${words[1]}" != "go" ] || [  "${words[2]}" != "get" ]; then
    __go_debug "only autocomplete starting with 'go get'. Actual '${words[1]} ${words[2]}'"
    return 0
  fi

  # only autocomplete packages, not flags
  if [ "${words[${CURRENT}]:0:1}" = "-" ]; then
    __go_debug "only autocomplete packages, not flags. CURRENT: ${words[${CURRENT}]}"
    return 0
  fi

  lastParam=${words[-1]}
  __go_debug "lastParam: ${lastParam}"
  lastChar=${lastParam[-1]}
  __go_debug "lastChar: ${lastChar}"

  if [[ "${words[${CURRENT}]}" =~ (@.*) ]]; then
    __go_debug "last char is '@' so loading possible versions"
    local repo
    repo="$(__parse_repo "${lastParam%"${match[1]}"}")"

    nested=${lastParam##"${repo}"}
    nested=${nested##.git}
    nested=${nested##/}
    if [[ "${nested}" =~ ^@ ]]; then
      nested=""
    else
      nested="${nested%@*}/"
    fi

    __go_debug "repo: ${repo}"
    __go_debug "nested: ${nested}"

    local prefix
    prefix="${lastParam%@*}@"
    __go_debug "prefix ${prefix}"

    # Create all process substitutions at once and collect file descriptors
    local -a fd_processes=()
    refs=$(git ls-remote --heads --tags "https://${repo}" | cut -f 2)
      for ref in ${(f)refs}; do
        exec {fd}< <(__process_ref "$ref" "$nested")
        fd_processes+=($fd)
    done

    local -a completions
    # Collect all output at once
    for fd in ${fd_processes}; do
        if IFS= read -ru "$fd" item; then
          completions+=("${item}")
        fi
        exec {fd}<&-  # Close the file descriptor
    done

    compadd -p "${prefix}" -S '' "${completions[@]}"

    ret=$?
    __go_debug "exit: ${ret}"
    return $ret
  fi

  # GOMODCACHE to start completing from
  local modcache
  modcache=$(go env GOMODCACHE)
  __go_debug "GOMODCACHE: ${modcache}"

  local moduledir
  moduledir=${lastParam%/*}
  if [ "${moduledir}" = "${lastParam}" ]; then
    moduledir="."
  fi

  if [ "${moduledir}" != "." ]; then
    moduledir=$(__to_go_dirname "${moduledir}")
    modcache="${modcache}/${moduledir}"
  elif [ "${lastParam[-1]}" = "/" ]; then
    moduledir=$(__to_go_dirname "${lastParam:0:-1}")
    modcache="${modcache}/${moduledir}"
  fi

  __go_debug "moduledir: ${moduledir}"
  __go_debug "[processed] modcache": ${modcache}

  local prefix
  prefix=""
  if [ "${moduledir}" != "." ]; then
    prefix="$(__from_go_dirname "${moduledir}")/"
  fi
  __go_debug "prefix: ${prefix}"

  # Create all process substitutions at once and collect file descriptors
  local -a fd_processes=()
  for item in ${modcache}/*/; do
      exec {fd}< <(__process_item "$item")
      fd_processes+=($fd)
  done

  local -A seen
  local -a completions
  # Collect all output at once
  for fd in ${fd_processes}; do
      if IFS= read -ru "$fd" item; then
          if (( ${+seen[$item]} == 0 )); then
              seen[$item]=1
              __go_debug "found: ${item}"
              completions+=("${item}")
          fi
      fi
      exec {fd}<&-  # Close the file descriptor
  done

  compadd -p "${prefix}" -S '' "${completions[@]}"

  ret=$?
  __go_debug "exit: ${ret}"
  return $ret
}

# parse repo information from the current state of autocompletion
__parse_repo() {
  repo="${1}"
  __go_debug "received repo ${repo}"
  if [[ "${repo}" =~ '(github\.com\/([a-zA-Z0-9\-\_]+)\/([a-zA-Z0-9\-\_]+))' ]]; then
    __go_debug "repo is github.com format"
    repo=$(cut -d'/' -f1 -f2 -f3 <<<"${repo}")
    fi
  repo=${repo%.git*}
  print -r -- "$repo"
}

# process refs by parsing refs/heads or refs/tags
__process_ref() {
  ref="${1}"
  nested="${2}"
  if [[ "${ref}" =~ ^refs/heads/ ]]; then
    print -r -- "${ref##refs/heads/}"
  elif [[ "${ref}" =~ ^refs/tags/"${nested}" ]]; then
    print -r -- "${ref##refs/tags/"${nested}"}"
  fi
}

# process item that is read in the directory.
# e.g. github.com/!some!package@x.y.z by
# 1) take the basename: some!package@x.y.z
# 2) strip the version information: some!package@
# 3) parse from go dirname: SomePackage@
__process_item() {
  item="${1}"
  item=$(basename "${item}") # take only the last part
  item=$(sed 's/@.*/@/g' <<<"${item}") # strip version @x.y.z. information
  item=$(__from_go_dirname "${item}") # transform to go filename mode

  if [ "${item[-1]}" != "@" ]; then
    item="${item}/" # differentiate with version
  fi

  print -r -- "$item"
}

# take any string as input and replace !lowercase with uppercase, e.g. !hello!world with HelloWorld
__from_go_dirname() {
  local input="$1"
  local char
  while [[ "$input" =~ !(.) ]]; do
    input="${input/!${match[1]}/${match[1]:u}}"
  done

  print -r -- "$input"
}

# take any string as input and replace Uppercase with !lowercase, e.g. HelloWorld to !hello!world
__to_go_dirname() {
  local input="$1"
  local char
  while [[ "$input" =~ ([A-Z]) ]]; do
    input="${input/${match[1]}/!${match[1]:l}}"
  done

  print -r -- "$input"
}

