require "vagrant"
require "vagrant-windows-domain/action/leave_domain"

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
      
      config(:windows_domain) do
        require_relative 'config'
        Config
      end

      provisioner(:windows_domain) do
        require_relative 'provisioner'
        Provisioner
      end

      action_hook(:windows_domain, :machine_action_destroy) do |hook|
        require_relative 'action/leave_domain'
        hook.prepend(VagrantPlugins::WindowsDomain::LeaveDomain)
      end      
    end
  end
end