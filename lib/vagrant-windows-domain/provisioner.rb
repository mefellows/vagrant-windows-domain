require "log4r"
require 'erb'

module VagrantPlugins
  module WindowsDomain
    # DSC Errors namespace, including setup of locale-based error messages.
    class WindowsDomainError < Vagrant::Errors::VagrantError
      error_namespace("vagrant_windows_domain.errors")
      I18n.load_path << File.expand_path("locales/en.yml", File.dirname(__FILE__))
    end
    class DSCUnsupportedOperation < WindowsDomainError
      error_key(:unsupported_operation)
    end    

    # Windows Domain Provisioner Plugin.
    #
    # Connects and Removes a guest Machine from a Windows Domain.
    class Provisioner < Vagrant.plugin("2", :provisioner)

      # Default path for storing the transient script runner
      WINDOWS_DOMAIN_GUEST_RUNNER_PATH = "c:/tmp/vagrant-windows-domain-runner.ps1"
      
      attr_accessor :restart_sleep_duration        

      # The current Computer Name.
      #
      # Used to determine whether or not we need to rename the computer 
      # on join. This parameter should not be manually set.
      attr_accessor :old_computer_name      

      # Constructs the Provisioner Plugin.
      #
      # @param [Machine] machine The guest machine that is to be provisioned.
      # @param [Config] config The Configuration object used by the Provisioner.
      # @returns Provisioner
      def initialize(machine, config)
        super

        @logger = Log4r::Logger.new("vagrant::provisioners::vagrant_windows_domain")
        @restart_sleep_duration = 10
      end

      # Configures the Provisioner.
      #
      # @param [Config] root_config The default configuration from the Vagrant hierarchy.
      def configure(root_config)
        raise WindowsDomainError, :unsupported_platform if !windows?
      end

      # Run the Provisioner!
      def provision
        verify_guest_capability

        @old_computer_name = get_guest_computer_name(machine)
        
        @machine.env.ui.say(:info, "Connecting guest machine to domain '#{config.domain}' with computer name '#{config.computer_name}'")

        set_credentials

        result = join_domain

        remove_command_runner_script

        if result
          restart_guest
        end
      end

      # Join the guest machine to a Windows Domain.
      #
      # Generates, writes and runs a script to join a domain.
      def join_domain        
        run_remote_command_runner(write_command_runner_script(generate_command_runner_script(true)))
      end

      # Removes the guest machine from a Windows Domain.
      #
      # Generates, writes and runs a script to leave a domain.
      def leave_domain
        run_remote_command_runner(write_command_runner_script(generate_command_runner_script(false)))
      end
      alias_method :unjoin_domain, :leave_domain

      # Ensure credentials are provided.
      #
      # Get username/password from user if not provided
      # as part of the config.
      def set_credentials
        if (config.username == nil)
          @logger.info("==> Requesting username as none provided")
          config.username = @machine.env.ui.ask("Please enter your domain username: ")
        end

        if (config.password == nil)
          @logger.info("==> Requesting password as none provided")
          config.password = @machine.env.ui.ask("Please enter your domain password (output will be hidden): ", {:echo => false})
        end
      end

      # Cleanup after a destroy action.
      #
      # This is the method called when destroying a machine that allows
      # for any state related to the machine created by the provisioner
      # to be cleaned up.
      def destroy
        if @config && @config.include?("domain")
          set_credentials
          leave_domain
        else
          @logger.debug("Not leaving domain on `destroy` action - no valid configuration detected")
          return
        end
      end

      # Restarts the Computer and waits
      def restart_guest
        @machine.env.ui.say(:info, "Restarting computer for updates to take effect.")
        options = {}
        options[:provision_ignore_sentinel] = false
        @machine.action(:reload, options)
        begin
          sleep @restart_sleep_duration
        end until @machine.communicate.ready?
      end

      # Verify that we can call the remote operations.
      # Required to add the computer to a Domain.
      def verify_guest_capability
        verify_binary("Add-Computer")
        verify_binary("Remove-Computer")
      end

      # Verify a binary\command is executable on the guest machine.
      def verify_binary(binary)
        @machine.communicate.sudo(
          "which #{binary}",
          error_class: WindowsDomainError,
          error_key: :binary_not_detected,
          domain: config.domain,
          binary: binary)
      end

      # Generates a PowerShell runner script from an ERB template
      #
      # @param [boolean] add_to_domain Whether or not to add or remove the computer to the domain (default: true).
      # @return [String] The interpolated PowerShell script.
      def generate_command_runner_script(add_to_domain=true)
        path = File.expand_path("../templates/runner.ps1", __FILE__)

        Vagrant::Util::TemplateRenderer.render(path, options: {
            config: @config,
            username: @config.username,
            password: @config.password,
            domain: @config.domain,
            add_to_domain: add_to_domain,
            unsecure: @config.unsecure,
            parameters: generate_command_arguments(add_to_domain)
        })
      end

      # Generates the argument list
      def generate_command_arguments(add_to_domain=true)

        if add_to_domain
          params = {"-DomainName" => @config.domain }

          if @config.unsecure
            params["-Unsecure"] = nil
          else
            params["-Credential $credentials"] = nil
          end

          if @config.computer_name != nil && @config.computer_name != @old_computer_name
            params["-NewName"] = "'#{@config.computer_name}'"
          end

          if @config.ou_path
            params["-OUPath"] = "'#{@config.ou_path}'"
          end
        else
          params = {}
          if !@config.unsecure
            params["-UnjoinDomainCredential $credentials"] = nil
          end
        end

        # Remove with unsecure
        join_params = @config.join_options.map { |a| "#{a}" }.join(',')
        params.map { |k,v| "#{k}" + (!v.nil? ? " #{v}": '') }.join(' ') + join_params
        
      end

      # Writes the PowerShell runner script to a location on the guest.
      #
      # @param [String] script The PowerShell runner script.
      # @return [String] the Path to the uploaded location on the guest machine.
      def write_command_runner_script(script)
        guest_script_path = WINDOWS_DOMAIN_GUEST_RUNNER_PATH
        file = Tempfile.new(["vagrant-windows-domain-runner", "ps1"])
        begin
          file.write(script)
          file.fsync
          file.close
          @machine.communicate.upload(file.path, guest_script_path)
        ensure
          file.close
          file.unlink
        end
        guest_script_path
      end

      # Remove temporary run script as it may contain
      # sensitive plain-text credentials.
      def remove_command_runner_script
        @machine.communicate.sudo("del #{WINDOWS_DOMAIN_GUEST_RUNNER_PATH}")
      end

      # Runs the PowerShell script on the guest machine.
      #
      # Streams the output of the command to the UI
      # @return [boolean] The result of the remote command
      def run_remote_command_runner(script_path)
        @machine.ui.info(I18n.t(
          "vagrant_windows_domain.running"))

        # A bit of an ugly dance, but this is how we get neat, colourised output and exit codes from a Powershell run
        last_type = nil
        new_line = ""
        error = false
        machine.communicate.shell.powershell("powershell -ExecutionPolicy Bypass -OutputFormat Text -file #{script_path}") do |type, data|
          if !data.chomp.empty?
            error = true if type == :stderr
            if [:stderr, :stdout].include?(type)
              color = type == :stdout ? :green : :red
              new_line = "\r\n" if last_type != nil and last_type != type
              last_type = type
              @machine.ui.info( new_line + data.chomp, color: color, new_line: false, prefix: false)
            end
          end
        end

        error == false
      end

      # Gets the Computer Name from the guest machine
      def get_guest_computer_name(machine)
        computerName = ""
        machine.communicate.shell.powershell("$env:COMPUTERNAME") do |type, data|
          if !data.chomp.empty?
            if [:stderr, :stdout].include?(type)
              computerName = data.chomp
              @logger.info("Detected guest computer name: #{computerName}")
            end
          end
        end

        computerName
      end 

      # Is the guest Windows?
      def windows?
        # If using WinRM, we can assume we are on Windows
        @machine.config.vm.communicator == :winrm
      end

    end
  end
end
