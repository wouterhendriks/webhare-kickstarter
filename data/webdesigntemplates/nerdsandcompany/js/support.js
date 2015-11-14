"use strict";

module.exports.getSiteConfig = function()
{
    var whconfigel = document.querySelector('script#wh-config');
    var siteconfig = whconfigel ? JSON.parse(whconfigel.textContent) : {};// Make sure we have obj/site as some sort of object, to prevent crashes on naive 'if ($wh.config.obj.x)' tests'
    if(!siteconfig.obj)
      siteconfig.obj={};
    if(!siteconfig.site)
      siteconfig.site={};

    return siteconfig;
}