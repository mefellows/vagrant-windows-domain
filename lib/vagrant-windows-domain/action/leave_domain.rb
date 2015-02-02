require_relative '../provisioner'
require 'pp'

module VagrantPlugins
  module WindowsDomain
    class LeaveDomain
      include VagrantPlugins::WindowsDomain

      def initialize(app, env)
        @app = app
        @machine = env[:machine]
        @config = env[:machine].config.windows_domain
        @provisioner = VagrantPlugins::WindowsDomain::Provisioner.new(@machine, @config)
      end

      def call(env)
        @provisioner.destroy
        @app.call(env)
      end

    end
  end
end
