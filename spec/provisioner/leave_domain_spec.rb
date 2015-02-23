require 'spec_helper'
require 'vagrant-windows-domain/provisioner'
require 'vagrant-windows-domain/action/leave_domain'
require 'vagrant-windows-domain/config'
require 'base'

describe VagrantPlugins::WindowsDomain::LeaveDomain do

  include_context "unit"
  let(:instance) { described_class.new }

  let(:root_path)           { (Pathname.new(Dir.mktmpdir)).to_s }
  let(:domain)              { "foo.com" }
  let(:ui)                  { double("ui") }
  let(:app)                 { double("app") }
  let(:communicator)        { double ("communicator") }
  let(:shell)               { double ("shell") }
  let(:powershell)          { double ("powershell") }
  let(:guest)               { double ("guest") }
  let(:configuration_file)  { "manifests/MyWebsite.ps1" }
  let(:module_path)         { ["foo/modules", "foo/modules2"] }
  let(:config)              { VagrantPlugins::WindowsDomain::Config.new }
  let(:vm)                  { double("vm", provisioners: [double("prov", config: config)]) }
  let(:root_config)          { double("root_config", vm: vm) } 
  let(:env)                 { {:ui => ui, :machine => machine} }
  let(:machine)             { double("machine", ui: ui, id: "1234", config: root_config) }
  let(:provisioner)         { double("provisioner") }
  subject                   { described_class.new app, env }

  describe "call" do

    before do
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(env).to receive(:machine).and_return(machine)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).and_yield(:stdout, "myoldcomputername")
      config.domain = domain
      allow(env).to receive(:machine).and_return(machine)
      allow(machine).to receive(:env).and_return(env)
      allow(env).to receive(:ui).and_return(ui)
      subject.provisioner = provisioner
    end

    context "when no configuration exists for the machine" do
      it "should pass control to the next middleware Action" do
        config.domain = nil
        expect(app).to receive(:call).with(env)
        subject.call(env)
      end
    end

    context "when machine is running" do
      it "should prompt the user if they would like to destroy & d/c the machine" do
        state = double("state", id: :running)
        expect(provisioner).to receive(:destroy)

        expect(app).to receive(:call).with(env)
            expect(ui).to receive(:ask).with("Are you sure you want to destroy this machine and disconnect from #{domain}? (y/n)").and_return("y")
        expect(machine).to receive(:state).and_return(state).twice
        subject.call(env)

      end

      it "should not continue if the user declines to destroy the machine" do
        state = double("state", id: :running)
        expect(provisioner).to_not receive(:destroy)

        expect(ui).to receive(:ask).with("Are you sure you want to destroy this machine and disconnect from #{domain}? (y/n)").and_return("n")
        expect(machine).to receive(:state).and_return(state).twice
        expect(app).to_not receive(:call).with(env)
        subject.call(env)
      end
    end

    context "when machine is :paused, :saved or :poweroff" do
      it "should prompt the user if they would like to force destroy the machine" do
        state = double("state", id: :poweroff)
        provisioner = double("provisioner")
        subject.provisioner = provisioner

        expect(ui).to receive(:say).with(:warn, "Machine is currently not running. To properly leave the #{domain} network the machine needs to be running and connected to the network in which it was provisioned. Please run `vagrant up` and then `vagrant destroy`.\n")
        expect(ui).to receive(:ask).with("Would you like to continue destroying this machine, leaving this machine orphaned in the '#{domain}' network? If so, type 'destroy'").and_return("destroy")
        expect(ui).to receive(:say).with(:warn, "Force destroying this machine and not leaving the domain foo.com. May FSM have mercy on your soul.")
        expect(machine).to receive(:state).and_return(state).twice
        expect(app).to receive(:call).with(env)
        # Can't call destroy on a non-running machine
        expect(provisioner).to_not receive(:destroy)

        subject.call(env)

        expect(env[:force_confirm_destroy]).to be(true)
      end

      it "should not pass on to middleware if user declines force destroy" do
        state = double("state", id: :poweroff)
        provisioner = double("provisioner")
        subject.provisioner = provisioner

        expect(ui).to receive(:say).with(:warn, "Machine is currently not running. To properly leave the #{domain} network the machine needs to be running and connected to the network in which it was provisioned. Please run `vagrant up` and then `vagrant destroy`.\n")
        expect(ui).to receive(:ask).with("Would you like to continue destroying this machine, leaving this machine orphaned in the '#{domain}' network? If so, type 'destroy'").and_return("n")
        expect(machine).to receive(:state).and_return(state).twice
        expect(app).to_not receive(:call).with(env)
        expect(provisioner).to_not receive(:destroy)
        expect(env[:force_confirm_destroy]).to be(nil)

        subject.call(env)
      end
    end

    context "when machine is :not_created" do
      it "should pass control to the next middleware action" do
        state = double("state", id: :not_created)
        expect(machine).to receive(:state).and_return(state)

        expect(app).to receive(:call).with(env)
        subject.call(env)
      end
    end
  end


  describe "initialize" do

    its("env")              { should eq(env) }
    its("app")              { should eq(app) }
    its("config")           { should eq(config) }
    its("machine")          { should eq(machine) }

  end

end
