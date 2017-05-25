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
require 'net/ssh/gateway'
require 'prof/ssh_gateway'

RSpec.describe Prof::SshGateway do
  let(:ssh_key) do
    nil
  end

  subject(:ssh_gateway) do
    described_class.new(
      gateway_host: 'GATEWAY_HOST',
      gateway_username: 'GATEWAY_USERNAME',
      gateway_password: 'GATEWAY_PASSWORD',
      ssh_key: ssh_key
    )
  end

  describe '#execute_on' do
    let(:net_ssh_gateway_instance) do
      instance_double(Net::SSH::Gateway)
    end

    before do
      allow(Net::SSH::Gateway).to receive(:new).and_return(net_ssh_gateway_instance)
    end

    context 'when the gateway uses basic auth' do
      it 'authenticates with the gateway using username and password' do
        allow(net_ssh_gateway_instance).to receive(:ssh)

        ssh_gateway.execute_on('HOST', 'CMD')

        expect(Net::SSH::Gateway).to have_received(:new).
          with('GATEWAY_HOST', 'GATEWAY_USERNAME', password: 'GATEWAY_PASSWORD', paranoid: false)
      end
    end

    context 'when the gateway uses public-key cryptography' do
      it 'authenticates with the gateway using a username and a private key' do
        ssh_gateway = described_class.new(
          gateway_host: 'GATEWAY_HOST',
          gateway_username: 'GATEWAY_USERNAME',
          gateway_private_key: 'GATEWAY_PRIVATE_KEY',
          ssh_key: ssh_key
        )
        allow(net_ssh_gateway_instance).to receive(:ssh)

        ssh_gateway.execute_on('HOST', 'CMD')

        expect(Net::SSH::Gateway).to have_received(:new).
          with('GATEWAY_HOST', 'GATEWAY_USERNAME', keys: ['GATEWAY_PRIVATE_KEY'], paranoid: false)
      end
    end

    context 'when warning occurs' do
      it 'suppresses the warning' do
        expect(net_ssh_gateway_instance).to receive(:ssh) do
          warn 'Deprecated warning'
        end

        captured_stderr_output = capture_stderr do
          ssh_gateway.execute_on('HOST', 'CMD')
        end

        expect(captured_stderr_output).not_to include('Deprecated warning')
      end
    end

    context 'when there is no ssh key' do
      it 'does not set key_data' do
        expect(net_ssh_gateway_instance).to receive(:ssh).with(
          'HOST',
          'vcap',
          { password: 'c1oudc0w', paranoid: false, auth_methods: ['password', 'publickey'] }
        )
        ssh_gateway.execute_on('HOST', 'CMD')
      end
    end

    context 'when there is an ssh key' do
      let(:ssh_key) do
        'SOME_KEY'
      end

      it 'sets key_data' do
        expect(net_ssh_gateway_instance).to receive(:ssh).with(
          'HOST',
          'vcap',
          { password: 'c1oudc0w', paranoid: false, key_data: [ ssh_key ] }
        )
        ssh_gateway.execute_on('HOST', 'CMD')
      end
    end

  end

end
