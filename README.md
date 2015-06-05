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
generate (and store) any kind hashed passwords based on the plain password.
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

You can use any kind of key/value based storage supported by moneta for
trocla. By default it uses a simple yaml file.

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

* length: int - Define any lenght that a newly created password should have. Default: 12 - or whatever you define in your global settings.
* charset: (default|alphanumeric|shellsafe) - Which set of chars should be used for a random password? Default: default - or whatever you define in your global settings.

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

## Attention

If you don't feed trocla initially with a hash and/or delete the generated
plain text passwords trocla will likely create a lot of plain text passwords
and store them on your machine/server. This is by intend and is all about which
problems (mainly passwords in configuration management manifests) trocla tries
to address.

## Installation

Simply build and install the gem. 

## Configuration

Trocla can be configured in /etc/troclarc.yaml and in ~/.troclarc.yaml. A sample configuration file can be found in `lib/trocla/default_config.yaml`.

### Storage backends

Trocla can store your passwords in all backends supported by moneta. A simple YAML file configuration may look as follows:

```YAML
adapter: :YAML
adapter_options:
    :file: '/tmp/trocla.yaml'
```

In environments with multiple Puppet masters using an existing DB cluster might make sense. The configured user needs to be granted at least SELECT, INSERT, UPDATE, DELETE and CREATE permissions on your database:

```YAML
adapter: :Sequel
adapter_options:
    :db: 'mysql://db.server.name'
    :user: 'trocla'
    :password: '***'
    :database: 'trocladb'
    :table: 'trocla'
```

These examples are by no way complete, moneta has much more to offer.

### SSL encryption

You might want to let Trocla encrypt all your passwords

```YAML
encryption: :ssl
ssl_options:
    :private_key: '/var/lib/puppet/ssl/private_keys/trocla.pem'
    :public_key: '/var/lib/puppet/ssl/public_keys/trocla.pem'
```

## Update & Changes

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

