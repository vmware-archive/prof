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
require 'prof/environment/pcf_drinks'
require 'ostruct'

RSpec.describe Prof::Environment::PcfDrinks do

  let(:tempest_config) do
    {
      'proxy' => {
        'host' =>  'proxy.host',
        'username' => 'USERNAME',
        'password' => 'PASSWORD'
      },
      'cloudfoundry' => {
        'domain' => 'CF_DOMAIN'
      }
    }
  end

  let(:ops_manager_instance) do
    instance_double(Prof::OpsManager)
  end

  let(:tempest_product) do
    instance_double(::OpsmanagerClient::Client::Internals::Product)
  end

  let(:tempest_job) do
    instance_double(::OpsmanagerClient::Client::Internals::Job)
  end

  let(:tempest_job_properties) do
    {'director_credentials' => tempest_bosh_credentials}
  end

  let(:tempest_bosh_credentials) do
      {
        'identity' => 'vcap',
        'salt' => '5a9943b66a53d0d3',
        'password' => '971001bc7517a2ec'
      }
  end

  let(:cloud_foundry_instance) do
    instance_double(Prof::CloudFoundry)
  end

  let(:ssh_gateway_instance) do
    instance_double(Prof::SshGateway)
  end

  subject(:pcf_drinks) do
    described_class.new(tempest_config)
  end

  before do
    allow(Prof::SshGateway).to receive(:new).and_return(ssh_gateway_instance)
    stub_const('ENV', {'TEMPEST_ENVIRONMENT' => 'environment_name', 'OM_VERSION' => '42'})
  end

  describe '#ssh_gateway' do
    context 'when the key is not specified in the config' do
      it 'provides a configured SshGateway object without key' do
        pcf_drinks.ssh_gateway
        expect(Prof::SshGateway).to have_received(:new).with(
          gateway_host: 'proxy.host',
          gateway_username: 'USERNAME',
          gateway_password: 'PASSWORD',
          ssh_key: nil
        )
      end
    end
    context 'when the key is specified in the config' do
      before(:each) do
        tempest_config['proxy']['ssh_key'] = 'some-key-value'
      end

      it 'provides a configured SshGateway object with key' do
        pcf_drinks.ssh_gateway
        expect(Prof::SshGateway).to have_received(:new).with(
          gateway_host: 'proxy.host',
          gateway_username: 'USERNAME',
          gateway_password: 'PASSWORD',
          ssh_key: 'some-key-value'
        )
      end
    end
   end

  describe '#ops_manager' do
    it 'builds new object using TEMPEST_ENVIRONMENT and OM_VERSION settings' do
      expect(Prof::OpsManager).to receive(:new).with(
        environment_name: 'environment_name', version: '42'
      )
      pcf_drinks.ops_manager
    end
  end

  describe '#cloud_foundry' do
    let(:cf_admin_credentials_instance) do
      OpenStruct.new(
        username: 'CF_USERNAME',
        password: 'CF_PASSWORD'
      )
    end

    before(:each) do
      allow(Prof::OpsManager).to receive(:new).and_return(ops_manager_instance)
      allow(ops_manager_instance).to receive(:cf_admin_credentials).and_return(cf_admin_credentials_instance)
    end

    it 'provides a configured CloudFoundry object' do
      expect(Prof::CloudFoundry).to receive(:new).with(
        domain:   'CF_DOMAIN',
        username: 'CF_USERNAME',
        password: 'CF_PASSWORD'
      )
      pcf_drinks.cloud_foundry
    end
  end

  describe "#bosh_director" do
    let(:hula_bosh_director_instance) { instance_double(Hula::BoshDirector) }
    let(:ssh_gateway_instance) { instance_double(Prof::SshGateway) }
    let(:bosh_credentials) do
      {
        'identity' => 'vcap',
        'password' => 'super-secure-password'
      }
    end

    let(:vms_for_job_type_response) do
      [
        OpenStruct.new(
          :hostname => 'vm_hostname',
          :username => 'vcap',
          :password => 'super-secret-password'
        )
      ]
    end

    before(:each) do
      allow(Hula::BoshDirector).to receive(:new).and_return(hula_bosh_director_instance)
      allow(Prof::OpsManager).to receive(:new).and_return(ops_manager_instance)
      allow(Prof::SshGateway).to receive(:new).and_return(ssh_gateway_instance)
      allow(ops_manager_instance).to receive(:bosh_credentials).and_return(bosh_credentials)
      allow(ops_manager_instance).to receive(:vms_for_job_type).and_return(vms_for_job_type_response)
      allow(ssh_gateway_instance).to receive(:with_port_forwarded_to).and_return(1234)
    end

    context 'when the target credentials are set' do
      it 'provides a Hula::BoshDirector instance' do
        pcf_drinks.bosh_director
        expect(Hula::BoshDirector).to have_received(:new).with(
          target_url: 'https://127.0.0.1:1234',
          username: 'vcap',
          password: 'super-secure-password'
        )
      end
    end
  end
end
