# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'spec_helper'
require 'prof/ops_manager'

RSpec.describe Prof::OpsManager do

  let(:opsmanager) { described_class.new(environment_name: "test", version: "1.7") }
  let(:test_env) do
    instance_double(
      Opsmgr::Environments,
      settings: {
        'name' => 'fake-environment',
        'ops_manager' => {
          'username' => 'test_web_user',
          'password' => 'test_web_password',
          'url' => 'http://127.0.0.1:8741',
        },
      }
    )
  end

  before(:each) do
    allow(Opsmgr::Environments).to receive(:for).and_return(test_env)
    fake_response = JSON.parse(File.read(File.expand_path(File.join(__dir__, 'assets', 'installation_settings.json'))))
    installation_settings_object = Opsmgr::Api::InstallationSettingsResult.new(fake_response)
    allow_any_instance_of(Opsmgr::Api::Client).to receive(:installation_settings).and_return(installation_settings_object)
  end

  it "#cf_admin_credentials" do
    credentials = opsmanager.cf_admin_credentials
    expect(credentials.username).to eq("admin")
    expect(credentials.password).to eq("uaa-password")
  end

  it "#system_domain" do
    expect(opsmanager.system_domain).to eq("cf-system-domain")
  end

  it "#vms_for_job_type" do
    vms = opsmanager.vms_for_job_type('rabbitmq-server')
    expect(vms.first.hostname).to eq("10.85.48.137")
    expect(vms.first.username).to eq("vcap")
    expect(vms.first.password).to eq("super-secret-vm-password")
  end

  it '#bosh_credentials' do
    credentials = opsmanager.bosh_credentials
    expect(credentials['identity']).to eq 'director'
    expect(credentials['password']).to eq 'director_password'
  end
end
