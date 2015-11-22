"use strict";

module.exports.getSiteConfig = function()
{
  var whconfigel = document.querySelector('script#wh-config');

  // Make sure we have obj/site as some sort of object, to prevent crashes on naive 'if ($wh.config.obj.x)' tests'
  var siteconfig = whconfigel ? JSON.parse(whconfigel.textContent) : {};

  if (!siteconfig.obj) {
    siteconfig.obj = {};
  }
  
  if (!siteconfig.site) {
    siteconfig.site = {};
  }

  return siteconfig;
};
