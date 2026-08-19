# Introduction

Koha’s Plugin System (available in Koha 3.12+) allows for you to add additional tools and reports to [Koha](http://koha-community.org) that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work. Learn more about the Koha Plugin System in the [Koha 3.22 Manual](http://manual.koha-community.org/3.22/en/pluginsystem.html) or watch [Kyle’s tutorial video](http://bywatersolutions.com/2013/01/23/koha-plugin-system-coming-soon/).

# Downloading

From the [release page](https://github.com/bywatersolutions/koha-plugin-pay-via-paygov/releases) you can download the relevant *.kpz file

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

* Change `<enable_plugins>0<enable_plugins>` to `<enable_plugins>1</enable_plugins>` in your koha-conf.xml file
* Confirm that the path to `<pluginsdir>` exists, is correct, and is writable by the web server
* Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.


# Encrypting the API password

The PayGov API password is encrypted at rest using Koha's own encryption, which needs an
`encryption_key` in `koha-conf.xml`. Koha does not generate one for you — a fresh instance ships
the placeholder `__ENCRYPTION_KEY__`, and Koha reports this on the About page.

```xml
<encryption_key>a random string of at least 32 bytes</encryption_key>
```

`pwgen 32 1` produces a suitable value. Restart Koha after adding it.

If no key is configured the plugin still works, but the password stays in cleartext and the
configuration page shows a warning. Once a key is set, the stored password is encrypted
automatically the next time the plugin is upgraded or its configuration page is opened.

Changing `encryption_key` after the password has been encrypted makes it unrecoverable. Payments
will fail with a clear error until the password is re-entered on the configuration page.

Note that PayGov's integration requires the password as a field in the payment form the patron's
browser submits to PayGov, so it appears in the OPAC page source at payment time. That is the
vendor's documented design; encrypting the stored copy does not change it.
