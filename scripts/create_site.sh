printf "\n## This script will create a new site using the default template ##\n\n"

# global variables
DEBUG=false
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

  #FIXME: Check for existing folder "$MODS_DIR/$foldername". If found, exit immediately.

  # clone the base repo
  #git clone git@bitbucket.org:itmundi/nerds-company-webhare-website-template.git $foldername
  cp -r /Users/wouter/projects/webhare/whtree/var/installedmodules/nc_base "$MODS_DIR$foldername"

  # delete the .git folder, initialize a new Git repo
  cd "$MODS_DIR$foldername"
  rm -rf .git/
  git init

  printf "\n"
}

function replaceplaceholders()
{
  logstep "Replacing placeholder texts with project's title"
  #perl -pi -e "s/xxdescriptionxx/$TITLE./g" moduledefinition.xml
}

function runsetupscript()
{
  logstep "Creating webdesign in repository and a new site in the Publisher"
  
  wh run modulescript::nc_base/setup_new_webdesign.whscr "$TITLE" "$NAME"
  wh softreset

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
if $DEBUG; then
  MODS_DIR="${MODS_DIR}ncbasetests/"
fi

# collect variables
printf "Enter the title for your project. Please make sure this is a unique title, since we don't have proper error checking yet.\n\n"
read -p "Title: " TITLE
printf "\n"

# debug: add timestamp to title
if $DEBUG; then
  TITLE=$TITLE$(date +"%Y%m%d%H%M%S")
fi

# convert title to friendly folder name
NAME=$(converttofoldername ${TITLE})

# perform functions
createrepository $NAME
replaceplaceholders
if $CREATE_SITE; then
  runsetupscript
fi
#cleanup $NAME

# print recap
printf "## ----------------------- Recap ----------------------- ##\n\n"

printf "Title: '$TITLE'\n"
printf "Folder/module name: '$NAME'\n"
printf "Installed into folder: $MODS_DIR$NAME/\n"

printf "\n## ----------------------- End of recap ---------------- ##\n\n"


#printf "$out\n\n";


#printf "Please enter the name of your project\n"
#read -p "IP [31.7.4.77]: " IP
#IP=${IP:-31.7.4.77}
