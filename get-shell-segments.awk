#!/usr/bin/awk -f

###############################################################################
# PURPOSE:      Print out commands found inside Markdown 'console' sessions.
#
# AUTHOR:       DCD
# DATE:         September 2023
#
# RETURNS:      0  - OK
#               1  - FAIL
#
# EXAMPLE:      ./get-shell-segments.awk SOME_FILE.md
#
# NOTE:         
###############################################################################

BEGIN {
  FALSE = 0;
  TRUE = 1;
  count = 0;
  insegment = 0;
  commmands = 0;
  sudos = 0;
}

{
  ## if we are inside a console then set 'insegment' to true
  if( $0 ~ /^```console$/ ) {
    if( ! insegment ) {
      count = count +1;
      insegment = 1;
    }
  }
  else {
    if( $0 ~ /^```$/ ) {
      ## then we are no longer in a console segment; set the var to false
      insegment = 0;
    }
    else {
      if( insegment ) {
        keep = TRUE;
        ## look for the '$ ' or the '# ' prompt at the beginning of a line
        if( $0 ~ /^[\$#][ ]/ ) {
          #if( $0 ~ /\|/ ) {
          #  printf( "DBG-PIPE: %s\n", $0 );
          #}
          ## in case the first command is 'sudo' then count and remove it:
          if( $0 ~ /^[\$#] sudo / ) {
            ## if we are doing a 'sudo -' we will count it, but drop the cmd
            sudos = sudos + 1;
            if( $0 ~ /^[\$#] sudo -/ ) {
              keep = FALSE;
            }
            else {
              sub( /sudo /, "", $0 );
            }
          }
          commands = commands + 1;

          ## Here we watch for environment variables in front of commands
          ## For example:  TZ='America/Vancouver' date
          if( $2 ~ /=/ ) {

            ## too few words so we throw this command out
            if( NF <= 2 ) {
              commands = commands - 1;
            }
            else {
              ## we pick the 3rd word
              if( length($3) > 0 && keep ) {
                printf( "%s\n", $3 );
              }
            }
          }
          else {
            if( keep ) {
              if( $2 != "." && length($2) > 0 ) {
                printf( "%s\n", $2 );
              }
              if( $0 ~ /\|/ ) {
                if( split($0, arr, /\|/) > 0 ) {
                  nf = split(arr[2], arr2, / /);
                  if( nf > 0 ) {
                    printf( "%s\n", arr2[2] );
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

#END {
#  printf( "Number of shell segments is %i\n", count );
#  printf( "Number of commands is %i\n", commands );
#  printf( "Number of sudo commands is %i\n", sudos );
#}

