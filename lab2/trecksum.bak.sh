#! /usr/bin/env bash
# set -o errexit
# set -o nounset
# set -o pipefail

TREE_RESULT_FILE=$(mktemp)
SHA1SUM_FILE=$(mktemp)
SED_COMMAND_FILE=$(mktemp)

tree -f ${1} > ${TREE_RESULT_FILE}

PATHS=$(tac "${TREE_RESULT_FILE}" | grep -oP "(?<=── )\S+\$")

sha1sum ${PATHS} > ${SHA1SUM_FILE} 2> /dev/null

# map each line from "e3f992c8aa909e6c19ba40067d3cb1f6b0eb41e2  ./sample/sample-0/fbff9045ddfb0541"
# to "s|./sample/sample-0/fbff9045ddfb0541|fbff9045ddfb0541 e3f992c8aa909e6c19ba40067d3cb1f6b0eb41e2|;"
# using awk
awk '{
  basename = gensub(/.*\/(.*)/, "\\1", "g", $2)
  print "s|" $2 "|" basename " " $1 "|;"
}' ${SHA1SUM_FILE} > ${SED_COMMAND_FILE}

SED_COMMANDS=()

for path in ${PATHS}; do
  if [[ -d ${path} ]]; then
    SED_COMMANDS+=("s|${path}|$(basename ${path})|;")
  fi
done

# write the command to a tmp file
echo "${SED_COMMANDS[@]}" | tr ' ' '\n' >> ${SED_COMMAND_FILE}

sed -f ${SED_COMMAND_FILE} ${TREE_RESULT_FILE}
