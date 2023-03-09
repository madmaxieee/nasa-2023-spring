#! /usr/bin/env bash
# set -o errexit
# set -o nounset
# set -o pipefail

TREE_RESULT_FILE="/tmp/b09901106-trecksum-tree"
SED_COMMAND_FILE="/tmp/b09901106-trecksum.sed"

tree -f ${1} > ${TREE_RESULT_FILE}

# reverse the order of the paths so files nested in directories are processed first
# so that the direcotry names in the file names are not replaced when processing directories
PATHS=$(tac "${TREE_RESULT_FILE}" | grep -oP "(?<=[└├]── )\S+\$")
SED_COMMAND=""

for path in ${PATHS}; do
  if [[ -f ${path} ]]; then
    SUM="$(sha1sum ${path} | grep -o "^[0-9a-f]\{40\}")"
    SED_COMMAND="${SED_COMMAND}s|${path}|$(basename ${path}) ${SUM}|;"
  else
    SED_COMMAND="${SED_COMMAND}s|${path}|$(basename ${path})|;"
  fi
done

# write the command to a tmp file
echo ${SED_COMMAND} > ${SED_COMMAND_FILE}

sed -f ${SED_COMMAND_FILE} ${TREE_RESULT_FILE}
