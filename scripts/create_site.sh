#!/usr/bin/env bash

# ==============================================================================
#/ Webhare -- Website Creator
#/ ------------------------------------------------------------------------------
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
#/ ------------------------------------------------------------------------------
#/ The following ExitCodes are used:
#/
#/ 1 or 64  : General Error
#/
#/ 65 : Not enough parameters given
#/ 66 : The `wh` command is not available
#/ 67 : Webhare is not running
# ==============================================================================

set -o nounset # exit on use of an uninitialised variable, same as -u
set -o errexit # exit on all and any errors, same as -e

# ==============================================================================
# global variables
# ------------------------------------------------------------------------------
declare CREATE_SITE
declare DEBUGMODE
declare MODS_DIR
declare FOLDER_NAME
declare TEMPLATETAG
declare TITLE

readonly SOURCE_REPOSITORY='https://github.com/WouterHendriks/wh-creator.git'
# ==============================================================================

# ==============================================================================
# functions
# ------------------------------------------------------------------------------
fullUsage() {
  #/ Displays all lines in main script that start with '#/'
  grep '^#/' <"$0" | cut -c4-
}

shortUsage() {
  echo -e 'Usage:\n\n\t$(wh getmoduledir wh_creator)scripts/create_site.sh' "$*\n"
}

function printError()
{
  printf "\n\033[1;31m! \tERROR: $*\033[0m\n\n" >&2
}

function printTopic()
{
    echo -e "\n=====> $*"
}

function printStatus()
{
    echo "-----> $*"
}

function isInstalled() {
    return "$(command -v "${1}" >/dev/null 2>&1)"
}

function converttofoldername()
{
  echo "$@" | tr '[:upper:][:punct:] ' '[:lower:]_'
}

function cloneRepository()
{
  local sourceRepository="$1"
  local projectDirectory="$2"

  printTopic "Cloning source repository"
  if $DEBUGMODE; then
    printStatus "Copying from '$(wh getmoduledir wh_creator)' to '${projectDirectory}'"
    cp -r "$(wh getmoduledir wh_creator)" "${projectDirectory}"
  else
     git clone "$sourceRepository" "${projectDirectory}"
  fi
}

function cleanRepository()
{
 local projectDirectory="$1"

  printTopic 'Cleaning up the newly created repository'
  printStatus 'Deleting old .git folder'
  rm -rf "${projectDirectory}/.git/"
  printStatus 'Navigating to the modules directory'
  pushd "${projectDirectory}" > /dev/null
  printStatus 'Initializing a new Git repository'
  git init && git commit --allow-empty -m 'Initial commit.'
  popd
}

function createrepository()
{
 local projectDirectory="$1"
 local projectTitle="$2"

  cloneRepository "${SOURCE_REPOSITORY}" "${projectDirectory}"
  cleanRepository "${projectDirectory}"
  replacereadme "${projectDirectory}" "${projectTitle}"
}

function updatefilecontents()
{
  projectDirectory="$1"
  projectTitle="$2"

  printTopic 'Updating file contents'

  sed -i '' "s/xxdescriptionxx/${projectTitle}/g" "${projectDirectory}/moduledefinition.xml"
  sed -i '' '/<webdesign /d' "${projectDirectory}/moduledefinition.xml"
}

function runsetupscript()
{
  projectDirectory="$1"
  projectTitle="$2"

  printTopic 'Creating webdesign in repository and a new site in the Publisher'

  printStatus 'Restarting Webhare'
  wh softreset # is needed because the script expects an already initialized wh_creator module, would be nice if the WH script could take care of this

  printStatus 'Asking Webhare to run the webdesign script'
  wh run "${projectDirectory}/scripts/setup_new_webdesign.whscr" "${projectTitle}" "$FOLDER_NAME" "$TEMPLATETAG"
}

function replacereadme()
{
  projectDirectory="$1"
  projectTitle="$2"

  printStatus 'Replacing README contents'

  cat <<EOF > "${projectDirectory}/README.md"
# ${projectTitle}

## URLs
Your test/live URLs here

## Backend
Your backend URLs here

## Installation
```
git clone URL-to-Git-repository "\$(wh getdatadir)installedmodules/${FOLDER_NAME}"
```

## To satisfy the module dependencies:
- whcd ${FOLDER_NAME}/webdesigns/${FOLDER_NAME}/
- if whcd is unavailable, try cd "\$(wh getmoduledir ${FOLDER_NAME})webdesigns/${FOLDER_NAME}/"
- wh noderun npm install
- wh noderun bower install
EOF
}

function cleanup()
{
 local projectDirectory="$1"

  printTopic 'Cleaning up'

  printStatus 'Removing obsolete files and folders'
  rm -rf "${projectDirectory}/scripts/"
  rm -rf "${projectDirectory}/data/"
}

function checkConstraints()
{
  if [[ $# -eq 0 ]] ; then
    printError 'Missing parameter: "template name", for example: wh_creator:nerdsandcompany'
    shortUsage '[template_name]'
    exit 65
  elif [[ "$1" == '--help' ]] || [[ "$1" == '-h' ]]; then
    fullUsage
    exit 0
  elif [[ $(isInstalled 'wh') -ne 0 ]] ; then
    printError 'Webhare binary is not installed (or or not properly aliased)'
    exit 66
  elif [[ "$(wh isrunning)" -ne 0 ]];then
    printError 'Webhare does not seem to be running. Please (re)start Webhare and try again'
    exit 67
  fi
}

function setGlobalVariables()
{
  TEMPLATETAG="$1"
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
  while read -r -p 'Title: ' TITLE && [[ -z "$TITLE" ]] ; do
    printf "\nPlease enter something!\n\n"
  done

  printf "\n"

  setFolderNameFromTitle

  if [ -d "${MODS_DIR}${FOLDER_NAME}" ]; then
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
  FOLDER_NAME=$(converttofoldername "${TITLE}")
}
# ==============================================================================

# ==============================================================================
#
# ------------------------------------------------------------------------------
checkConstraints "$@"
printf "\n## This script will create a new site using the default template ##\n\n"
setGlobalVariables "$@"
askForTitle
createrepository "${MODS_DIR}${FOLDER_NAME}" "${TITLE}"
updatefilecontents "${MODS_DIR}${FOLDER_NAME}" "${TITLE}"
if ${CREATE_SITE}; then
  runsetupscript "${MODS_DIR}${FOLDER_NAME}" "${TITLE}"
fi
cleanup "${MODS_DIR}${FOLDER_NAME}"
# ==============================================================================

#EOF
