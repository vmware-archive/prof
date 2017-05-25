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
require 'prof/environment/cloud_foundry'

RSpec.describe Prof::Environment::CloudFoundry do
  describe 'ssh_gateway' do
    context 'without configuration' do
      it 'has a basic auth gateway with default values' do
        gateway = instance_double(Prof::SshGateway)
        expect(Prof::SshGateway).to receive(:new).with(
          gateway_host: '192.168.50.4',
          gateway_username: 'vagrant',
          gateway_password: 'vagrant'
        ).and_return(gateway)

        cf = described_class.new(
          bosh_service_broker_job_name: 'job_name',
          bosh_manifest_path: 'manifest_path'
        )

        expect(cf.ssh_gateway).to be(gateway)
      end
    end

    context 'with basic auth configuration' do
      it 'has a basic auth gateway' do
        gateway = instance_double(Prof::SshGateway)
        expect(Prof::SshGateway).to receive(:new).with(
          gateway_host: 'HOST',
          gateway_username: 'USERNAME',
          gateway_password: 'PASSWORD'
        ).and_return(gateway)

        cf = described_class.new(
          ssh_gateway_host: 'HOST',
          ssh_gateway_username: 'USERNAME',
          ssh_gateway_password: 'PASSWORD',
          bosh_service_broker_job_name: 'job_name',
          bosh_manifest_path: 'manifest_path'
        )

        expect(cf.ssh_gateway).to be(gateway)
      end
    end

    context 'with public key configuration' do
      it 'has a public-key cryptography gateway' do
        gateway = instance_double(Prof::SshGateway)
        expect(Prof::SshGateway).to receive(:new).with(
          gateway_host: 'HOST',
          gateway_username: 'USERNAME',
          gateway_private_key: 'PRIVATE_KEY'
        ).and_return(gateway)

        cf = described_class.new(
          ssh_gateway_host: 'HOST',
          ssh_gateway_username: 'USERNAME',
          ssh_gateway_private_key: 'PRIVATE_KEY',
          bosh_service_broker_job_name: 'job_name',
          bosh_manifest_path: 'manifest_path'
        )

        expect(cf.ssh_gateway).to be(gateway)
      end
    end
  end

  describe 'bosh_director' do
    context 'without configuration' do
      it 'has a basic auth bosh director with default values' do
        director = instance_double(Hula::BoshDirector)
        expect(Hula::BoshDirector).to receive(:new).
          with(
            target_url: 'https://192.168.50.4:25555',
            username: 'admin',
            password: 'admin',
            manifest_path: 'manifest_path',
            certificate_path: nil,
            env_login: false
          ).and_return(director)

        cf = described_class.new(
          bosh_service_broker_job_name: 'job_name',
          bosh_manifest_path: 'manifest_path'
        )

        expect(cf.bosh_director).to be(director)
      end
    end

    context 'with a bosh ca cert configured' do
      it 'has a basic auth bosh director with a ca cert' do
        director = instance_double(Hula::BoshDirector)
        expect(Hula::BoshDirector).to receive(:new).
          with(
            target_url: 'https://192.168.50.4:25555',
            username: 'admin',
            password: 'admin',
            manifest_path: 'manifest_path',
            certificate_path: 'certificate_path',
            env_login: false
          ).and_return(director)

        cf = described_class.new(
          bosh_service_broker_job_name: 'job_name',
          bosh_manifest_path: 'manifest_path',
          bosh_ca_cert_path: 'certificate_path'
        )

        expect(cf.bosh_director).to be(director)
      end
    end

    context 'with a bosh env login enabled' do
      it 'has a bosh director with env login' do
        director = instance_double(Hula::BoshDirector)
        expect(Hula::BoshDirector).to receive(:new).
          with(
            target_url: 'https://192.168.50.4:25555',
            username: 'admin',
            password: 'admin',
            manifest_path: 'manifest_path',
            certificate_path: nil,
            env_login: true
          ).and_return(director)

        cf = described_class.new(
          bosh_service_broker_job_name: 'job_name',
          bosh_manifest_path: 'manifest_path',
          bosh_env_login: true
        )

        expect(cf.bosh_director).to be(director)
      end
    end
  end
end
