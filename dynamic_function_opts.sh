#!/bin/zsh
alias getOpts="parse_dynamic_options"
alias pdo="parse_dynamic_options"
alias _opt="_optsVal"
alias ov="_optsVal"
alias trimL="_trimLeadingWhiteSpace"

# Function to parse dynamic options
# $@: individual opts in form "-{n}ame {value}" or "-{n}ame={value}"
# returns an expandable associative array of opts to values.
parse_dynamic_options() {
    local optstring=""
    local opt
    local _args='';
    # Build the optstring from the arguments
    for arg in "$@"; do
      if [[ "$arg" == -* ]]; then
          optstring="${optstring}${arg:1:1}:"
      fi
    done

    # Use getopts with the generated optstring
    while getopts "$optstring" opt; do
      case "$opt" in
        *)
            k=$(_trimLeadingWhiteSpace $opt);
            v=$(_trimLeadingWhiteSpace ${OPTARG#=})
            _args+=" [$k]='$v'"
        ;;
      esac
    done
    shift $((OPTIND-1))
    # Remove the first character - singular leading space.
    local _opts=${_args:1};
    echo "($_opts)";
}

_getTextBeforeChar() {
  echo "${1%=*}";
}
_getTextAfterChar() {
  echo "${1#*=}";
}

# Turn opts into assoc. array and retrive akey's value.
# $1: an expandable assoc array string.
# $2: a key to search for.
# usage:
#   opts=$(parse_dynamic_options "-m 1" "-y myarg2");
#   _optsVal $opts "m";
_optsVal() {
  # ugly...
  eval "declare -A _array=${1}"
  if [[ ! -v "_array[$2]" ]]; then
    if [ -n "$3" ]; then
      echo "$3";
    fi
  else
    echo "${_array[$2]}"
  fi
}

_trimLeadingWhiteSpace() {
  echo "${1#"${1%%[![:space:]]*}"}"
}

_test() {
  local opts=$(parse_dynamic_options -m=1 -y=myarg2);
  echo $opts;
  _optsVal $opts "m";
  _optsVal $opts "t" "feat";
}

