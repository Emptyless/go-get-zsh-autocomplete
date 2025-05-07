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

  if [[ "${words[${CURRENT}]}" =~ @.* ]]; then
    __go_debug "last char is '@' so loading possible versions"
    local repo
    repo="${lastParam}"
    if [[ "${repo}" =~ '(github\.com\/([a-zA-Z0-9\-\_]+)\/([a-zA-Z0-9\-\_]+))' ]]; then
      __go_debug "repo is github.com format"
      repo=$(cut -d'/' -f1 -f2 -f3 <<<"${repo}")
    fi
    repo=${repo%.git*}

    nested=${lastParam##"${repo}"}
    nested=${nested##.git}
    nested=${nested##/}
    if [ "${nested}" = "${lastParam}" ]; then
      nested=""
    else
      nested="${nested%@*}/"
    fi

    __go_debug "repo: ${repo}"
    __go_debug "nested: ${nested}"

    local prefix
    prefix="${lastParam%@*}@"
    __go_debug "prefix ${prefix}"

    local -a completions
    local refs
    refs=$(git ls-remote --heads --tags "https://${repo}" | cut -f 2)
    for ref in ${(f)refs}; do
      if [[ "${ref}" =~ ^refs/heads/ ]]; then
        completions+=("${ref##refs/heads/}")
        __go_debug "found: ${ref}"
      elif [[ "${ref}" =~ ^refs/tags/"${nested}" ]]; then
        completions+=("${ref##refs/tags/"${nested}"}")
        __go_debug "found: ${ref##refs/tags/}"
      fi
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

  local -a completions
  for item in ${modcache}/*/; do
    item=$(basename "${item}")
    item=$(sed 's/@.*/@/g' <<<"${item}")
    item=$(sed 's/!(.)/\U\0/g' <<<"${item}")
    item=$(__from_go_dirname "${item}")

    if [ "${item[-1]}" != "@" ]; then
      item="${item}/"
    fi

    found=false
    for item2 in ${completions}; do
        if [ "${item}" = "${item2}" ]; then
          found=true
          break
        fi
    done

    if [ "${found}" != true ]; then
      __go_debug "found: ${item}"
      completions+=("${item}")
    fi
  done

  compadd -p "${prefix}" -S '' "${completions[@]}"

  ret=$?
  __go_debug "exit: ${ret}"
  return $ret
}

# take any string as input and replace !<char> with Char
__from_go_dirname() {
  local result
  local toUpper
  toUpper=false

  for (( i=0; i<=${#1}; i++ )); do
    char="${1:$i:1}"
    if [ "$char" = "!" ]; then
      toUpper=true
    elif [ "$toUpper" = true ]; then
      result="${result}${char:u}"
      toUpper=false
    else
      result="${result}${char}"
      toUpper=false
    fi
  done
  echo "$result"
}

# take any string as input and replace !<char> with Char
__to_go_dirname() {
  local result
  for (( i=0; i<=${#1}; i++ )); do
    char="${1:$i:1}"
    if [[ "$char" =~ [A-Z] ]]; then
      result="${result}!${char:l}"
    else
      result="${result}${char}"
    fi
  done
  echo "$result"
}

