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
require 'securerandom'
require 'prof/cloud_foundry'

RSpec.describe Prof::CloudFoundry do
  subject(:cloud_foundry) {described_class.new(options)}
  let(:options) do
    {
      domain:   "somedomain.com",
      username: "some-user",
      password: "some-password"
    }
  end

  describe 'api_url' do
    it 'defaults to https' do
      expect(cloud_foundry.api_url).to start_with("https://")
    end
  end

  describe 'service actions' do
    let(:retry_timeout) { 1 }
    let(:retry_interval) { 0.1 }
    let!(:options) do
      {
        domain:   "somedomain.com",
        username: "some-user",
        password: "some-password",
        hula_cloud_foundry: hula_cloud_foundry,
        retry_timeout: retry_timeout,
        retry_interval: retry_interval,
      }
    end

    let(:hula_cloud_foundry) do
      hula_cloud_foundry = double
      allow(hula_cloud_foundry).to receive(:get_service_status).and_return(
       'in progress',
       expected_state
      )

      allow(hula_cloud_foundry).to receive(:delete_service_instance_and_unbind)
        .and_return('delete in progress')
      allow(hula_cloud_foundry).to receive(:create_service_instance)
        .and_return('create in progress')
      hula_cloud_foundry
    end

    context 'create service' do
      let(:expected_state) { 'create succeeded' }

      before do
        Struct.new('Service', :name, :plan)
      end

      it 'waits for service creation to have succeded' do
        service = Struct::Service.new('the_service_name', 'the_plan_name')

        expect(hula_cloud_foundry).to receive(:get_service_status).twice
        expect{cloud_foundry.provision_service(service)}.not_to raise_error
      end
    end

    context 'delete service' do
      let(:service_instance_name) { SecureRandom.uuid }
      let(:service_instance) { Struct::ServiceInstance.new(service_instance_name) }
      let(:expected_state) { "Service instance #{service_instance_name} not found" }

      before do
        Struct.new('ServiceInstance', :name)
      end

      it 'waits for service deletion to have succeded' do
        expect(hula_cloud_foundry).to receive(:get_service_status).twice
        expect{cloud_foundry.delete_service_instance_and_unbind(service_instance)}.not_to raise_error
      end

      context 'when a timeout error is thrown' do
        let(:retry_timeout) { 0.1 }
        let(:retry_interval) { 1 }

        it 'times out if wrong service instance name is checked' do
          expect(hula_cloud_foundry).to receive(:get_service_status).exactly(:once)
          expect{cloud_foundry.delete_service_instance_and_unbind(service_instance)}.to raise_error(Timeout::Error)
        end
      end

      context 'when get_service_status returns failure' do
        let(:expected_state) { "delete failed" }

        it 'throws when status matches the error condition' do
          err_message = "Error #{expected_state} occured for service instance: #{service_instance.name}"

          expect(hula_cloud_foundry).to receive(:get_service_status).exactly(2).times
          expect{cloud_foundry.delete_service_instance_and_unbind(service_instance)}.to raise_error(err_message)
        end
      end
    end
  end
end
