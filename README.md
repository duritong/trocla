# trocla

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

    trocla set --pwd-from-stdin user4 plain mysupersecretpassword

This will take the password from the cli without asking you.

    trocla set --pwd-from-stdin user5 mysql *ABC....

This will store a mysql sha1 hash for the key user5, without storing any kind
of plain text password.

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

## Contributing to trocla
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2011 mh. See LICENSE.txt for
further details.

