# Changelog

## to 0.3.0 (unreleased)

* Add open method to be able to immediately close a trocla store after using it - thanks martinpfeiffer
* Add typesafe charset - thanks hggh
* Support cost option for bcrypt
* address concurrency corner cases, when 2 concurrent threads or even processes
  are currently calculating the same (expensive) format.
* parse additional options on cli (#39 & #46) - thanks fe80

## to 0.2.3

1. Add extended CA validity profiles
1. Make it possible to define keyUsage

## to 0.2.2

1. Bugfix to render output correctly also on an already existing set
1. Fix tests not working around midnight, due to timezone differences

## to 0.2.1

1. New Feature: Introduce a way to render specific formats, mainly this allows you to control the output of a specific format. See the x509 format for more information.

## to 0.2.0

1. New feature profiles: Introduce profiles to make it easy to have a default set of properties. See the profiles section for more information.
1. New feature expiration: Make it possible that keys can have an expiration. See the expiration section for more information.
1. Increase default password length to 16.
1. Add a console safe password charset. It should provide a subset of chars that are easier to type on a physical keyboard.
1. Fix a bug with encryptions while deleting all formats.
1. Introduce pluggable stores, so in the future we are able to talk to different backends and not only moneta. For testing and inspiration a simple in memory storage backend was added.
1. CHANGE: moneta's configuration for `adapter` & `adapter_options` now live under store_options in the configuration file. Till 0.3.0 old configuration entries will still be accepted.
1. CHANGE: ssl_options is now known as encryption_options. Till 0.3.0 old configuration entries will still be accepted.
1. Improve randomness when creating a serial number.
1. Add a new charset: hexadecimal
1. Add support for name constraints within the x509 format
1. Clarify documentation of the set action, as well as introduce `--no-format` for the set action.

## to 0.1.3

1. CHANGE: Self signed certificates are no longer CAs by default, actually they have never been due to a bug. If you want that a certificate is also a CA, you *must* pass `become_ca: true` to the options hash. But this makes it actually possible, that you can even have certificate chains. Thanks for initial hint to [Adrien Bréfort](https://github.com/abrefort)
1. Default keysize is now 4096
1. SECURITY: Do not increment serial, rather choose a random one.
1. Fixing setting of altnames, was not possible due to bug, till now.
1. Add extended tests for the x509 format, that describe all the internal specialities and should give an idea how it can be used.
1. Add cli option to list all formats

## to 0.1.1

1. fix storing data longer that public Keysize -11. Thanks [Timo Goebel](https://github.com/timogoebel)
1. add a numeric only charset. Thanks [Jonas Genannt](https://github.com/hggh)
1. fix reading key expire time. Thanks [asquelt](https://github.com/asquelt)

## to 0.1.0

1. Supporting encryption of the backends. Many thanks to Thomas Gelf
1. Adding a windows safe password charset

## to 0.0.12

1. change from sha1 signature for the x509 format to sha2
1. Fix an issue where shellsafe characters might have already been initialized with shell-unsafe characters. Plz review any shell-safe character passwords regarding this problem. See the [fix](https://github.com/duritong/trocla/pull/19) for more information. Thanks [asquelt](https://github.com/asquelt) for the fix.

## to 0.0.8

1. be sure to update as well the moneta gem, trocla now uses the official moneta releases and supports current avaiable versions.
1. Options for moneta's backends have changed. For example, if you are using the yaml-backend you will likely need to change the adapter option `:path:` to `:file:` to match moneta's new API.
1. **IMPORTANT:** If you are using the yaml backend you need to migrate the current data *before* using the new trocla version! You can migrate the datastore by using the following two sed commands: `sed -i 's/^\s\{3\}/ /' /PATH/TO/trocla_data.yaml` && `sed -i '/^\s\{2\}value\:/d' /PATH/TO/trocla_data.yaml`.
1. **SECURITY:** Previous versions of trocla used quite a simple random generator. Especially in combination with the puppet `fqdn_rand` function, you likely have very predictable random passwords and I recommend you to regenerate all randomly generated passwords! Now!
