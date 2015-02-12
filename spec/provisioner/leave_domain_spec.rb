require 'spec_helper'
require 'vagrant-windows-domain/provisioner'
require 'vagrant-windows-domain/action/leave_domain'
require 'vagrant-windows-domain/config'
require 'base'

describe VagrantPlugins::WindowsDomain::LeaveDomain do

  include_context "unit"
  let(:instance) { described_class.new }

  let(:root_path)           { (Pathname.new(Dir.mktmpdir)).to_s }
  let(:ui)                  { Vagrant::UI::Silent.new }
  let(:app)                 { double("app") }
  let(:communicator)        { double ("communicator") }
  let(:shell)               { double ("shell") }
  let(:powershell)          { double ("powershell") }
  let(:guest)               { double ("guest") }
  let(:configuration_file)  { "manifests/MyWebsite.ps1" }
  let(:module_path)         { ["foo/modules", "foo/modules2"] }
  let(:config)         		{ VagrantPlugins::WindowsDomain::Config.new }
  let(:vm)                  { double("vm", provisioners: [double("prov", config: config)]) }
  let(:root_config)        	{ double("root_config", vm: vm) } 
  let(:env)                 { {:ui => ui, :machine => machine} }
  let(:machine)             { double("machine", ui: ui, id: "1234", config: root_config) }
  subject                   { described_class.new app, env }

  describe "call" do

    before do
      env = double("environment", root_path: "/tmp/vagrant-windows-domain-path", machine: machine)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(env).to receive(:machine).and_return(machine)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).and_yield(:stdout, "myoldcomputername")
    end

    context "when no configuration exists for the machine" do
		it "should pass control to the next middleware Action" do

		end
    end

  	context "when machine is running" do
		it "should prompt the user if they would like to destroy & d/c the machine" do
		end
  	end

  	context "when machine is :paused, :saved or :poweroff" do
		it "should prompt the user if they would like to force destroy the machine" do

		end

		it "should not pass on to middleware if user declines force destroy" do

		end
  	end

  	context "when machine is :not_created" do
  		it "should do nothing" do

  		end
  	end
  end


  describe "initialize" do

    its("env")            	{ should eq(env) }
    its("app")     			{ should eq(app) }
    its("config")          	{ should eq(config) }
    its("machine")          { should eq(machine) }

  end

end
