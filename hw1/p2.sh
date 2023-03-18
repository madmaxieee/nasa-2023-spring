#! /usr/bin/env bash
# shellcheck disable=SC2078

help_message="This command is an DSA verifying implementation written in shell script.
usage: ./p2.sh --sig (<r>,<s>) --pubkey (<p>,<q>,<alpha>,<beta>) <file>"

arg_sig=false
arg_pubkey=false

function math {
  BC_LINE_LENGTH=0 bc <<< "scale=0; $1"
}

function parse_number {
  local n=$1
  if [[ $n =~ ^[0-9]+$ ]]; then
    echo "$n"
  elif [[ $n =~ ^0x[0-9A-F]+$ || $n =~ ^0x[0-9a-f]+$ ]]; then
    hex=$(echo "${n//0x/}" | tr '[:lower:]' '[:upper:]')
    math "obase=10; ibase=16; $hex"
  else 
    echo "Invalid number: $n" >&2
    exit 1
  fi
}

function power {
  local a=$1
  local n=$2
  local N=$3

  local ans=1

  while [[ $(math "$n > 0") -eq 1 ]]; do
    if [[ $(math "$n % 2") -eq 1 ]]; then
      ans=$(math "($ans * $a) % $N")
    fi

    a=$(math "($a * $a) % $N")
    n=$(math "$n / 2")
  done

  echo "$ans"
}

while [ : ]; do
    case "$1" in
    --sig)
      arg_sig=true
      shift

      if [[ -z $1 ]]; then
        echo "Please provide a signature" >&2
        exit 1
      fi

      sig=$1
      shift

      if [[ $sig =~ \([xa-fA-F0-9]+,[xa-fA-F0-9]+\) ]]; then
        sig=$(echo "$sig" | tr -d '()')
        r=$(parse_number "$(echo "$sig" | cut -d ',' -f 1)")
        s=$(parse_number "$(echo "$sig" | cut -d ',' -f 2)")
      else
        echo "Invalid signature format" >&2
        exit 1
      fi
      ;;

    --pubkey)
      arg_pubkey=true
      shift

      if [[ -z $1 ]]; then
        echo "Please provide a public key" >&2
        exit 1
      fi

      pubkey=$1
      shift

      if [[ $pubkey =~ \(([xa-fA-F0-9]+,){3}[xa-fA-F0-9]+\)
      ]]; then
        pubkey=$(echo "$pubkey" | tr -d '()')
        p=$(parse_number "$(echo "$pubkey" | cut -d ',' -f 1)")
        q=$(parse_number "$(echo "$pubkey" | cut -d ',' -f 2)")
        alpha=$(parse_number "$(echo "$pubkey" | cut -d ',' -f 3)")
        beta=$(parse_number "$(echo "$pubkey" | cut -d ',' -f 4)")
      else
        echo "Invalid public key format" >&2
        exit 1
      fi

      ;;
    
    -h | --help)
      echo "$help_message"
      exit 1
      ;;

    --* | -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;

    *)
      if [[ -n $1 ]]; then
        inputfile=$1
      else
        break
      fi
      shift
      ;;
    esac
done

if [[
  $arg_sig == false ||
  $arg_pubkey == false ||
  -z $inputfile
]]; then
  echo "Invalid arguments" >&2
  echo "$help_message" >&2
  exit 1
fi

# DSA algorithm

# 1. Compute w = s^-1 mod q
w=$(power "$s" "$(math "$q - 2")" "$q")

# 2. Compute the hash of the message
hash=$(sha1sum "$inputfile" | cut -d ' ' -f 1 | tr '[:lower:]' '[:upper:]')
hash=$(math "obase=10; ibase=16; $hash")

# 3. Compute u1 = hash * w mod q
u1=$(math "($hash * $w) % $q")

# 4. Compute u2 = r * w mod q
u2=$(math "($r * $w) % $q")

# 5. Compute v = (alpha^u1 * beta^u2 mod p) mod q
alpha=$(power "$alpha" "$u1" "$p")
beta=$(power "$beta" "$u2" "$p")
v=$(math "($alpha * $beta) % $p")
v=$(math "($v % $q)")

# 6. If v = r, the signature is valid
if [[ $v -eq $r ]]; then
  echo "True"
else
  echo "False"
fi
