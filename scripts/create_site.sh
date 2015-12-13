#!/usr/bin/env bash

# ==============================================================================
#/ Webhare -- Website Creator
# ------------------------------------------------------------------------------
#/ This script will will generate a basic module and site for Webhare
#/
#/ To create a site, run as follows:
#/
#/     $(wh getmoduledir wh_creator)scripts/create_site.sh [template_name]
#/
#/ Where "template_name" specifies a template. To use the default template run:
#/
#/     $(wh getmoduledir wh_creator)scripts/create_site.sh 'publisher:blank'
#/
#/ To run with the template specific for Nerds & Company, run:
#/
#/     $(wh getmoduledir wh_creator)scripts/create_site.sh 'wh_creator:nerdsandcompany'
#/
#/ The script will ask for a project name.
#/
## ==============================================================================

set -o nounset # exit on use of an uninitialised variable, same as -u
set -o errexit # exit on all and any errors, same as -e

# ==============================================================================
# global variables
# ------------------------------------------------------------------------------
declare CREATE_SITE
declare DEBUGMODE
declare MODS_DIR
declare NAME
declare TEMPLATETAG
declare TITLE
# ==============================================================================

# ==============================================================================
# functions
# ------------------------------------------------------------------------------
fullUsage() {
  #/ Displays all lines in main script that start with '#/'
  grep '^#/' <"$0" | cut -c4-
}

shortUsage() {
  echo -e 'Usage:\n\t$(wh getmoduledir wh_creator)scripts/create_site.sh' "$*\n"
}

function printError()
{
  echo -e "\n !     ERROR: $*\n" >&2
}

function isInstalled() {
    return $(command -v "${1}" >/dev/null 2>&1);
}

function logstep()
{
  printf "## - $@ ##\n\n"
}

function converttofoldername()
{
  echo "$@" | tr '[:upper:][:punct:] ' '[:lower:]_'
}

function createrepository()
{
  local foldername="$@"

  logstep "Creating folder and initializing new Git repository"

  # go to the modules directory
  cd "$MODS_DIR"

  # clone the base repo and save it under the new name
  if $DEBUGMODE; then
    cp -r "$(wh getmoduledir wh_creator)" $foldername
  else
    git clone https://github.com/WouterHendriks/wh-creator.git $foldername
  fi

  # delete the .git folder and initialize a new Git repo
  cd "$MODS_DIR$foldername"
  rm -rf .git/
  git init
  git commit --allow-empty -m 'Initial commit.'

  # remove and add a new README.MD
  replacereadme

  printf "\n"
}

function updatefilecontents()
{
  local foldername="$@"

  logstep "Updating file contents"

  cd "$MODS_DIR$foldername"

  sed -i '' "s/xxdescriptionxx/$TITLE/g" moduledefinition.xml
  sed -i '' '/<webdesign /d' moduledefinition.xml
}

function runsetupscript()
{
  local foldername="$@"

  logstep "Creating webdesign in repository and a new site in the Publisher"

  wh softreset # is needed because the script expects an already initialized wh_creator module, would be nice if the WH script could take care of this
  wh run "$MODS_DIR$foldername/scripts/setup_new_webdesign.whscr" "$TITLE" "$NAME" "$TEMPLATETAG"

  printf "\n"
}

function replacereadme()
{
  # generate text
  read -d '' readmetext <<EOF
# $TITLE

## URLs
Your test/live URLs here

## Backend
Your backend URLs here

## Installation
git clone <URL-to-Git-repository> "\$(wh getdatadir)installedmodules/$NAME"

## To satisfy the module dependencies:
- whcd $NAME/webdesigns/$NAME/
- if whcd is unavailable, try cd "\$(wh getmoduledir $NAME)webdesigns/$NAME/"
- wh noderun npm install
- wh noderun bower install
EOF

  # remove old file and add new one
  rm README.md
  echo "$readmetext" >> README.md
}

function cleanup()
{
  local foldername="$@"

  cd "$MODS_DIR$foldername"

  # remove obsolete files and folders
  rm -rf scripts/
  rm -rf data/
}

function checkConstraints()
{
  if [[ $(isInstalled 'wh') -eq 0 ]] ; then
    if [[ $# -eq 0 ]] ; then
        printError 'Missing parameter: "template name", for example: wh_creator:nerdsandcompany'
        shortUsage '[template_name]'
        exit 65
    fi
  else
    printError 'Webhare binary is not installed (or or not properly aliased)'
    exit 66
  fi

    if [[ "$1" == '--help' ]] || [[ "$1" == '-h' ]]; then
      fullUsage
      exit 0
    fi
}

function setGlobalVariables()
{
  TEMPLATETAG=$1
  DEBUGMODE=false #FIXME: Make this a param?; assumes /.../installedmodules/ncbasetests/ exists
  CREATE_SITE=true
  MODS_DIR="$(wh getdatadir)installedmodules/"

  # debug: use a test folder for the modules
  if $DEBUGMODE; then
    MODS_DIR="${MODS_DIR}ncbasetests/"
  fi
}

function getTitleFromUser()
{
  while read -p 'Title: ' TITLE && [[ -z "$TITLE" ]] ; do
    printf "\nPlease enter something!\n\n"
  done

  printf "\n"

  if [ -d "$MODS_DIR$NAME" ]; then
    echo 'A directory for given title already exists. Please try another title.'
    TITLE=''
    getTitleFromUser
  fi

}

function askForTitle()
{
  printf "Enter the title for your project. Please make sure this is a unique title, since we don't have proper error checking yet.\n\n"

  getTitleFromUser

  if $DEBUGMODE; then
    # debug: add timestamp to title
    TITLE=$TITLE$(date +"%Y%m%d%H%M%S")
  fi
}

function setFolderNameFromTitle()
{
  NAME=$(converttofoldername "${TITLE}")
}
# ==============================================================================


# ==============================================================================
#
# ------------------------------------------------------------------------------
checkConstraints $@
printf "\n## This script will create a new site using the default template ##\n\n"
setGlobalVariables $@
askForTitle
setFolderNameFromTitle
createrepository $NAME
updatefilecontents $NAME
if $CREATE_SITE; then
  runsetupscript $NAME
fi
cleanup $NAME

#EOF
