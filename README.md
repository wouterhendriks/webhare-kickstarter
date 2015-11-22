# WebHare website builder

With this module, you can kickstart your new website by running a Bash script that will generate a basic module + site for you.

## To create a website

* If you don't have this repo yet, clone it as 'wh_creator':

```
#!bash

git clone git@bitbucket.org:itmundi/webhare-projects-creator.git "$(wh getdatadir)installedmodules/wh_creator"

```

* Run the following script to create the site:


```
#!bash

$(wh getmoduledir wh_creator)scripts/create_site.sh

```

A new website should be created now. Refer to the output on how to move on.