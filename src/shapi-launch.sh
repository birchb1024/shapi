#!/bin/bash
#
#  Script launched by the ssh daemon to invoke other commands. 
#
set -euo pipefail
#set -x

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
test -d "$script_dir"

if false
then
  # TODO Move into a command which uses pass
  PASSWORD_STORE_GPG_PASSPHRASE_FILE=${PASSWORD_STORE_GPG_PASSPHRASE_FILE:-$(readlink -f "${script_dir}"/secret/gpg-pass-phrase.txt)}
  export PASSWORD_STORE_GPG_OPTS="--passphrase-file $PASSWORD_STORE_GPG_PASSPHRASE_FILE"
  export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR:-$(readlink -f "${script_dir}"/../../.password-store)}
  PASS_BIN_DIR=$(readlink -f "${script_dir}"/../bin)
  export PATH="$PASS_BIN_DIR":$PATH
  test -x "$PASS_BIN_DIR"/pass
  test -e "$PASSWORD_STORE_GPG_PASSPHRASE_FILE"
  test -d "$PASSWORD_STORE_DIR"
fi

function help {
  "$script_dir"/../bin/jp -f "$script_dir"/shapi-help.json '@' 
}

if [[ $# -lt 1 ]]
then
  help
  exit
fi

#
# Unlike normal CLI, sshd ForceCommand passes all arguments in $1 in a single string.
# So we have to parse this out, noting that some arguments like distinguished names contain spaces.
#
IFS=' ' read -r -a varargs <<< "$1"         # Split a string on space. Bash eh, what are you like.
command="${varargs[0]}"

# We test commands explicitly to avoid injections 
case "$command" in

  shapi/help)
    help
    exit 0  
  ;;

  shapi/health)
    echo '{"health": "OK"}'
    ;;

  shapi/echo)
    "$script_dir"/../bin/jp '@'
    ;;

  machine/facter)
	    stdoutTmpFile=$(mktemp)
     	    stderrTmpFile=$(mktemp)
            set +e
	    if ( facter -j | awk '!/ssh/' | "$script_dir"/../bin/jp '@' ) 1>"$stdoutTmpFile" 2>"$stderrTmpFile"
	    then
		cat "$stdoutTmpFile"
	    else
		echo "{ \"error\": \"$(cat "$stderrTmpFile" | sed 's;";\";g' )\" }"
		exit 1
	    fi
	    set -e
    ;;

    * )
      echo '{ "error": "Unknown command '$command'" }'
    ;;
esac


  
