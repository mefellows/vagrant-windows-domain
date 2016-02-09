require_relative '../provisioner'

module VagrantPlugins
  module WindowsDomain
    # Include the built-in modules so we can use them as top-level things.
    include Vagrant::Action::Builtin

    # Leave a domain on a `vagrant destroy`.
    #
    # This is an Action middleware component that will detect the state of the machine -
    # and any corresponding configuration and act accordingly. This function accepts user input and
    # will halt the execution of proceeding middleware if the user chooses to cancel.
    #
    # Also note that it will interfere with a `vagrant destroy` user input to avoid duplicate "are you sure.."
    # messages.
    class LeaveDomain
      include VagrantPlugins::WindowsDomain

      attr_accessor :machine
      attr_accessor :config
      attr_accessor :env
      attr_accessor :app
      attr_accessor :provisioner

      def initialize(app, env)
        @logger = Log4r::Logger.new("vagrant::provisioners::vagrant_windows_domain")
        @logger.debug("Initialising WindowsDomain plugin on destroy action")
        @app = app
        @env = env
        @machine = env[:machine]

        @machine.config.vm.provisioners.each do |prov|
          @config = prov.config if prov.config.is_a?(VagrantPlugins::WindowsDomain::Config)
        end

        @provisioner = VagrantPlugins::WindowsDomain::Provisioner.new(@machine, @config)
      end

      # The middleware method that is invoked automatically by the Plugin ecosystem.
      # Expected to call the next middleware component in the chain if action should proceed.
      def call(env)

        if @config and @config.domain != nil

       	  if [:not_created].include? @machine.state.id
       	    @logger.debug("Machine not created, nothing to do")
       	  elsif [:running].include? @machine.state.id
            if !(env[:force_confirm_box_remove] || env[:force_confirm_destroy])
       	      answer = @machine.env.ui.ask("Are you sure you want to destroy this machine and disconnect from #{@config.domain}? (y/n)")
              return unless answer.downcase == 'y' # Bail out of destroy and prevent middleware from continuing on
            end 

            env[:force_confirm_destroy] = true # Prevent the popup dialog again
            @logger.debug("Valid configuration detected, triggering leave domain action")
            @provisioner.destroy
       	  else
       	    @machine.env.ui.say(:warn, "Machine is currently not running. To properly leave the #{@config.domain} network the machine needs to be running and connected to the network in which it was provisioned. Please run `vagrant up` and then `vagrant destroy`.\n")
            if !(env[:force_confirm_box_remove] || env[:force_confirm_destroy])
       	      answer = @machine.env.ui.ask("Would you like to continue destroying this machine, leaving this machine orphaned in the '#{@config.domain}' network? If so, type 'destroy'")
       	      return unless answer.downcase == 'destroy' # Bail out of destroy and prevent middleware from continuing on
            end 

       	    # OK, we're being naughty and letting the rest of the middleware do their things (i.e. destroy the machine, and such)

       	    env[:force_confirm_destroy] = true # Prevent the popup dialog again
       	    @logger.debug("Force destroying this machine and not leaving the domain #{@config.domain}")
       	    @machine.env.ui.say(:warn, "Force destroying this machine and not leaving the domain #{@config.domain}. May FSM have mercy on your soul.")
       	  end
       	else
       	  @logger.debug("No configuration detected, not leaving any domain")
       	end

        # Continue the rest of the middleware actions
        @app.call(env)
      end

    end
  end
end
