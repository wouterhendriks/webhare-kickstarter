# WebHare website builder

With this module, you can kickstart your new website by running a Bash script that will generate a basic module + site for you.

## To create a website

* If you don't have this repo yet, clone it as 'wh_creator':

```
git clone https://github.com/WouterHendriks/wh-creator.git "$(wh getdatadir)installedmodules/wh_creator"
```

* Run the following script to create the site:


```
$(wh getmoduledir wh_creator)scripts/create_site.sh wh_creator:nerdsandcompany
```

The 'wh_creator:nerdsandcompany' parameter is the template tag and specific for Nerds & Company. You can make and use your own, or use the default WebHare one:

```
publisher:blank
```

A new website should be created now. Refer to the output on how to move on.
