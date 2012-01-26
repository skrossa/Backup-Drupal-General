#!/bin/sh

###################################
# Default environment#
###################################
# Set defaults
defaultExtraLabel=""
defaultBuDirLevel="../.."
defaultPrep="--prep"
###################################

# backup-drupal-general.sh by Sharon L. Krossa, skrossa@sharonkrossa.com
thisVersion="2.2.1"
thisVersionDate="25 Jan 2012"
#
# All code is Copyright ©2010 - 2012 by the original authors
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    This program includes works under other copyright notices and distributed
#    according to the terms of the GNU General Public License or a compatible
#    license, including:
#        Color shell script by Dave Taylor, copyright 2004-2006
#
# Backs up Drupal directory and database
# By default to DrupalBackups/ in level two directories above Drupal directory
# e.g. /afs/ir/group/krossa/cgi-bin/sharon
# gets backed up to
# /afs/ir/group/krossa/cgi-bin/sharon/../../DrupalBackups/
# that is,
# /afs/ir/group/krossa/DrupalBackups
# But alternate directory can be indicated
#
# Written by Sharon L. Krossa, skrossa@sharonkrossa.com & skrossa@stanford.edu
# v. 2.1
#       Various improvements, including configurable defaults and bug fixes
# v. 2.0
#        Generalized to non-AFS systems
# v. 1.3 (19 Sep 2011)
#        Made commands not verbose
#        Changed sql-dump so doesn't dump data from common tables (caches, session, etc.)
# v. 1.2 (4 Dec 2010)
#        Fixed Drupal commands to be compatible with Drupal 3 (no spaces)
# v. 1.1 (26 Apr 2010)
#        Fixed so archiveNamePart1 also created when argument used for extraLabel
# v. 1.0 (11 Apr 2010)
#
#
# Optional arguments (for extra label for archive file names)
#
# At Stanford, need to use from corn.stanford.edu in order to use Drush
#
# Must be run from within top level directory of drupal site
# e.g., /afs/ir/group/krossa/cgi-bin/sharon
#
# Not suitable for sites (including multisites) that use more than one database
#
# usage syntax is:
# backup-drupal-general help
# backup-drupal-general [-v|s|t] [extraLabel]
# backup-drupal-general [-v|s|t] extraLabel [buDirLevel] [--prep]
# -s Silent -- don't give any feedback (except error)
# -v verbose -- give full feedback
# -t terse -- only feedback is to echo executed commands
# extraLabel is used in backup file names in addition to folder names & date/time
# buDirlevel is used to indicate the relative path from the Drupal site being backed up
#   to the directory where the DrupalBackups directory is/should reside (that is the directory
#   above DrupalBackups) default is ../..
#
########################################################################
# Error checking function                                              #
########################################################################
# The exit status is stored in the shell variable $?.
# So usage syntax is
# check_errs $? "${redf}Sorry, problem! Exiting.${reset}"
check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ] ; then
    echo "ERROR # ${1} : ${redf}${2}${reset}"
    # as a bonus, make our script exit with the right error code.
    exit ${1}
  fi
}
########################################################################
# Command execution and feedback function                              #
########################################################################
# usage syntax is:
# do_and_feedback [-v|s|t] command [feedback]
# do_and_feedback "drush -v dl drupal" "download Drupal"
# -s Silent -- don't give any feedback (except error)
# -v verbose -- give full feedback
# -t terse -- only feedback is to echo executed commands

do_and_feedback()
{
  case $1 in
    -s|-t|-v)
      doFlag=$1
      curCommand=$2
      feedback=$3
      ;;
    *)
      doFlag="-t"
      curCommand=$1
      feedback=$2
      ;;
  esac
#   curCommand=$1
#   if [ ( x"$curVar" = x-s ) -o ( x"$curVar" = x-v ) -o ( x"$curVar" = x-t ) ] ; then
#     doFlag=$curCommand
#     curCommand=$2
#     feedback=$3
#   else
#     feedback=$2
#     doFlag="-v"
#   fi
  if [ x"$doFlag" != x-s ] ; then
    if [ "$feedback" -a x"$doFlag" != x-t ] ; then
      echo "${greenf}Okay, ${feedback} by doing ${cyanf}${curCommand}${reset}"
    else
      echo "${cyanf}${curCommand}${reset}"
    fi
  fi
  $curCommand
  check_errs $? "Sorry, problem with ${cyanf}${curCommand} ${reset}-- Exiting."
}

########################################################################
# Set variables for easy color inclusion in echos                      #
########################################################################
# from Wicked Cool Shell Scripts written by Dave Taylor
# http://www.intuitive.com/wicked/showscript.cgi?011-colors.sh
# ANSI Color -- use these variables to easily have different color
#    and format output. Make sure to output the reset sequence after
#    colors (f = foreground, b = background), and use the 'off'
#    feature for anything you turn on.

initializeANSI()
{
# apparently the funny character esc is set to works when run
  esc=""

  blackf="${esc}[30m";   redf="${esc}[31m";    greenf="${esc}[32m"
  yellowf="${esc}[33m"   bluef="${esc}[34m";   purplef="${esc}[35m"
  cyanf="${esc}[36m";    whitef="${esc}[37m"

  blackb="${esc}[40m";   redb="${esc}[41m";    greenb="${esc}[42m"
  yellowb="${esc}[43m"   blueb="${esc}[44m";   purpleb="${esc}[45m"
  cyanb="${esc}[46m";    whiteb="${esc}[47m"

  boldon="${esc}[1m";    boldoff="${esc}[22m"
  italicson="${esc}[3m"; italicsoff="${esc}[23m"
  ulon="${esc}[4m";      uloff="${esc}[24m"
  invon="${esc}[7m";     invoff="${esc}[27m"

  reset="${esc}[0m"
}

initializeANSI

########################################################################
# main script starts here                                              #
########################################################################


# Get variables, if any

verbFlag=""
extraLabel=""
buDirLevel=""
prep=""

#case $1 in
#<matching pattern>) <command>
#;;
#esac
# Then you can use shift to get the next variable in the right place

case $1 in
  help)
    echo "backup-drupal-general.sh v.${thisVersion} by Sharon L. Krossa, skrossa@sharonkrossa.com"
    echo "${thisVersionDate}"
    echo "Backs up Drupal directory and database"
    echo ""
    echo "Must be run from within top level directory of drupal site"
    echo "e.g., /afs/ir/group/krossa/cgi-bin/sharon"
    echo ""
    echo "Not suitable for sites (including multisites) that use more than one database"
    echo ""
    echo "By default backups up to DrupalBackups/ in level two directories above Drupal directory"
    echo "e.g. /afs/ir/group/krossa/cgi-bin/sharon"
    echo "gets backed up to"
    echo "/afs/ir/group/krossa/cgi-bin/sharon/../../DrupalBackups/"
    echo "that is,"
    echo "/afs/ir/group/krossa/DrupalBackups"
    echo "But alternate directory can be indicated"
    echo ""
    echo "usage syntax is:"
    echo "backup-drupal-general help"
    echo "backup-drupal-general [-v|s|t] [extraLabel]"
    echo "backup-drupal-general [-v|s|t] extraLabel [relativeDirectory] [--prep|--noprep]"
    echo ""
    echo "Optional arguments:"
    echo ""
    echo "-s Silent -- don't give any feedback (except error)"
    echo "-v verbose -- give full feedback"
    echo "-t terse -- only feedback is to echo executed commands"
    echo "default is -t"
    echo ""
    echo "extraLabel is used in backup file names (in addition to directory name & date/time)"
    echo "  It can contain only alphanumeric ASCII characters and underscores"
    echo "  default is ${defaultExtraLabel}"
    echo ""
    echo "relativeDirectory is used to indicate the relative path from the Drupal site directory"
    echo "  being backed up to the directory where the DrupalBackups directory is/should reside"
    echo "  (that is, the directory above DrupalBackups)"
    echo "  default is ${defaultBuDirLevel}"
    echo ""
    echo "--prep indicates undated copies of the backup files should also be made"
    echo "  (e.g., to allow easier automated moving of a Drupal site)"
    echo "--noprep indicates undated copies of the backup files should not be made"
    echo "default is ${defaultPrep}"
    echo " "
    exit 0
    ;;
  -v|-t|-s)
    verbFlag=$1
    extraLabel=$2
    buDirLevel=$3
    prep=$4
    ;;
  *)
    verbFlag="-t"
    extraLabel=$1
    buDirLevel=$2
    prep=$3
    ;;
esac

# Get extra label, if any, from arguments, otherwise ask for
# (optional) extra label

if [ ! "$extraLabel" ] ; then
  echo "${boldon}${bluef}Enter extra label (ASCII alphanumeric characters only) for .sql and directory archive file names (e.g., \"sitename\" or \"preupdate\". Note: The directory name and current date and time will be automatically included in the archive file names.) To use default (${defaultExtraLabel}), leave blank:${reset}${boldoff}"
  read extraLabel
  if [ $extraLabel ] ; then
    if [ x"$verbFlag" == x-v ] ; then
      echo "${greenf}Okay, extra label is \"${extraLabel}\"${reset}"
    fi
  else
    extraLabel=${defaultExtraLabel}
    if [ x"$verbFlag" == x-v ] ; then
      echo "${greenf}Okay, default extra label (${extraLabel}).${reset}"
    fi
  fi
fi

# Error check variables

if [ "$extraLabel" ] ; then
  echo $extraLabel | grep "[^0-9a-zA-Z]" > /dev/null 2>&1
  grepRes="$?"
  if [ "$grepRes" -eq "0" ] ; then
    # grep found something other than a-z, 0-9, and underscore
    echo "${redf}Sorry, extra label for archive file names (${extraLabel}) contains character(s) that are not ASCII alphanumeric -- Exiting.${reset}"
    exit 1
  fi
fi

if [ "$buDirLevel" ] ; then
  if [ "$buDirLevel" == "--prep" -o "$buDirLevel" == "--noprep" ] ; then
    prep=${buDirLevel}
    buDirLevel=${defaultBuDirLevel}
  elif [ ! "$prep" ] ; then
    prep=${defaultPrep}
  fi
else
  buDirLevel=${defaultBuDirLevel}
  prep=${defaultPrep}
fi

if [ ! -d "$buDirLevel" ] ; then
    echo "${redf}Sorry, $buDirLevel doesn't exist -- Exiting.${reset}"
    exit 1
fi

# Check that script being run from a main Drupal directory
# by checking for certain Drupal files

if [ ! -f "index.php" ] ; then
  echo "${redf}Sorry, ${mainPath} doesn't appear to be a main Drupal directory (no index.php file). Exiting.${reset}"
  exit 1
elif [ ! -f "install.php" ] ; then
  echo "${redf}Sorry, ${mainPath} doesn't appear to be a main Drupal directory (no install.php file). Exiting.${reset}"
  exit 1
elif [ ! -f "update.php" ] ; then
  echo "${redf}Sorry, ${mainPath} doesn't appear to be a main Drupal directory (no update.php file). Exiting.${reset}"
  exit 1
elif [ "grep --count --regexp='Drupal' index.php" '<' '1' ] ; then
  echo "${redf}Sorry, ${mainPath} doesn't appear to be a main Drupal directory ('Drupal' not in index.php). Exiting.${reset}"
  exit 1
elif [ "grep --count --regexp='Drupal' install.php" '<' '1' ] ; then
  echo "${redf}Sorry, ${mainPath} doesn't appear to be a main Drupal directory ('Drupal' not in install.php). Exiting.${reset}"
  exit 1
elif [ "grep --count --regexp='Drupal' update.php" '<' '1' ] ; then
  echo "${redf}Sorry, ${mainPath} doesn't appear to be a main Drupal directory ('Drupal' not in update.php). Exiting.${reset}"
  exit 1
elif [ x"$verbFlag" == x-v ] ; then
  echo "${greenf}Confirmed: this is a main Drupal directory. Continuing.${reset}"
fi

# Parse path

mainPath=$PWD

# get Drupal directory name

origIFS=$IFS
IFS="/"
for pdir in $mainPath ; do
    drupalDir=$pdir
done
IFS=$origIFS

if [ ! "$drupalDir" ] ; then
  echo "${redf}Sorry, there is a bug in the script. My bad. Exiting.${reset}"
  exit 1
fi

# Establish variables for backup directory

backupDir="DrupalBackups"

# cd $buDirLevel
do_and_feedback "$verbFlag" "cd ${buDirLevel}" "change directory to ${buDirLevel}"

topPath=$PWD

backupDirPath="${topPath}/${backupDir}"

# relBackupDir is the location of backupDir relative to mainPath
relBackupDirPath="${buDirLevel}/${backupDir}"

# Establish variable for date label

dateLabel=`date +%Y-%m-%d-%H%M%S`

# Establish first part of file names

if [ "$extraLabel" ] ; then
  archiveNamePart1="${drupalDir}-${dateLabel}-${extraLabel}-drupal"
  archiveUndatedNamePart1="most-recent-${drupalDir}-${extraLabel}-drupal"
else
  archiveNamePart1="${drupalDir}-${dateLabel}-drupal"
  archiveUndatedNamePart1="most-recent-${drupalDir}-drupal"
fi

# Establish full file names

filesArchiveName="${archiveNamePart1}-dir.tar.gz"
databaseArchiveName="${archiveNamePart1}-db.sql"

filesUndatedArchiveName="${archiveUndatedNamePart1}-dir.tar.gz"
databaseUndatedArchiveName="${archiveUndatedNamePart1}-db.sql"

# Check for backup directory, and if not there, create

if [ x"$verbFlag" == x-v ] ; then
  echo "Checking for ${backupDirPath} directory..."
fi

if [ -d "$backupDirPath" ] ; then # do nothing, DrupalBackups dir exists
  if [ x"$verbFlag" == x-v ] ; then
    echo "${greenf}It's there!${reset}"
  fi
else # make directory
  do_and_feedback "$verbFlag" "mkdir ${backupDirPath}" "make DrupalBackups directory"
fi

# Check whether files archive of same name already exists

if [ x"$verbFlag" == x-v ] ; then
  echo "Checking if ${backupDirPath}/${filesArchiveName} already exists..."
fi
if [ -f "${backupDirPath}/${filesArchiveName}" ] ; then
  echo "${redf}${backupDirPath}/${filesArchiveName} already exists! Exiting.${reset}"
  exit 1
elif [ x"$verbFlag" == x-v ] ; then
  echo "${greenf}It doesn't!${reset}"
fi

# Check whether database archive of same name already exists

if [ x"$verbFlag" == x-v ] ; then
  echo "Checking if  ${backupDirPath}/${databaseArchiveName} already exists..."
fi
if [ -f "${backupDirPath}/${databaseArchiveName}" ] ; then
  echo "${redf}${backupDirPath}/${databaseArchiveName} already exists! Exiting.${reset}"
  exit 1
elif [ x"$verbFlag" == x-v ] ; then
  echo "${greenf}It doesn't!${reset}"
fi

# Backup Drupal directory
# Done from immediately above directory, so no extra directories in paths in archive

do_and_feedback "$verbFlag" "cd ${mainPath}" "change directory to ${drupalDir}"
do_and_feedback "$verbFlag" "cd .." "change directory to just above ${drupalDir}"
if [ x"$verbFlag" == x-v ] ; then
  do_and_feedback "$verbFlag" "tar -vczf ${backupDirPath}/${filesArchiveName} ${drupalDir}" "backup Drupal directory"
else
  if [ x"$verbFlag" == x-t ] ; then
    echo "This next command can take awhile; please be patient."
  fi
  do_and_feedback "$verbFlag" "tar -czf ${backupDirPath}/${filesArchiveName} ${drupalDir}" "backup Drupal directory"
fi
do_and_feedback "$verbFlag" "cd ${drupalDir}" "change directory back to ${drupalDir}"

# Backup database (database dump)

if [ x"$verbFlag" == x-v ] ; then
  do_and_feedback "$verbFlag" "drush -v sql-dump --skip-tables-key=common --result-file=${backupDirPath}/${databaseArchiveName}" "backup Drupal database"
else
  if [ x"$verbFlag" == x-t ] ; then
    echo "This next command can take awhile; please be patient."
  fi
  do_and_feedback "$verbFlag" "drush sql-dump --skip-tables-key=common --result-file=${backupDirPath}/${databaseArchiveName}" "backup Drupal database"
fi

# Make undated named copies of archive files (to facilitate automated moving)

if [ "$prep" == "--prep" ] ; then
  do_and_feedback "$verbFlag" "cd ${backupDirPath}" "change directory to ${backupDirPath}"
  do_and_feedback "$verbFlag" "cp -f ${filesArchiveName} ${filesUndatedArchiveName}" "copy ${filesArchiveName} to ${filesUndatedArchiveName} (overwriting previous copy, if any)"
  do_and_feedback "$verbFlag" "cp -f ${databaseArchiveName} ${databaseUndatedArchiveName}" "copy ${databaseArchiveName} to ${databaseUndatedArchiveName} (overwriting previous copy, if any)"
fi

# Return to original drupal directory

do_and_feedback "$verbFlag" "cd ${mainPath}" "change directory back to ${mainPath}"

# Note successful completion.

if [ x"$verbFlag" != x-s ] ; then
  echo ""
  echo "${boldon}${greenf}Backup of ${drupalDir} Drupal directory and database complete.${reset}${boldoff}"
  echo ""
fi
