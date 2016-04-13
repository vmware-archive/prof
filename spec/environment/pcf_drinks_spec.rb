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
end
