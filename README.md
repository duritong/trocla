# trocla
[![Ruby](https://github.com/duritong/trocla/actions/workflows/ruby.yml/badge.svg)](https://github.com/duritong/trocla/actions/workflows/ruby.yml)

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
a salted sha512 password for a user. This will then store the salted sha512 of
a random password AND the plain text password in trocla. Later you can
retrieve (by deleting) the plain password and send it to the user. Puppet
will still simply retrieve the hashed password that is stored in trocla,
while the plain password is not anymore stored on the server.

By default trocla uses moneta to store the passwords and can use any kind of
key/value based storage supported by moneta for trocla. By default it uses a
simple yaml file.
However, since version 0.2.0 trocla also supports a pluggable storage backend
which allows you to write your custom backend. See more about stores below.

Trocla can also be integrated into [Hiera](https://docs.puppetlabs.com/hiera/) by using ZeroPointEnergy's [hiera-backend](https://github.com/ZeroPointEnergy/hiera-backend-trocla).

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
* expires: An integer indicating the amount of seconds a value (e.g. password) is available. After expiration a value will not be available anymore and trying to `get` this key will return no value (nil). Meaning that calling create after expiration, would create a new password automatically. There is more about expiration in the storage backends section.
* render: A hash providing flags for formats to render the output specifially. This is a global option, but support depends on a per format basis.

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
We expect a plain password to be entered and will format the password with
the selected format before storing it.

    trocla set --password mysupersecretpassword user4 plain

This will take the password from the cli without asking you.

    trocla set user5 mysql -p mysuperdbpassword

This will store a mysql sha1 hash for the key user5, without storing any kind
of plain text password.
If you like trocla not to format a password, as you are passing in an already
formatted password (like the sha512 hash), then you must use `--no-format` to
skip formatting. Like:

    trocla set user5 sha512crypt --no-format -p '$6$1234$xxxx....'

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

Password hashes for PostgreSQL servers. Since postgesql 10 you can use the sha256 hash, you have two options:
* Create a ssh256 hash password with option `encode: sha256` (default value)
* Create a md5 hash, the username is require for the salt key, with option  `encode: md5` and `username: your_user`

### bcrypt

You are able to tune the [cost factor of bcrypt](https://github.com/codahale/bcrypt-ruby#cost-factors) by passing the option `cost`.
Note: ruby bcrypt does not support a [cost > 31](https://github.com/codahale/bcrypt-ruby/blob/master/lib/bcrypt/password.rb#L45).

### x509

This format takes a set of additional options. Required are:

    subject: A subject for the target certificate. E.g. /C=ZZ/O=Trocla Inc./CN=test/emailAddress=example@example.com
    OR
    CN: The CN of the the target certificate. E.g. 'This is my self-signed certificate which doubles as CA'

Additional options are:

    ca                The trocla key of CA (imported into or generated within trocla) that
                      will be used to sign that certificate.
    become_ca         Whether the certificate should become a CA or not. Default: false,
                      to enable set it to true.
    hash              Hash to be used. Default sha2
    keysize           Keysize for the new key. Default is: 4096
    serial            Serial to be used, default is selecting a random one.
    days              How many days should the certificate be valid. Default 365
    C                 instead within the subject string
    ST                instead within the subject string
    L                 instead within the subject string
    O                 instead within the subject string
    OU                instead within the subject string
    emailAddress      instead within the subject string
    key_usages        Any specific key_usages different than the default ones. If you specify
                      any, you must specify all that you want. If you don't want to have any,
                      you must specify an empty array.
    altnames          An array of subjectAltNames. By default for non CA certificates we
                      ensure that the CN ends up here as well. If you don't want that.
                      You need to pass an empty array.
    name_constraints  An array of domains that are added as permitted x509 NameConstraint.
                      By default, we do not add any contraint, meaning all domains are
                      signable by the CA, as soon as we have one item in the list, only
                      DNS entries matching this list are allowed. Be aware, that older
                      openssl versions have a bug with [leading dots](https://rt.openssl.org/Ticket/Display.html?id=3562) for name
                      constraints. So using them might not work everywhere as expected.

Output render options are:

    certonly       If set to true the x509 format will return only the certificate
    keyonly        If set to true the x509 format will return only the private key
    publickeyonly  If set to true the x509 format will return only the public key

### sshkey

This format generate a ssh keypair

Additional options are:

    type        The ssh key type (rsa, dsa). Default: rsa
    bits        Specifies the number of bits in the key to create. Default: 2048
    comment     Specifies a comment.
    passphrase  Specifies a passphrase.

Output render options are:

    pubonly     If set to true the sshkey format will return only the ssh public key
    privonly    If set to true the sshkey format will return only the ssh private key

### wireguard

This format generate a keypair for WireGuard.

The format requires the wg binary from WireGuard userland utilities.

Output render options are:

    pubonly     If set to true the wireguard format will return only the public key
    privonly    If set to true the wireguard format will return only the private key

## Installation

* Debian has trocla within its sid-release: `apt-get install trocla`
* For RHEL/CentOS 7 there is a [copr reporisotry](https://copr.fedoraproject.org/coprs/duritong/trocla/). Follow the help there to integrate the repository and install trocla.
* Trocla is also distributed as gem: `gem install trocla`

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
* Vault - modern secrets storage by HashiCorp, require the ruby gem [vault](https://github.com/hashicorp/vault-ruby)

The backend is chosen based on the `store` configuration option. If it is a symbol, we expect it to be a store that we ship with trocla. Otherwise, we assume it to be a fully qualified ruby class name, that inherits from Trocla::Store. If trocla should load an additional library to be able to find your custom store class, you can set `store_require` to whatever should be passed to a ruby require statement.

Store backends can be configured through the `store_options` configuration.

#### Expiration

We expect storage backends to implement support for the `expires` option, so that keys expire after the passed amount of seconds. Furthermore a storage backend needs to implement the behaviour described by the rspec shared_example 'store_validation' section 'expiration'. Mainly:

* Expiration is always for all formats per key.
* Adding, deleting or updating a format will keep the existing expiration, but reset the planned expiration.
* While setting a new plain format will not only erase all other formats, but also erase/reset any expires.
* Setting a value with an expires option of 0 or false, will remove any existent expiration.

New backends should be tested using the provided shared example.

> **WARNING**: Vault backend use metadatas. It's set if an option is define. `expires` is automaticly change to `delete_version_after`, and you can use an interger or [format string](https://www.vaultproject.io/api-docs/secret/kv/kv-v2#parameters)

#### Moneta backends

Trocla uses moneta as its default storage backend and hence can store your passwords in any of moneta's supported backends. By default it uses the yaml backend, which is configured as followed:

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

These examples are by no way complete, moneta has much more to offer. Please have a look at [moneta's documentation](https://github.com/minad/moneta/blob/master/README.md) for further information.

#### Vault backend

[Vault](https://www.vaultproject.io/) is a modern secret storage supported by HashiCorp, which works with a REST API. You can create multiple storage engine.

To use vault with trocla you need to create a kv (key/value) storage engine on the vault side. Trocla can use [v1](https://www.vaultproject.io/docs/secrets/kv/kv-v1) and [v2](https://www.vaultproject.io/docs/secrets/kv/kv-v2) API endpoints, but it's recommended to use the v2 (native hash object, history, acl...).

You need to install the `vault` gem to be able to use the vault backend, which is not included in the default dependencies for trocla.

With vault storage, the terminology changes:
* `mount`, this is the name of your kv engine
* `key`, this is the biggest change. As usual with trocla, the key is a simple string. With the vault kv engine, the key map to a path, so you can have a key like `my/path/key` for structured your data
* `secret`, is the data content of your key. This is a simple hash with key (format) and value (the secret content of your format)

The trocla mapping works the same way as with a moneta or file backend.

The `store_options` are a dynamic argument for initializer [Vault::Client](https://github.com/hashicorp/vault-ruby/blob/master/lib/vault/client.rb) class (except `:mount`, used to defined the kv name). You can define only one kv mount.

```YAML
store: :vault
store_options:
  :mount: kv
  :token: s.Tok3n
  :address: https://vault.local
```

With Vault when you delete a key, you don't delete all key content. The metadatas, like history, are still here and the endpoint are not delete. If you prefere to destroy all key content you can add `:destroy: true` in the `store_options:` hash.

### Backend encryption

By default trocla does not encrypt anything it stores. You might want to let Trocla encrypt all your passwords, at the moment the only supported way is SSL.
Given that often trocla's store is on the same system at it's being used, there might be little sense to encrypt everything while the encryption keys are on the same system. However, if you are for example using an existing DB cluster using backend encryption you won't store any plaintext passwords within the database system.

### Backend SSL encryption

To enable SSL encryption (e.g. by using your puppet masters SSL keys), you need to set the following configuration options:

```YAML
encryption: :ssl
encryption_options:
    :private_key: '/var/lib/puppet/ssl/private_keys/trocla.pem'
    :public_key: '/var/lib/puppet/ssl/public_keys/trocla.pem'
```

## Hooks

You can specify hooks to be called whenever trocla sets or deletes a password. The idea is that this allows you to run custom code that can trigger further actions based on deleting or setting a password.

Enabling hooks is done through the following configuration:

```YAML
hooks:
  set:
    my_hook: /path/to/my_hook_file.rb
  delete:
    other_hook: /path/to/my_other_hook_file.rb
```

A hook must have the following implementation based on the above config:

```Ruby
class Trocla
  module Hooks
    def self.my_hook(trocla, key, format, options)
      # [... your code ...]
    end
  end
end
```
You can specify only either one or both kinds of hooks.

Hooks must not raise any exceptions or interrupt the flow itself. They can also not change the value that was set or revert a deletion.

However, they have Trocla itself available (through `trocla`) and you must ensure to not create infinite loops.

## Update & Changes

See [Changelog](CHANGELOG.md)

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

