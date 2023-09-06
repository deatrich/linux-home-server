#!/bin/bash
###############################################################################
# PURPOSE:	From a list of Markdown files, generate a partial Markdown file
#		containing the list of URLs, formatted as a definition list.
#
# AUTHOR:	DCD
# DATE:		September 2023
#
# RETURNS:	0  - OK
#		1  - FAIL
#
# EXAMPLE:	./generate-url-index.sh
#
# CHANGES:	
# NOTE:		
###############################################################################
#set -v		# debugging tools
#set -x

unalias -a
PATH="/bin:/usr/bin"

cmd=$(basename $0)
dbg=""

function err_exit( ) {
  echo -e "$cmd: $1"
  exit 1
}

links="yes"

## This file is actually never generated.  You could echo the output list
## to a file; that is: ./generate-url-index.sh > urls-TEMP-NAME.md
## Then do: diff urls.md urls-TEMP-NAME.md
output="urls-TEMP-NAME.md"

global_list=""
function process_file( ) {
  thisfile="$1"
  typeset -i res

  ## get the 'ATX heading 1' chapter title with the internal chapter link
  title=$(head -3 $thisfile | grep '^# ' | sed 's/^# //')

  ## break the heading-1 chapter title into pieces
  [[ $title =~ (.*)([ ]\{#)([^}]*) ]]
  res=$?
  if [ $res -eq 0 ] ; then
    name="${BASH_REMATCH[1]}"
    link="${BASH_REMATCH[3]}"
  
    newlist=""
    while read -r lines ; do
      [[ $lines =~ ^([\[])([[:alnum:].-]+)(\]: )(.*) ]]
      res=$?
      if [ $res -eq 0 ] ; then
        url="${BASH_REMATCH[4]}"
        item=":    [$url]($url)"
        item="$item\n"
        #echo "key: ${BASH_REMATCH[2]}  value: ${BASH_REMATCH[4]}"
        if [ "$newlist" = "" ] ; then
          newlist="$item"
        else
          newlist="$newlist\n$item"
        fi
      fi
    done < $thisfile
    if [ "$newlist" != "" ] ; then
      newlist="[$name](#$link): \n\n$newlist"
      ## when finished concatenate $newlist to $global_list
      if [ "$global_list" = "" ] ; then
        global_list="$newlist"
      else
        global_list="$global_list\n$newlist"
      fi
    fi
  fi
}

if [ -f "$output" ] ; then
  err_exit "File '$output' already exists"
fi

if [ ! -f "contents.txt" ] ; then
  err_exit "File 'contents.txt' is missing"
fi

cmdfile="urls.md"
if [ ! -f "$cmdfile" ] ; then
  err_exit "File '$cmdfile' is missing"
fi

## list of all Markdown files to process
file_list=$(cat contents.txt)

## list of Markdown files to ignore when looking for urls:
ignore_list="metadata.md command-list.md commands.md url-list.md urls.md $output"

## Here we loop through each file and call the process_file function
typeset -i ignore
for i in $file_list ; do
  ignore=0
  for j in $ignore_list ; do
    if [ "$i" = "$j" ] ; then
      ignore=1
    fi
  done
  if [ $ignore -eq 0 ] ; then
    if [ -s $i ] ; then
      process_file "$i"
    else
      err_exit "File '$i' does not exist"
    fi
  fi
done

echo -e "$global_list"

