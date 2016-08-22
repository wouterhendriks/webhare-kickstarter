# WebHare website kickstarter

With this module, you can kickstart your new website by running a Bash script that will generate a basic module + (webdesign) site for you.

## To create a website

* If you don't have this repo yet, clone it as 'webhare_kickstarter':
```
git clone git@gitlab.com:webwerf/webhare-kickstarter.git "$(wh getdatadir)installedmodules/webhare_kickstarter"
```

* Run the following script to create the site:
```
$(wh getmoduledir webhare_kickstarter)scripts/create_site.sh
```

A new website should be created now. Refer to the output on how to move on.
