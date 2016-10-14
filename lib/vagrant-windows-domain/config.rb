require "vagrant/util/counter"
require "log4r"

module VagrantPlugins
  module WindowsDomain    
    # The "Configuration" represents a configuration of how the WindowsDomain
    # provisioner should behave: authentication mechanism etc.
    class Config < Vagrant.plugin("2", :config)

      # The Windows Domain to join.
      #
      # Setting this will result in an additional restart.
      attr_accessor :domain

      # The new Computer Name to use when joining the domain.
      # Specifies a new name for the computer in the new domain. Uses the -NameName Option.
      attr_accessor :computer_name

      # The Username to use when authenticating against the Domain.
      #
      # Specifies a user account that has permission to join the computers to a new domain. 
      attr_accessor :username

      # The Password to use when authenticating against the Domain.
      #
      # Specifies the password of a user account that has permission to 
      # join the computers to a new domain. 
      attr_accessor :password

      # The set of Advanced options to pass when joining the Domain.
      #
      # See (https://technet.microsoft.com/en-us/library/hh849798.aspx) for detail.
      # NOTE: If we user :computer_name from above this needs to be merged!!
      attr_accessor :join_options

      # Organisational Unit path in AD.
      #
      # Specifies an organizational unit (OU) for the domain account. 
      # Enter the full distinguished name of the OU in quotation marks. 
      # The default value is the default OU for machine objects in the domain.
      attr_accessor :ou_path

      # Performs an unsecure join to the specified domain.
      #
      # When this option is used username/password are not required
      attr_accessor :unsecure

      # The trigger whether plugin should rename the computer or omit the renaming
      attr_accessor :rename

      def initialize
        super
        @domain            = UNSET_VALUE
        @computer_name     = UNSET_VALUE
        @username          = UNSET_VALUE
        @password          = UNSET_VALUE
        @join_options      = {}
        @ou_path           = UNSET_VALUE
        @unsecure          = UNSET_VALUE
        @rename            = UNSET_VALUE
        @logger            = Log4r::Logger.new("vagrant::vagrant_windows_domain")
      end

      # Final step of the Configuration lifecyle prior to
      # validation.
      #
      # Ensures all attributes are set to defaults if not provided.
      def finalize!
        super

        # Null checks
        @domain            = nil if @domain == UNSET_VALUE || @domain == ""
        @computer_name     = nil if @computer_name == UNSET_VALUE || @computer_name == ""
        @username          = nil if @username == UNSET_VALUE || @username == ""
        @password          = nil if @password == UNSET_VALUE || @password == ""
        @join_options      = [] if @join_options == UNSET_VALUE
        @ou_path           = nil if @ou_path == UNSET_VALUE
        @unsecure          = false if @unsecure == UNSET_VALUE
        @rename            = true if @rename == UNSET_VALUE
      end

      # Validate configuration and return a hash of errors.
      #
      # Validation happens after finalize!.
      #
      # @param [Machine] The current {Machine}
      # @return [Hash] Any errors or {} if no errors found
      def validate(machine)        
        errors = _detected_errors

        # Need to supply one of them!
        if ( (@username != nil && @password != nil) && @unsecure == true)
          errors << I18n.t("vagrant_windows_domain.errors.both_credentials_provided")
        end
        
        { "windows domain provisioner" => errors }
      end     
    end
  end
end
