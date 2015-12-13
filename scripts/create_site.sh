#!/usr/bin/env bash

# ==============================================================================
# functions
# ------------------------------------------------------------------------------
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

  #FIXME: Would be nice to do this in the title question
  if [ -d "$foldername" ]; then
    printf "## ERROR! Based on this title we would create this folder:\n\n- $MODS_DIR$foldername\n\nBut alas, it already exists so nothing was done. Please run again with another title. Exiting.\n\n"
    exit 1
  fi

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
# ==============================================================================


# ==============================================================================
#
# ------------------------------------------------------------------------------
if [[ $# -eq 0 ]] ; then
    printf "\nMissing parameter: 'template tag', for example: wh_creator:nerdsandcompany\n\n"
    exit 1
fi

printf "\n## This script will create a new site using the default template ##\n\n"

# global variables
TEMPLATETAG=$1
DEBUGMODE=false #FIXME: Make this a param?; assumes /.../installedmodules/ncbasetests/ exists
CREATE_SITE=true
MODS_DIR="$(wh getdatadir)installedmodules/"

# debug: use a test folder for the modules
if $DEBUGMODE; then
  MODS_DIR="${MODS_DIR}ncbasetests/"
fi

# ask user for the title
printf "Enter the title for your project. Please make sure this is a unique title, since we don't have proper error checking yet.\n\n"
while read -p 'Title: ' TITLE && [[ -z "$TITLE" ]] ; do
  printf "\nPlease enter something!\n\n"
done

printf "\n"

# debug: add timestamp to title
if $DEBUGMODE; then
  TITLE=$TITLE$(date +"%Y%m%d%H%M%S")
fi

# convert title to friendly folder name
NAME=$(converttofoldername "${TITLE}")

# perform functions
createrepository $NAME
updatefilecontents $NAME
if $CREATE_SITE; then
  runsetupscript $NAME
fi
cleanup $NAME
