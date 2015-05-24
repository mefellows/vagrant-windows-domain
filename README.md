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
    # Uses the Rename-Computer PowerShell command. ORRRR -NewName flag??
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

## Uninstallation

```vagrant plugin uninstall vagrant-windows-domain```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/vagrant-windows-domain/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Squash commits & push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
