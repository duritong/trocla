# trocla
[![Build Status](https://travis-ci.org/duritong/trocla.png)](https://travis-ci.org/duritong/trocla)

Trocla provides you a simple way to create and store (random) passwords on a
central server, which can be retrieved by other applications. An example for
such an application is puppet and trocla can help you to not store any
plaintext or hashed passwords in your manifests by keeping these passwords only
on your puppetmaster.

Furthermore it provides you a simple cli that helps you to modify the password
storage from the cli.

Trocla does not only create and/or store a plain password, it is also able to
generate (and store) any kind of hashed passwords based on the plain password.
As long as the plain password is preset, trocla is able to generate any kind
of hashed passwords through an easy extendible plugin system.

It is not necessary to store the plain password on the server, you can also
just feed trocla with the hashed password and use that in your other tools.
A common example for that is that you let puppet retrieve (and hence create)
a salted md5 password for a user. This will then store the salted md5 of
a random password AND the plain text password in trocla. Later you can
retrieve (by deleting) the plain password and send it to the user. Puppet
will still simply retrieve the hashed password that is stored in trocla,
while the plain password is not anymore stored on the server.

Be default trocla uses moneta to store the passwords and can use any kind of
key/value based storage supported by moneta for trocla. By default it uses a
simple yaml file.
However, since version 0.2.0 trocla also supports a pluggable store backend
which allows you to write your custom backend. See more about stores below.

## Usage

### create

Assuming that we have an empty trocla storage.

    trocla create user1 plain

This will create (if not already stored in trocla) a random password and
store its plain text under key user1. The password will also be returned
by trocla.

    trocla create user2 mysql

This will create a random password and store its plain and mysql-style hashed
sha1 password in trocla. The hashed password is returned.

    trocla create user1 mysql

This will take the already stored plain text password of key user1 and generate
and store the mysql-style hashed sha1 password.

It is possible that certain hash formats require additional options. For example
the pgsql hash requires also the user to create the md5 hash for the password.
You can pass these additional requirements as yaml-based strings to the format:

    trocla create user1 pgsql 'username: user1'

This will create a pgsql password hash using the username user1.

Valid global options are:

* length: int - Define any lenght that a newly created password should have. Default: 16 - or whatever you define in your global settings.
* charset: (default|alphanumeric|shellsafe) - Which set of chars should be used for a random password? Default: default - or whatever you define in your global settings.
* profiles: a profile name or an array of profiles matching a profile_name in your configuration. Learn more about profiles below.
* random: boolean - Whether we allow creation of random passwords or we expect a password to be preset. Default: true - or whatever you define in your global settings.

Example:

    trocla create some_shellsafe_password plain 'charset: shellsafe'
    trocla create another_alphanumeric_20_char_password plain "charset: alphanumeric
    length: 20"

### get

Get simply returns a stored password. It will not create a new password.

Assuming that we are still working with the same storage

    trocla get user2 plain

will return the plain text password of the key user2.

    trocla get user3 plain

This will return nothing, as no password with this format have been stored so
far.

### set

    trocla set user3 plain

This will ask you for a password and set it under the appropriate key/format.

    trocla set --password mysupersecretpassword user4 plain

This will take the password from the cli without asking you.

    trocla set user5 mysql -p *ABC....

This will store a mysql sha1 hash for the key user5, without storing any kind
of plain text password.

You can also pipe in a password:

    echo -n foo | trocla set user6 plain -p

or a file

    cat some_file | trocla set user6 plain -p
    trocla set user6 plain -p < some_file

### reset

    trocla reset user1 md5crypt

This will recreate the salted md5 shadow-style hash. However, it will not create
a new plain text passwords. Hence, this is mainly usefull to create new hashed
passwords based on new salts.

If the plain password of a key is resetted, every already hashed password is
deleted as well, as the hashes wouldn't match anymore the plain text password.

### delete

    trocla delete user1 plain

This will delete the plain password of the key user1 and return it.

### formats

    trocla formats

This will list all available and supported formats.

## Attention

If you don't feed trocla initially with a hash and/or delete the generated
plain text passwords trocla will likely create a lot of plain text passwords
and store them on your machine/server. This is by intend and is all about which
problems (mainly passwords in configuration management manifests) trocla tries
to address. It is possible to store all passwords encrypted in the specific
backend.
See backend encryption for more information, however be aware that the key must
always also reside on the trocla node. So it mainly makes sense if you store
them on a remote backend like a central database server.

## Formats

Most formats are straight forward to use. Some formats require some additional
options to work properly. These are documented here:

### pgsql

Password hashes for PostgreSQL servers. Requires the option `username` to be set
to the username to which the password will be assigned.

### x509

This format takes a set of additional options. Required are:

    subject: A subject for the target certificate. E.g. /C=ZZ/O=Trocla Inc./CN=test/emailAddress=example@example.com
    OR
    CN: The CN of the the target certificate. E.g. 'This is my self-signed certificate which doubles as CA'

Additional options are:

    ca           The trocla key of CA (imported into or generated within trocla) that
                 will be used to sign that certificate.
    become_ca    Whether the certificate should become a CA or not. Default: false,
                 to enable set it to true.
    hash         Hash to be used. Default sha2
    keysize      Keysize for the new key. Default is: 4096
    serial       Serial to be used, default is selecting a random one.
    days         How many days should the certificate be valid. Default 365
    C            instead within the subject string
    ST           instead within the subject string
    L            instead within the subject string
    O            instead within the subject string
    OU           instead within the subject string
    emailAddress instead within the subject string
    altnames     An array of subjectAltNames

## Installation

Simply build and install the gem.

## Configuration

Trocla can be configured in /etc/troclarc.yaml and in ~/.troclarc.yaml. A sample configuration file can be found in `lib/trocla/default_config.yaml`.
By default trocla configures moneta to store all data in /tmp/trocla.yaml

### Profiles

It is possible to define profiles within the configuration file. The idea behind profiles are to make it easy to group together certain options for
automatic password generation.

Trocla ships with a default set of profiles, which are part of the `lib/trocla/default_config.yaml` configuration file. It is possible to override
the existing profiles within your own configuration file, as well as adding more. Note that the profiles part of the configuration file is merged
together and your configuration file has precedence.

The profiles part in the config is a hash where each entry consist of a name (key) and a hash of options (value).

Profiles make it especially easy to define a preset of options for SSL certificates as you will only need to set the certificate specific options,
while global options such as C, O or OU can be preset within the profile.

Profiles are used by setting the profiles option to a name of the pre-configured profiles, when passing options to the password option. On the cli
this looks like:

    trocla create foo plain 'profiles: rootpw'

It is possible to pass mutliple profiles as an array, while the order will also reflect the precedence of the options.

Also it is possible to set a default profiles option in the options part of the configuration file.

### Storage backends

Trocla has a pluggable storage backend, which allows you to choose the way that values are stored (persistently).
Such a store is a simple class that implements Trocla::Store and at the moment there are the following store implementations:

* Moneta - the default store using [moneta](https://rubygems.org/gems/moneta) to delegate storing the values
* Memory - simple inmemory backend. Mainly used for testing.

The backend is chosen based on the `store` configuration option. If it is a symbol, we expect it to be a store that we ship with trocla. Otherwise, we assume it to be a fully qualified ruby class name, that inherits from Trocla::Store. If trocla should load an additional library to be able to find your custom store class, you can set `store_require` to whatever should be passed to a ruby require statement.

Store backends can be configured through the `store_options` configuration.

#### Moneta backends

Trocla can store your passwords in all backends supported by moneta. A simple YAML file configuration may look as follows:

```YAML
store_options:
  adapter: :YAML
  adapter_options:
    :file: '/tmp/trocla.yaml'
```

In environments with multiple Puppet masters using an existing DB cluster might make sense. The configured user needs to be granted at least SELECT, INSERT, UPDATE, DELETE and CREATE permissions on your database:

```YAML
store_options:
  adapter: :Sequel
  adapter_options:
    :db: 'mysql://db.server.name'
    :user: 'trocla'
    :password: '***'
    :database: 'trocladb'
    :table: 'trocla'
```

These examples are by no way complete, moneta has much more to offer.

### Backend encryption

You might want to let Trocla encrypt all your passwords, at the moment the only supported way is SSL. By default trocla does not encrypt any passwords stored on the disk.

### Backend SSL encryption

Required configuration to enable ssl based encryption of all passwords:

```YAML
encryption: :ssl
encryption_options:
    :private_key: '/var/lib/puppet/ssl/private_keys/trocla.pem'
    :public_key: '/var/lib/puppet/ssl/public_keys/trocla.pem'
```

## Update & Changes

### to 0.2.0

1. Feature: Introduce profiles
1. Increase default password length to 16
1. Add a console safe password charset that should provide a subset of chars that easier to type on a physical keyboard.
1. Fix a bug with encryptions when deleting all formats
1. Introduce pluggable stores, so we can talk to other backends and not only moneta in the future
1. CHANGE: moneta adapter & adapter_options now live under store_options in the configuration file. Till 0.3.0 old configuration entries will be migrated on the fly.
1. CHANGE: ssl_options is now known as encryption_options. Till 0.3.0 old configuration entries will be migrated on the fly.

### to 0.1.3

1. CHANGE: Self signed certificates are no longer CAs by default, actually they have never been due to a bug. If you want that a certificate is also a CA, you *must* pass `become_ca: true` to the options hash. But this makes it actually possible, that you can even have certificate chains. Thanks for initial hint to [Adrien Bréfort](https://github.com/abrefort)
1. Default keysize is now 4096
1. SECURITY: Do not increment serial, rather choose a random one.
1. Fixing setting of altnames, was not possible due to bug, till now.
1. Add extended tests for the x509 format, that describe all the internal specialities and should give an idea how it can be used.
1. Add cli option to list all formats

### to 0.1.1

1. fix storing data longer that public Keysize -11. Thanks [Timo Goebel](https://github.com/timogoebel)
1. add a numeric only charset. Thanks [Jonas Genannt](https://github.com/hggh)
1. fix reading key expire time. Thanks [asquelt](https://github.com/asquelt)

### to 0.1.0

1. Supporting encryption of the backends. Many thanks to Thomas Gelf
1. Adding a windows safe password charset

### to 0.0.12

1. change from sha1 signature for the x509 format to sha2
1. Fix an issue where shellsafe characters might have already been initialized with shell-unsafe characters. Plz review any shell-safe character passwords regarding this problem. See the [fix](https://github.com/duritong/trocla/pull/19) for more information. Thanks [asquelt](https://github.com/asquelt) for the fix.

### to 0.0.8

1. be sure to update as well the moneta gem, trocla now uses the official moneta releases and supports current avaiable versions.
1. Options for moneta's backends have changed. For example, if you are using the yaml-backend you will likely need to change the adapter option `:path:` to `:file:` to match moneta's new API.
1. **IMPORTANT:** If you are using the yaml backend you need to migrate the current data *before* using the new trocla version! You can migrate the datastore by using the following two sed commands: `sed -i 's/^\s\{3\}/ /' /PATH/TO/trocla_data.yaml` && `sed -i '/^\s\{2\}value\:/d' /PATH/TO/trocla_data.yaml`.
1. **SECURITY:** Previous versions of trocla used quite a simple random generator. Especially in combination with the puppet `fqdn_rand` function, you likely have very predictable random passwords and I recommend you to regenerate all randomly generated passwords! Now!
1. We now support reading passwords from files, which means that you can now also easily add multi-line passwords. Have a look at the documentation above.

## Contributing to trocla
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011-2015 mh. See LICENSE.txt for
further details.

