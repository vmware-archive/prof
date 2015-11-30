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

describe Prof::Environment::PcfDrinks do

  let!(:tempest_config) do
    {
      tempest: {
        some: 'config',
        url: 'http://foobar.com:9999',
        username: 'tempest user',
        password: 'tempest password'
      },
      tempest_vm: {
        username: 'tempest vm user',
        password: 'tempest vm password'
      },
      proxy: {
        host: 'proxy.host',
        username: 'USERNAME',
        password: 'PASSWORD'
      },
      cloudfoundry: {
        domain: 'CF_DOMAIN'
      }
    }
  end

  let(:cf_admin_credentials_instance) do
    double(
      'cf_admin_credentials',
      username: 'CF_USERNAME',
      password: 'CF_PASSWORD'
    )
  end

  let(:ops_manager_instance) do
    instance_double(Prof::OpsManager)
  end

  let(:opsmanager_client) do
    instance_double(::OpsmanagerClient::Client)
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

  let(:log_fetcher_instance) do
    instance_double(Prof::OpsManagerLogFetcher)
  end

  let(:ssh_gateway_instance) do
    instance_double(Prof::SshGateway)
  end

  subject(:pcf_drinks) do
    described_class.new(tempest_config)
  end

  before do
    allow(Prof::SshGateway).to receive(:new).and_return(ssh_gateway_instance)
    allow(Prof::OpsManagerLogFetcher).to receive(:new).and_return(log_fetcher_instance)
    allow(Prof::OpsManager).to receive(:new).and_return(ops_manager_instance)
    allow(Prof::CloudFoundry).to receive(:new).and_return(cloud_foundry_instance)
    allow(ops_manager_instance).to receive(:cf_admin_credentials).and_return(cf_admin_credentials_instance)
    allow(ops_manager_instance).to receive(:opsmanager_client).and_return(opsmanager_client)
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
        tempest_config[:proxy].merge!(ssh_key: 'some-key-value')
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
    it 'provides a configured OpsManager object' do
      actual_ops_manager = pcf_drinks.ops_manager
      expected_config = tempest_config.fetch(:tempest).merge(page: an_instance_of(Capybara::Session))

      expect(Prof::OpsManager).to have_received(:new).with(expected_config)
      expect(actual_ops_manager).to equal(ops_manager_instance)
    end
  end

  describe '#cloud_foundry' do
    it 'provides a configured CloudFoundry object' do
      actual_cloud_foundry = pcf_drinks.cloud_foundry

      expect(Prof::CloudFoundry).to have_received(:new).with(
        domain:   'CF_DOMAIN',
        username: 'CF_USERNAME',
        password: 'CF_PASSWORD'
      )
      expect(actual_cloud_foundry).to equal(cloud_foundry_instance)
    end
  end

  describe '#bosh_product' do
    context 'when OpsMan uses microbosh for the bosh product guid' do
      before(:each) do
        allow(opsmanager_client).to receive(:product).with('microbosh').and_return(tempest_product)
      end

      it 'returns the correct product' do
        product = pcf_drinks.send(:bosh_product)
        expect(product).to equal(tempest_product)
      end
    end

    context 'when OpsMan uses p-bosh for the bosh product guid' do
      before(:each) do
        allow(opsmanager_client).to receive(:product).with('microbosh').and_return(nil)
        allow(opsmanager_client).to receive(:product).with('p-bosh').and_return(tempest_product)
      end

      it 'returns the correct product' do
        product = pcf_drinks.send(:bosh_product)
        expect(product).to equal(tempest_product)
      end
    end
  end

  describe '#bosh_credentials' do
    before(:each) do
      allow(pcf_drinks).to receive(:bosh_product).and_return(tempest_product)
      allow(tempest_product).to receive(:job_of_type).with('director').and_return(tempest_job)
      allow(tempest_job).to receive(:properties).and_return(tempest_job_properties)
    end

    it 'returns the credentials for bosh' do
      credentials = pcf_drinks.send(:bosh_credentials)
      expect(credentials).to equal(tempest_bosh_credentials)
    end
  end

end
