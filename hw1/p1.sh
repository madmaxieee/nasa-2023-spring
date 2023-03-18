#! /usr/bin/env bash
# shellcheck disable=SC2078

help_message="This command is an RSA algorithm implementation written in shell script.
There are three modes to choose from:

I. Key generation:
usage: ./p1.sh --key-generation <1st prime number> <2nd prime number>
eg: ./p1.sh --key-generation 707981 906313

II. Encrypt mode:
usage: ./p1.sh --encrypt --public-exponent <e> --modulus <n> <file>
eg: ./p1.sh --encrypt --public-exponent 65537 --modulus 641652384053 testfile
usage: ./p1.sh --key-generation <1st prime number> <2nd prime number> --encrypt <file>
eg: ./p1.sh --key-generation 707981 906313 --encrypt testfile

III. Decrypt mode:
usage: ./p1.sh --decrypt --private-exponent <d> --modulus <n> <file>
eg: ./p1.sh --decrypt --private-exponent 64657547393 --modulus 641652384053 testfile"

arg_keygeneration=false
arg_publicexponent=false
arg_modulus=false
arg_privateexponent=false
flag_encrypt=false
flag_decrypt=false

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

while [ : ]; do
  case "$1" in
    --key-generation)
      arg_keygeneration=true
      shift

      if [[ -z $1 || -z $2 ]]; then
        echo "Please provide two prime numbers" >&2
        exit 1
      fi

      p=$(parse_number "$1")
      shift
      q=$(parse_number "$1")
      shift
      ;;

    --encrypt)
      flag_encrypt=true
      shift
      ;;

    --public-exponent)
      arg_publicexponent=true
      shift

      if [[ -z $1 ]]; then
        echo "Please provide public exponent" >&2
        exit 1
      fi

      e=$(parse_number "$1")
      shift
      ;;

    --modulus)
      arg_modulus=true
      shift

      if [[ -z $1 ]]; then
        echo "Please provide modulus" >&2
        exit 1
      fi

      N=$(parse_number "$1")
      shift
      ;;

    --decrypt)
      flag_decrypt=true
      shift
      ;;

    --private-exponent)
      arg_privateexponent=true
      shift

      if [[ -z $1 ]]; then
        echo "Please provide private exponent" >&2
        exit 1
      fi

      d=$(parse_number "$1")
      shift
      ;;

    --)
      shift
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
  esac
done

function gcd {
  local a=$1
  local b=$2

  while [[ $(math "$b == 0") -eq 1 ]]; do
    local temp=$b
    b=$(math "$a % $b")
    a=$temp
  done

  echo "$a"
}

# return d, x, y such that ax + by = d
function extended_gcd {
  local a=$1
  local b=$2

  local result
  local d
  local x
  local y

  if [[ $(math "$b == 0") -eq 1 ]]; then
    echo "$a 1 0"
    return
  fi

  result=$(extended_gcd "$b" "$(math "$a % $b")")

  d=$(echo "$result" | cut -d' ' -f1)
  x=$(echo "$result" | cut -d' ' -f2)
  y=$(echo "$result" | cut -d' ' -f3)

  echo "$d $y $(math "$x - ($a / $b) * $y")"
}

function keygen {
  local p=$1
  local q=$2
  local e=$3
  local N
  local phiN

  N=$(math "$p * $q")
  phiN=$(math "($p - 1) * ($q - 1)")

  if [[ $(gcd "$e" "$phiN") -ne 1 ]]; then
    echo "Public exponent is not coprime with phi(N)" >&2
    exit 1
  fi

  # a b d
  extended_gcd "$e" "$phiN"
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

if [[ $arg_keygeneration == true && $flag_encrypt == false && $flag_decrypt == false ]]; then
  if [[ -z $e ]]; then
    e=65537
  fi

  d=$(keygen "$p" "$q" "$e" | cut -d ' ' -f 2)
  N=$(math "$p * $q")

  echo "Public exponent: $e"
  echo "Private exponent: $d"
  echo "Modulus: $N"

  exit 0
fi

if [[ $flag_encrypt == true && $arg_keygeneration == false && $arg_publicexponent == true && $arg_modulus == true && $flag_decrypt == false ]]; then
  while read -r line; do
    power "$line" "$e" "$N"
  done < "$inputfile"

  if [[ -n $line ]]; then
    power "$line" "$e" "$N"
  fi

  exit 0
fi

if [[ $flag_encrypt == true && $arg_keygeneration == true && $flag_decrypt == false ]]; then
  if [[ -z $e ]]; then
    e=65537
  fi

  N=$(math "$p * $q")

  while read -r line; do
    power "$line" "$e" "$N"
  done < "$inputfile"

  if [[ -n $line ]]; then
    power "$line" "$e" "$N"
  fi

  exit 0
fi

if [[ $flag_decrypt == true && $arg_keygeneration == false && $arg_privateexponent == true && $arg_modulus == true && $flag_encrypt == false ]]; then
  while read -r line; do
    power "$line" "$d" "$N"
  done < "$inputfile"

  if [[ -n $line ]]; then
    power "$line" "$d" "$N"
  fi

  exit 0
fi

echo "Invalid arguments" >&2
exit 1
