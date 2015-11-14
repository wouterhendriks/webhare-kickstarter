# WebHare website builder

With this module, you can kickstart your new website by running a Bash script that will generate a basic module + site for you.

## To create a website

* If you don't have this repo yet, create it as 'nc_base':

```
#!bash

cd "$(wh getdatadir)installedmodules/"
git clone git@bitbucket.org:itmundi/webhare-projects-creator.git nc_base

```

* Run the following script to create the site:


```
#!bash

~/mods/nc_base/scripts/create_site.sh

```

A new website should be created now. Refer to the output on how to move on.