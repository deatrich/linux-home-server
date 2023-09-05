#!/bin/bash
###############################################################################
# PURPOSE:	From a list of Markdown files, generate a partial Markdown file
#		containing the list of shell commands in console sessions,
#		formatted as a definition list.
#
# AUTHOR:	DCD
# DATE:		September 2023
#
# RETURNS:	0  - OK
#		1  - FAIL
#
# EXAMPLE:	./generate-commands-index.sh
#
# CHANGES:	
# NOTE:		Set 'links' to "no" if you do not have internal urls for each
#		chapter file.
#		When links is "yes" then we also grab the identifier for the
#		internal link to any chapter where we find a console command.
#
#		Note also that 'sudo' is never listed; instead we take the 
#		command after sudo.  Therefore you will need to manually add
#		'sudo' to your final list.
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
## to this file if you don't want to deal with stdout:
output="index-$$.md"

global_list=""
function process_file( ) {
  thisfile="$1"

  if [ "$links" = "yes" ] ; then
    ## get the 'ATX heading 1' chapter title with the internal chapter link
    title=$(head -3 $thisfile | grep '^# ' | sed 's/^# //')

    ## this ugly regular expression removes all except the chapter link but
    ## without the hash-mark (example: {#chapter-1} becomes:  chapter-1 )
    url=$([[ $title =~ ([ ]\{#)([^}]*) ]] && echo ${BASH_REMATCH[2]})
  fi
  ## we call a small awk program which finds commands in 'console' sessions
  cmdlist=$(./get-shell-segments.awk $thisfile | sort -u)
  newlist=""
  if [ "$cmdlist" != "" ] ; then
    while read i ; do
      if [ "$newlist" = "" ] ; then
        newlist="$i"
        if [ "$links" = "yes" ] ; then
          newlist="$i $url"
        fi
      else
        if [ "$links" = "yes" ] ; then
          newlist="$newlist\n$i $url"
        else
          newlist="$newlist\n$i"
        fi
      fi
    done <<< $(echo "$cmdlist")

    ## when finished concatenate $newlist to $global_list
    if [ "$global_list" = "" ] ; then
      global_list="$newlist"
    else
      global_list="$global_list\n$newlist"
    fi
  fi
}

if [ -f "$output" ] ; then
  err_exit "File '$output' already exists"
fi

if [ ! -f "contents.txt" ] ; then
  err_exit "File 'contents.txt' is missing"
fi

cmdfile="commands.md"
if [ ! -f "$cmdfile" ] ; then
  err_exit "File '$cmdfile' is missing"
fi

## list of all Markdown files to process
file_list=$(cat contents.txt)

## list of Markdown files to ignore when looking for console commands:
ignore_list="metadata.md command-list.md commands.md $output"

## Here we loop through each file and call the process_file function
typeset -i ignore
for i in $file_list ; do
  ignore=0
  for j in $ignore_list ; do
    if [ "$i" = "$j" ] ; then
      ignore=1
    fi
  done
  if [ $ignore -eq 0 ] ; then process_file "$i"; fi
done

## get a uniq sort of the list of commands, and ignore empty lines:
fulllist=$(echo -e "$global_list"|sort -u|egrep -v '^$')

## we dump the list into a bash array for easier processing
IFS=$'\n' read -d '' -a arr <<<$(echo -e "$fulllist")

## get the number of elements in the array
typeset -i count
count=${#arr[@]}

typeset -i c
c=0

## this is the previous command, in case of duplicates
lastc=""

echo "Look for any commands not yet found in '$cmdfile':"
while [ $c -lt $count ] ; do
  if [ "$links" = "yes" ] ; then
    read -r cmd link <<< ${arr[$c]}
    if [ $c -gt 0 ] ; then
      if [ "$lastc" = "$cmd" ] ; then
        c=$c+1
        continue
      fi
    fi
    ## see if this $cmd is already in the $cmdfile
    egrep -q "^\[$cmd]\(#$link\):$" $cmdfile
    if [ $? -ne 0 ] ; then  ## command not found, so echo it as a list item
      echo "[$cmd](#$link):"
      echo ":   X"
      echo ""
    fi
  else
    var=${arr[$c]}
    egrep -q "^$var:$" $cmdfile
    if [ $? -ne 0 ] ; then  ## command not found, so echo it as a list item
      echo "$var:"
      echo ":   X"
      echo ""
    fi
  fi
  lastc=$cmd
  c=$c+1
done

