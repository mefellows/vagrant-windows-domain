require 'spec_helper'
require 'vagrant-windows-domain/provisioner'
require 'vagrant-windows-domain/config'
require 'base'

describe VagrantPlugins::WindowsDomain::Config do
  include_context "unit"
  let(:instance) { described_class.new }
  let(:machine) { double("machine") }

 let(:root_path)           { (Pathname.new(Dir.mktmpdir)).to_s }
  let(:ui)                  { Vagrant::UI::Silent.new }
  let(:machine)             { double("machine", ui: ui) }
  let(:env)                 { double("environment", root_path: root_path, ui: ui) }
  let(:vm)                  { double ("vm") }
  let(:communicator)        { double ("communicator") }
  let(:shell)               { double ("shell") }
  let(:powershell)          { double ("powershell") }
  let(:guest)               { double ("guest") }
  let(:configuration_file)  { "manifests/MyWebsite.ps1" }
  let(:module_path)         { ["foo/modules", "foo/modules2"] }
  let(:root_config)         { VagrantPlugins::DSC::Config.new }
  # subject                   { described_class.new machine, root_config }

  describe "defaults (finalize!)" do

    before do
      env = double("environment", root_path: "/tmp/vagrant-windows-domain-path")
      config = double("config")
      machine.stub(config: config, env: env)
    end

    before { subject.finalize! }

    its("domain")            { should be_nil }
    its("computer_name")     { should eq(nil) }
    its("username")          { should be_nil }
    its("password")          { should be_nil }
    its("join_options")      { should eq({})   }
    its("ou_path")           { should be_nil }
    its("unsecure")          { should eq(false) }

    it "should ignore empty strings" do
      subject.domain = ""
      subject.username = ""
      subject.password = ""
      subject.computer_name = ""
      
      subject.finalize!

      expect(subject.domain).to be_nil
      expect(subject.computer_name).to be_nil
      expect(subject.username).to be_nil
      expect(subject.password).to be_nil
    end
  end

  describe "validate settings" do
    before do
      env = double("environment", root_path: "/tmp/vagrant-windows-domain-path")
      config = double("config")
      machine.stub(config: config, env: env)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).and_yield(:stdout, "myoldcomputername")
    end

    before { subject.finalize! }

    it "should be invalid if either 'username' and 'password' or 'unsecure' are both provided" do
      subject.username = "myusername"
      subject.password = "mypassword"
      subject.unsecure = true
      subject.validate(machine)

      assert_invalid
      assert_error("You must not supply a \"username\" and \"password\" if \"unsecure\" is set to true.")
    end

    it "should detect the current computers' name" do
      subject.validate(machine)
      expect(subject.old_computer_name).to eq("myoldcomputername")
    end

  end

end