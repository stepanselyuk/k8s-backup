#!/usr/bin/env bash
#: Name        : slugify
#: Date        : 2012-05-01
#: Author      : "Benjamin Linton" <developer@benlinton.com>
#: Version     : 1.0.1
#: Description : Convert filenames into a web friendly format.
#: Options     : See print_usage() function.
#: MODIFIED     : STEPAN SELIUK

## Initialize defaults
script_name=${0##*/}
dashes_omit_adjacent_spaces=1
consolidate_spaces=1
space_replace_char='-'
ignore_case=0
dashes_to_spaces=0
underscores_to_spaces=0

## Initialize valid options
opt_string=acdhintuv

## Usage function
function print_usage(){
  echo "usage: $script_name [-$opt_string] source_file ..."
  echo "   -a: remove spaces immediately adjacent to dashes"
  echo "   -c: consolidate consecutive spaces into single space"
  echo "   -d: replace spaces with dashes (instead of default underscores)"
  echo "   -h: help"
  echo "   -i: ignore case"
  echo "   -t: treat existing dashes as spaces"
  echo "   -u: treat existing underscores as spaces (useful with -a, -c, or -d)"
}

## For each provided option arg
while getopts $opt_string opt
do
  case $opt in
    a) dashes_omit_adjacent_spaces=1 ;;
    c) consolidate_spaces=1 ;;
    d) space_replace_char='-' ;;
    h) print_usage; exit 0 ;;
    i) ignore_case=1 ;;
    t) dashes_to_spaces=1 ;;
    u) underscores_to_spaces=1 ;;
    *) exit 1 ;;
  esac
done

## Remove options from args
shift "$(( $OPTIND - 1 ))"

## Unless source_file arg(s) found, print usage and exit (0 to avoid breaking pipes)
if [[ -z "$1" ]]; then
  print_usage
  exit 0
fi

## Identify case insensitive filesystems
case_sensitive_filesystem=1
case $OSTYPE in
  darwin*) case_sensitive_filesystem=0 ;; # OS X
  *) ;; # Do nothing
esac

## For each file, directory, or glob
for source in "$@"; do

  ## Verify source exists
#  if [ ! -e "$source" ]; then
#    echo "not found: $source"
#    ## Skip to next loop iteration unless in dry run mode
#    if [ $dry_run -eq 0 ]; then
#      continue
#    fi
#  fi

  ## Initialize target
  target="$source"

  ## Optionally convert to lowercase
  if [ $ignore_case -eq 0 ]; then
    target=$(echo "$target" | tr A-Z a-z )
  fi

  ## Optionally convert existing underscores to spaces
  if [ $underscores_to_spaces -eq 1 ]; then
    target=$(echo "$target" | tr _ ' ')
  fi

  ## Optionally convert existing dashes to spaces
  if [ $dashes_to_spaces -eq 1 ]; then
    target=$(echo "$target" | tr - ' ')
  fi

  ## Optionaly consolidate spaces
  if [ $consolidate_spaces -eq 1 ]; then
    target=$(echo "$target" | tr -s ' ')
  fi

  ## Optionally remove spaces immediately adjacent to dashes
  if [ $dashes_omit_adjacent_spaces -eq 1 ]; then
    target=$(echo "$target" | sed 's/\- /-/')
    target=$(echo "$target" | sed 's/ \-/-/')
  fi

  ## Replace spaces with underscores or dashes
  target=$(echo "$target" | tr ' ' "$space_replace_char")

  echo "$target"

done
