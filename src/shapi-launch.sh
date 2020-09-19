#!/bin/bash
#
#  Script launched by the ssh daemon to invoke other commands. 
#
set -euo pipefail
#set -x
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

PASSWORD_STORE_GPG_PASSPHRASE_FILE=${PASSWORD_STORE_GPG_PASSPHRASE_FILE:-$(readlink -f "${script_dir}"/../../secret/gpg-pass-phrase.txt)}
export PASSWORD_STORE_GPG_OPTS="--passphrase-file $PASSWORD_STORE_GPG_PASSPHRASE_FILE"
export PASSWORD_STORE_DIR=${PASSWORD_STORE_DIR:-$(readlink -f "${script_dir}"/../../.password-store)}
PASS_BIN_DIR=$(readlink -f "${script_dir}"/../bin)
export PATH="$PASS_BIN_DIR":$PATH

test -d "$script_dir"
test -x "$PASS_BIN_DIR"/pass
test -e "$PASSWORD_STORE_GPG_PASSPHRASE_FILE"
test -d "$PASSWORD_STORE_DIR"

function help {
  cat "$script_dir"/shapi-help.yaml
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

  help)
    help
    exit 0  
  ;;

  computer/groups)
    "$script_dir"/../../active_directory/computer.sh groups ${varargs[@]:1}
    ;;

  ldap/object)
    "$(readlink -f "$script_dir"/../../active_directory/object.sh)" ${varargs[@]:1}
    ;;

    * )
      echo "Unknown command: $command"  1>&2
    ;;
esac


  
