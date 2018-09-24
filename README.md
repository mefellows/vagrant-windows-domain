# Vagrant Windows Domain Plugin

[![Build Status](https://travis-ci.org/SEEK-Jobs/vagrant-windows-domain.svg)](https://travis-ci.org/SEEK-Jobs/vagrant-windows-domain)
[![Coverage Status](https://coveralls.io/repos/SEEK-Jobs/vagrant-windows-domain/badge.svg?branch=master)](https://coveralls.io/r/SEEK-Jobs/vagrant-windows-domain?branch=master)
[![Gem Version](https://badge.fury.io/rb/vagrant-windows-domain.svg)](http://badge.fury.io/rb/vagrant-windows-domain)

A Vagrant Plugin that makes connecting and disconnecting your Windows Vagrant box to a Windows Domain a cinch.

On a `vagrant up` - unless credentials are supplied - it will prompt the user for their domain credentials and add the guest to the domain, including restarting the guest without interfering with other provisioners. 

On a `vagrant destroy`, it will do the same and remove itself from the Domain, keeping things neat-n-tidy.

## Installation

```vagrant plugin install vagrant-windows-domain```

## Usage

In your Vagrantfile, add the following plugin and configure to your needs:

```ruby
config.vm.provision :windows_domain do |domain|

    # The Windows Domain to join.
    #
    # Setting this will result in an additional restart.
    domain.domain = "domain.int"

    # The new Computer Name to use when joining the domain.
    #
    # Uses the Rename-Computer PowerShell command.
    # Specifies a new name for the computer in the new domain.
    domain.computer_name = "myfandangledname"

    # The Username to use when authenticating against the Domain.
    #
    # Specifies a user account that has permission to join the computers to a new domain. 
    #
    # If not supplied the plugin will prompt the user during provisioning to provide one.
    domain.username = "me"

    # The Password to use when authenticating against the Domain.
    #
    # Specifies the password of a user account that has permission to 
    # join the computers to a new domain. 
    #
    # If not supplied the plugin will prompt the user during provisioning to provide one.
    domain.password = "iprobablyshouldntusethisfield"

    # IP address of primary DNS server
    #
    # Specifies the IP address you want assigned as the primary DNS server for the primary nic.
    # If not supplied, the nic's primary dns server will be assigned dynamically.
    domain.primary_dns = "8.8.8.8"
    
    #IP address of the secondary DNS server
    #
    # Specifies the IP address you want assigned as the secondary DNS server for the primary nic
    # If not supplied, the nic's secondary dns server will be assigned dynamically.
	domain.secondary_dns = "8.8.4.4"

    # The set of Advanced options to pass when joining the Domain.
    #
    # See (https://technet.microsoft.com/en-us/library/hh849798.aspx) for detail, these are generally not required.
    domain.join_options = [ "JoinReadOnly" ]

    # Organisational Unit path in AD.
    #
    # Specifies an organizational unit (OU) for the domain account. 
    # Enter the full distinguished name of the OU in quotation marks. 
    # The default value is the default OU for machine objects in the domain.
    domain.ou_path = "OU=testOU,DC=domain,DC=Domain,DC=com"

    # Performs an unsecure join to the specified domain.
    #
    # When this option is enabled username/password are not required and cannot be used.
    domain.unsecure = false
end
```
## Example

There is a [sample](https://github.com/SEEK-Jobs/vagrant-windows-domain/tree/master/development) Vagrant setup used for development of this plugin. 
This is a great real-life example to get you on your way.

### Supported Environments

Currently the plugin supports any Windows environment with Powershell 3+ installed (2008r2, 2012r2 should work nicely).

## Development

Before getting started, read the Vagrant plugin [development basics](https://docs.vagrantup.com/v2/plugins/development-basics.html) and [packaging](https://docs.vagrantup.com/v2/plugins/packaging.html) documentation.

You will need Ruby 2.1.5 and Bundler v1.12.5 installed before proceeding.

_NOTE_: it _must_ be bundler v1.12.5 due to a hard dependency in Vagrant at this time.

```
git clone git@github.com:mefellows/vagrant-dsc.git
cd vagrant-dsc
bundle install
```

Run tests:
```
bundle exec rake spec
```

Run Vagrant in context of current vagrant-dsc plugin:
```
cd <directory>
bundle exec vagrant up
```

There is a test Vagrant DSC setup in `./development` that is a good example of a simple acceptance test.

### Multiple Bundlers?

If you have multiple Bundler versions, you can still use 1.12.5 with the following:

```
bundle _1.12.5_ <command>
```

e.g. `bundle _1.12.5_ exec rake spec`

## Uninstallation

```vagrant plugin uninstall vagrant-windows-domain```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/vagrant-windows-domain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Squash commits & push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
