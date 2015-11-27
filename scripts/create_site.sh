if [[ $# -eq 0 ]] ; then
    printf "\nMissing parameter: 'template tag', for example: wh_creator:nerdsandcompany\n\n"
    exit 1
fi

printf "\n## This script will create a new site using the default template ##\n\n"

# global variables
TEMPLATETAG=$1
DEBUGMODE=false #FIXME: Make this a param?
CREATE_SITE=true
MODS_DIR="$(wh getdatadir)installedmodules/"

# functions
function logstep()
{
  printf "## - $@ ##\n\n"
}

function converttofoldername()
{
  local str="$@"

  local output

  output=$(echo $str | tr '[:upper:]' '[:lower:]')
  output=$(echo $output | tr ' ' '_')

  echo $output
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
  git clone git@bitbucket.org:itmundi/webhare-projects-creator.git $foldername

  # delete the .git folder and initialize a new Git repo
  cd "$MODS_DIR$foldername"
  rm -rf .git/
  git init

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

function cleanup()
{
  local foldername="$@"

  logstep "Cleaning up"

  cd "$MODS_DIR$foldername"

  # remove obsolete files and folders
  rm -rf scripts/
  rm -rf data/
}

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
NAME=$(converttofoldername ${TITLE})

# perform functions
createrepository $NAME
updatefilecontents $NAME
if $CREATE_SITE; then
  runsetupscript $NAME
fi
cleanup $NAME

# print recap
printf "## ----------------------- Recap ----------------------- ##\n\n"

printf "Title: '$TITLE'\n"
printf "Folder/module name: '$NAME'\n"
printf "Installed into folder: $MODS_DIR$NAME/\n"

printf "\n## ----------------------- End of recap ---------------- ##\n\n"
