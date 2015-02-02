require 'spec_helper'
require 'vagrant-windows-domain/provisioner'
require 'vagrant-windows-domain/config'
require 'rspec/its'

describe VagrantPlugins::WindowsDomain::Provisioner do
  include_context "unit"

  let(:root_path)           { (Pathname.new(Dir.mktmpdir)).to_s }
  let(:ui)                  { double("ui") }
  let(:machine)             { double("machine", ui: ui) }
  let(:env)                 { double("environment", root_path: root_path, ui: ui) }
  let(:vm)                  { double ("vm") }
  let(:communicator)        { double ("communicator") }
  let(:shell)               { double ("shell") }
  let(:powershell)          { double ("powershell") }
  let(:guest)               { double ("guest") }
  let(:configuration_file)  { "manifests/MyWebsite.ps1" }
  let(:module_path)         { ["foo/modules", "foo/modules2"] }
  let(:root_config)         { VagrantPlugins::WindowsDomain::Config.new }
  subject                   { described_class.new machine, root_config }

  describe "configure" do
    before do
      allow(machine).to receive(:root_config).and_return(root_config)
      machine.stub(config: root_config, env: env)
      allow(ui).to receive(:say).with(any_args)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).with("$env:COMPUTERNAME").and_yield(:stdout, "myoldcomputername")
      allow(root_config).to receive(:vm).and_return(vm)
      allow(vm).to receive(:communicator).and_return(:winrm)
      root_config.finalize!
      root_config.validate(machine)
    end

    it "should confirm if the OS is Windows" do
      allow(communicator).to receive(:sudo).twice
      expect(subject.windows?).to eq(true)
      subject.configure(root_config)
    end

    it "should error if the detected OS is not Windows" do
      allow(vm).to receive(:communicator).and_return(:ssh)
      expect { subject.configure(root_config) }.to raise_error("Unsupported platform detected. Vagrant Windows Domain only works on Windows guest environments.")
    end

  end

  describe "provision" do

    before do
      allow(machine).to receive(:root_config).and_return(root_config)
      machine.stub(config: root_config, env: env)
      allow(ui).to receive(:say).with(any_args)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).with("$env:COMPUTERNAME").and_yield(:stdout, "myoldcomputername")
      allow(root_config).to receive(:vm).and_return(vm)
      allow(vm).to receive(:communicator).and_return(:winrm)
      allow(communicator).to receive(:sudo).with("which Add-Computer", {:error_class=>VagrantPlugins::WindowsDomain::WindowsDomainError, :error_key=>:binary_not_detected, :domain=>"foo.com", :binary=>"Add-Computer"})
      allow(communicator).to receive(:sudo).with("which Remove-Computer", {:error_class=>VagrantPlugins::WindowsDomain::WindowsDomainError, :error_key=>:binary_not_detected, :domain=>"foo.com", :binary=>"Remove-Computer"})

      root_config.domain = "foo.com"
      root_config.username = "username"
      root_config.password = "password"

      root_config.finalize!
      root_config.validate(machine)
      subject.configure(root_config)
    end

    it "should join the domain" do
      allow(communicator).to receive(:upload)
      allow(ui).to receive(:info)
      expect(communicator).to receive(:sudo).with(". 'c:/tmp/vagrant-windows-domain-runner.ps1'", {:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_return(0)
      expect(communicator).to receive(:sudo).with("del c:/tmp/vagrant-windows-domain-runner.ps1")
      expect(machine).to receive(:action). with(:reload, {:provision_ignore_sentinel=>false})
      expect(communicator).to receive(:ready?).and_return(true)
      subject.restart_sleep_duration = 0
      subject.provision
      expect(subject.old_computer_name).to eq("myoldcomputername")
    end

    it "should restart the machine on a successful domain join" do
      allow(communicator).to receive(:upload)
      allow(ui).to receive(:info)
      expect(communicator).to receive(:sudo).with(". 'c:/tmp/vagrant-windows-domain-runner.ps1'", {:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_return(0)
      expect(communicator).to receive(:sudo).with("del c:/tmp/vagrant-windows-domain-runner.ps1")
      expect(machine).to receive(:action). with(:reload, {:provision_ignore_sentinel=>false})
      expect(communicator).to receive(:ready?).and_return(true)
      subject.restart_sleep_duration = 0
      subject.provision
    end

    it "should not restart the machine on a failed domain join attempt" do
      allow(communicator).to receive(:upload)
      allow(ui).to receive(:info)
      expect(communicator).to receive(:sudo).with(". 'c:/tmp/vagrant-windows-domain-runner.ps1'", {:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_return(false)
      expect(communicator).to receive(:sudo).with("del c:/tmp/vagrant-windows-domain-runner.ps1")
      expect(machine).to_not receive(:action). with(:reload, {:provision_ignore_sentinel=>false})
      subject.restart_sleep_duration = 0
      subject.provision
    end

    context "generate_command_arguments" do

      it "join with credentials if provided" do
        args = subject.generate_command_arguments
      end

      it "not join with credentials if 'unsecure' option provided" do

      end

      it "remove with credentials if provided" do

      end

      it "remove join with credentials if 'unsecure' option provided" do

      end

      it "should rename the computer if the computer name is different" do

      end
      
    end

    it "should prompt for credentials if not provided" do
      root_config.username = nil
      root_config.password = nil
      expect(ui).to receive(:ask).with("Please enter your domain password (output will be hidden): ", {:echo=>false}).and_return("myusername")
      expect(ui).to receive(:ask).with("Please enter your domain username: ")
      subject.set_credentials
    end

    it "should not prompt for credentials if provided" do
      expect(ui).to_not receive(:ask)
      subject.set_credentials
    end

    it "should remove any traces of credentials once provisioning has occurred" do
      expect(communicator).to receive(:sudo).with("del c:/tmp/vagrant-windows-domain-runner.ps1")
      subject.remove_command_runner_script
    end

  end

  describe "cleanup" do
    before do
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).and_yield(:stdout, "myoldcomputername")
    end

    it "should leave domain" do
      allow(machine).to receive(:communicate).and_return(communicator)
      expect(communicator).to receive(:upload)
      expect(communicator).to receive(:sudo).with(". 'c:/tmp/vagrant-windows-domain-runner.ps1'", {:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_return(0)
      expect(ui).to receive(:info).with(any_args).once
      
      result = subject.leave_domain
      expect(result).to eq(true)
    end

    it "should leave domain when a `vagrant destroy` is issued" do
      allow(machine).to receive(:communicate).and_return(communicator)
      expect(communicator).to receive(:upload)
      expect(communicator).to receive(:sudo).with(". 'c:/tmp/vagrant-windows-domain-runner.ps1'", {:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell})
      expect(ui).to receive(:info).with(any_args).once
      
      subject.cleanup
    end

    it "should ask for credentials when leaving domain when no credentials were provided" do
      root_config.username = nil
      root_config.password = nil      
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:env).and_return(env)
      expect(communicator).to receive(:upload)
      expect(communicator).to receive(:sudo).with(". 'c:/tmp/vagrant-windows-domain-runner.ps1'", {:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_yield(:stdout, "deleted!")
      expect(ui).to receive(:info).with(any_args).twice
      expect(ui).to receive(:ask).with("Please enter your domain password (output will be hidden): ", {:echo=>false}).and_return("myusername")
      expect(ui).to receive(:ask).with("Please enter your domain username: ")      

      subject.cleanup
    end

  end

  describe "Powershell runner script" do
    before do
      allow(machine).to receive(:root_config).and_return(root_config)
      machine.stub(config: root_config, env: env)
      allow(ui).to receive(:say).with(any_args)
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).with("$env:COMPUTERNAME").and_yield(:stdout, "myoldcomputername")
      allow(root_config).to receive(:vm).and_return(vm)
      allow(vm).to receive(:communicator).and_return(:winrm)
      root_config.domain = "foo.com"
      root_config.username = "username"
      root_config.password = "password"
      root_config.finalize!
      root_config.validate(machine)
    end

    context "with credentials provided" do

      it "should generate a valid powershell command to add the computer to a domain" do
        script = subject.generate_command_runner_script
        expect_script = 
%Q{$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
Add-Computer -DomainName foo.com -Credential $credentials -Verbose -Force
}
        expect(script).to eq(expect_script)
      end

      it "should generate a valid powershell command to remove the computer from a domain" do
        script = subject.generate_command_runner_script(false)
        expect_script = 
%Q{$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
Remove-Computer -UnjoinDomainCredential $credentials -Workgroup "WORKGROUP" -Verbose -Force
}
        expect(script).to eq(expect_script)
      end

      context "with join options" do
        it "should rename the computer on join" do
          
          root_config.computer_name = "mynewcomputername"
          root_config.ou_path = "OU=testOU,DC=domain,DC=Domain,DC=com"
          root_config.finalize!
          root_config.validate(machine)

          script = subject.generate_command_runner_script
          expect_script = 
%Q{$secpasswd = ConvertTo-SecureString "password" -AsPlainText -Force
$credentials = New-Object System.Management.Automation.PSCredential ("username", $secpasswd)
Add-Computer -DomainName foo.com -Credential $credentials -NewName 'mynewcomputername' -OUPath 'OU=testOU,DC=domain,DC=Domain,DC=com' -Verbose -Force
}
          expect(script).to eq(expect_script)
        end
      end
    end

    context "with 'unsecure' parameter provided" do
      before do
        root_config.unsecure = true
      end

      it "should generate a valid powershell command to add the computer to a domain" do
        script = subject.generate_command_runner_script.strip
        expect_script = "Add-Computer -DomainName foo.com -Unsecure -Verbose -Force"
        expect(script).to eq(expect_script)
      end

      it "should generate a valid powershell command to remove the computer from a domain" do
        script = subject.generate_command_runner_script(false).strip
        expect_script = "Remove-Computer  -Workgroup \"WORKGROUP\" -Verbose -Force"
        expect(script).to eq(expect_script)
      end
    end

  end
end