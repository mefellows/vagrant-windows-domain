require 'spec_helper'
require 'vagrant-windows-domain/provisioner'
require 'vagrant-windows-domain/config'
require 'rspec/its'

describe VagrantPlugins::WindowsDomain::Provisioner do
  include_context "unit"

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
  let(:root_config)         { VagrantPlugins::WindowsDomain::Config.new }
  subject                   { described_class.new machine, root_config }

  describe "configure" do
    before do
      allow(machine).to receive(:root_config).and_return(root_config)
      machine.stub(config: root_config, env: env)

      allow(machine).to receive(:communicate).and_return(communicator)
      allow(communicator).to receive(:shell).and_return(shell)
      allow(shell).to receive(:powershell).with("$env:COMPUTERNAME").and_yield(:stdout, "myoldcomputername")      
      root_config.finalize!
      root_config.validate(machine)
    end

    it "should confirm if the OS is Windows" do
      allow(root_config).to receive(:vm).and_return(vm)
      allow(vm).to receive(:communicator).and_return(:winrm)
      allow(communicator).to receive(:sudo).twice
      expect(subject.windows?).to eq(true)

      subject.configure(root_config)
    end

    it "should fail if the detected OS is not Windows" do
      allow(root_config).to receive(:vm).and_return(vm)
      allow(vm).to receive(:communicator).and_return(:ssh)

      expect { subject.configure(root_config) }.to raise_error("Unsupported platform detected. Vagrant Windows Domain only works on Windows guest environments.")
      
    end

  end


#   describe "provision" do

#     before do
#       # allow(root_config).to receive(:vm).and_return(vm)
#       allow(machine).to receive(:root_config).and_return(root_config)
#       allow(machine).to receive(:env).and_return(env)
#       root_config.finalize!
#       root_config.validate(machine)
#       subject.configure(root_config)
#       machine.stub(config: root_config, env: env, communicate: communicator, guest: guest)
#     end

#     it "should restart the machine on a successful domain join" do

#     end

#     it "should not attempt to join the domain if already on it" do

#     end

#     it "should authenticate with credentials if provided" do

#     end

#     it "should prompt for credentials if not provided" do
    
#     end

#     it "should verify DSC binary exists" do
#       expect(communicator).to receive(:sudo).with("which Start-DscConfiguration", {:error_class=>VagrantPlugins::DSC::WindowsDomainError, :error_key=>:dsc_not_detected, :binary=>"Start-DscConfiguration"})
#       subject.verify_binary("Start-DscConfiguration")
#     end

#     it "should verify DSC and Powershell versions are valid" do
#       expect(communicator).to receive(:test).with("(($PSVersionTable | ConvertTo-json | ConvertFrom-Json).PSVersion.Major) -ge 4", {:error_class=>VagrantPlugins::DSC::WindowsDomainError, :error_key=>:dsc_incorrect_PowerShell_version}).and_return(true)
#       allow(subject).to receive(:verify_binary).and_return(true)
#       subject.verify_dsc
#     end

#     it "should raise an error if DSC version is invalid" do
#       # shell = double("WinRMShell")
#       # allow(communicator).to receive(:shell).and_return(shell)
#       # allow(communicator).to receive(:create_shell).and_return(shell)

#       # TODO: Create an actual Communicator object and mock out methods/calls to isolate this behaviour better
#       expect(communicator).to receive(:test).with("(($PSVersionTable | ConvertTo-json | ConvertFrom-Json).PSVersion.Major) -ge 4", {:error_class=>VagrantPlugins::DSC::WindowsDomainError, :error_key=>:dsc_incorrect_PowerShell_version})
#       allow(subject).to receive(:verify_binary).and_return(true)
#       # expect { subject.verify_dsc }.to raise_error("Unable to detect a working DSC environment. Please ensure powershell v4+ is installed, including WMF 4+.")
#       subject.verify_dsc
#     end

#     it "should raise an error if Powershell version is invalid" do

#     end


#   end

#   describe "Powershell runner script" do
#     before do
#       # Prevent counters messing with output in tests
#       Vagrant::Util::Counter.class_eval do
#         def get_and_update_counter(name=nil) 1 end
#       end

#       allow(machine).to receive(:root_config).and_return(root_config)
#       root_config.configuration_file = configuration_file
#       machine.stub(config: root_config, env: env)
#       root_config.module_path = module_path
#       root_config.configuration_file = configuration_file
#       root_config.finalize!
#       root_config.validate(machine)
#       subject.configure(root_config)

#     end

#     context "with default parameters" do
#       it "should generate a valid powershell command" do
#         script = subject.generate_dsc_runner_script
#         expect_script = "#
# # DSC Runner.
# #
# # Bootstraps the DSC environment, sets up configuration data
# # and runs the DSC Configuration.
# #
# #

# # Set the local PowerShell Module environment path
# $absoluteModulePaths = [string]::Join(\";\", (\"/tmp/vagrant-windows-domain-1/modules-0;/tmp/vagrant-windows-domain-1/modules-1\".Split(\";\") | ForEach-Object { $_ | Resolve-Path }))

# echo \"Adding to path: $absoluteModulePaths\"
# $env:PSModulePath=\"$absoluteModulePaths;${env:PSModulePath}\"
# (\"/tmp/vagrant-windows-domain-1/modules-0;/tmp/vagrant-windows-domain-1/modules-1\".Split(\";\") | ForEach-Object { gci -Recurse  $_ | ForEach-Object { Unblock-File  $_.FullName} })

# $script = $(Join-Path \"/tmp/vagrant-windows-domain-1\" \"manifests/MyWebsite.ps1\" -Resolve)
# echo \"PSModulePath Configured: ${env:PSModulePath}\"
# echo \"Running Configuration file: ${script}\"

# # Generate the MOF file, only if a MOF path not already provided.
# # Import the Manifest
# . $script

# cd \"/tmp/vagrant-windows-domain-1\"
# $StagingPath = $(Join-Path \"/tmp/vagrant-windows-domain-1\" \"staging\")
# $response = MyWebsite -OutputPath $StagingPath  4>&1 5>&1 | Out-String

# # Start a DSC Configuration run
# $response += Start-DscConfiguration -Force -Wait -Verbose -Path $StagingPath 4>&1 5>&1 | Out-String
# $response"

#         expect(script).to eq(expect_script)
#       end
#     end

#   end

#   describe "write DSC Runner script" do
#     it "should upload the customised DSC runner to the guest" do
#       script = "myscript"
#       path = "/local/runner/path"
#       guest_path = "c:/tmp/vagrant-windows-domain-runner.ps1"
#       machine.stub(config: root_config, env: env, communicate: communicator)
#       file = double("file")
#       allow(file).to receive(:path).and_return(path)
#       allow(Tempfile).to receive(:new) { file }
#       expect(file).to receive(:write).with(script)
#       expect(file).to receive(:fsync)
#       expect(file).to receive(:close).exactly(2).times
#       expect(file).to receive(:unlink)
#       expect(communicator).to receive(:upload).with(path, guest_path)
#       res = subject.write_dsc_runner_script(script)
#       expect(res.to_s).to eq(guest_path)
#     end
#   end

#   describe "Apply DSC" do
#     it "should invoke the DSC Runner and notify the User of provisioning status" do
#       expect(ui).to receive(:info).with(any_args).once
#       expect(ui).to receive(:info).with("provisioned!", {color: :green, new_line: false, prefix: false}).once
#       allow(machine).to receive(:communicate).and_return(communicator)
#       expect(communicator).to receive(:sudo).with('. ' + "'c:/tmp/vagrant-windows-domain-runner.ps1'",{:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_yield(:stdout, "provisioned!")

#       subject.run_dsc_apply
#     end

#     it "should show error output in red" do
#       expect(ui).to receive(:info).with(any_args).once
#       expect(ui).to receive(:info).with("provisioned!", {color: :red, new_line: false, prefix: false}).once
#       allow(machine).to receive(:communicate).and_return(communicator)
#       expect(communicator).to receive(:sudo).with('. ' + "'c:/tmp/vagrant-windows-domain-runner.ps1'",{:elevated=>true, :error_key=>:ssh_bad_exit_status_muted, :good_exit=>0, :shell=>:powershell}).and_yield(:stderr, "provisioned!")

#       subject.run_dsc_apply
    # end
  # end
end