#!/usr/bin/env bash

# ==============================================================================
#/ WebHare -- Website Creator
#/ ------------------------------------------------------------------------------
#/ This script will will generate a basic module and site for WebHare, based on a specific Nerds & Company template
#/
#/ To create a site, run as follows:
#/
#/     $(wh getmoduledir webhare_kickstarter)scripts/create_site.sh
#/
#/ The script will ask for a project title, which will automatically be converted to a proper folder name.
#/
#/ ------------------------------------------------------------------------------
#/ The following ExitCodes are used:
#/
#/ 1 or 64  : General Error
#/
#/ 66 : The `wh` command is not available
#/ 67 : WebHare is not running
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

readonly SOURCE_REPOSITORY='git@bitbucket.org:itmundi/webhare-kickstarter.git'
# ==============================================================================

# ==============================================================================
# functions
# ------------------------------------------------------------------------------
fullUsage() {
  #/ Displays all lines in main script that start with '#/'
  grep '^#/' <"$0" | cut -c4-
}

shortUsage() {
  echo -e 'Usage:\n\n\t$(wh getmoduledir webhare_kickstarter)scripts/create_site.sh' "$*\n"
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

#function isInstalled() {
#    return "$(command -v "${1}" >/dev/null 2>&1)"
#}

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
    printStatus "Copying from '$(wh getmoduledir webhare_kickstarter)' to '${projectDirectory}'"
    cp -r "$(wh getmoduledir webhare_kickstarter)" "${projectDirectory}"
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
  git init && git add . && git commit -m 'Initial revision'
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

  sed -i '' "s/REPLACEtitleREPLACE/${projectTitle}/g" "${projectDirectory}/moduledefinition.xml"
  sed -i '' "s/REPLACEfoldernameREPLACE/${FOLDER_NAME}/g" "${projectDirectory}/moduledefinition.xml"
  sed -i '' '/<webdesign /d' "${projectDirectory}/moduledefinition.xml"
}

function runsetupscript()
{
  projectDirectory="$1"
  projectTitle="$2"

  printTopic 'Creating webdesign in repository and a new site in the Publisher'

  printStatus 'Restarting WebHare'
  wh softreset # is needed because the script expects an already initialized webhare_kickstarter module, would be nice if the WH script could take care of this

  printStatus 'Asking WebHare to run the webdesign script'
  wh run "${projectDirectory}/scripts/setup_new_webdesign.whscr" "${projectTitle}" "$FOLDER_NAME" "$TEMPLATETAG"

  wh sitemgr zip "${projectTitle}"
}

function replacereadme()
{
  projectDirectory="$1"
  projectTitle="$2"

  printStatus 'Replacing README contents'

  cat <<EOF > "${projectDirectory}/README.md"
# ${projectTitle}

## URLs
Your live/test/acceptance URLs here

## Backend
Your backend URLs here

## Installation
\`\`\`
#!bash
# Clone the repo and save as '${FOLDER_NAME}'
git clone <URL-to-Git-repository> "\$(wh getdatadir)installedmodules/${FOLDER_NAME}"

# Make sure WebHare knows about this module
wh softreset

## Satisfy the module dependencies
whcd ${FOLDER_NAME}/webdesigns/${FOLDER_NAME}/
wh noderun npm install
wh noderun bower install
# if whcd is unavailable, try:
# cd "\$(wh getmoduledir ${FOLDER_NAME})webdesigns/${FOLDER_NAME}/"

# Install the site
wh sitemgr install '${projectTitle}'
\`\`\`
EOF
}

function cleanup()
{
 local projectDirectory="$1"

  printTopic 'Cleaning up'

  printStatus 'Removing obsolete files and folders'
  rm -rf "${projectDirectory}/scripts/"
  rm -rf "${projectDirectory}/data/webdesigntemplates/"
}

function checkConstraints()
{
  if [[ "$0" == '--help' ]] || [[ "$0" == '-h' ]]; then
    fullUsage
    exit 0
  #elif [[ $(isInstalled 'wh') -ne 0 ]] ; then
  #  printError 'WebHare binary is not installed (or or not properly aliased)'
  #  exit 66
  elif [[ "$(wh isrunning)" -ne 0 ]];then
    printError 'WebHare does not seem to be running. Please (re)start WebHare and try again'
    exit 67
  fi
}

function setGlobalVariables()
{
  TEMPLATETAG="webhare_kickstarter:nerdsandcompany"
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
  printf "Enter the title for your project. A (folder) name, based on this title, will be generated automagically.\n\n"

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
