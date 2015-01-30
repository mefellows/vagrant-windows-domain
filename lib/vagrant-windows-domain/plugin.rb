require "vagrant"

module VagrantPlugins
  module WindowsDomain
    class Plugin < Vagrant.plugin("2")
      name "DSC"
      description <<-DESC
        Provides support for adding and removing guest Windows machines
        from a Domain.
      DESC

      config(:windows_domain, :provisioner) do
        require_relative 'config'
        Config
      end

      provisioner(:windows_domain) do
        require_relative 'provisioner'
        Provisioner
      end
    end
  end
end