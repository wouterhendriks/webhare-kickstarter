# WebHare website kickstarter

With this module, you can kickstart your new website by running a Bash script that will generate a basic module + (webdesign) site for you.

## To create a website

* If you don't have this repo yet, clone it as 'webhare_kickstarter':
```
git clone git@bitbucket.org:itmundi/webhare-kickstarter.git "$(wh getdatadir)installedmodules/webhare_kickstarter"
```

* Run the following script to create the site:
```
$(wh getmoduledir webhare_kickstarter)scripts/create_site.sh webhare_kickstarter:nerdsandcompany
```

The 'webhare_kickstarter:nerdsandcompany' parameter is the template tag and specific for Nerds & Company. You can make and use your own, or use the default WebHare one:
```
publisher:blank
```

A new website should be created now. Refer to the output on how to move on.
