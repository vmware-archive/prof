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
        retry_interval: retry_interval
      }
    end

    let(:service_instance_name) { SecureRandom.uuid }
    let(:service_instance) { Struct::ServiceInstance.new(service_instance_name) }

    let(:hula_cloud_foundry) do
      hula_cloud_foundry = double
      allow(hula_cloud_foundry).to receive(:get_service_status).and_return(
        # Required for testing asynchonicity
        'in progress',
        state_under_test,
        # Required for ensure block to delete successfully
        "Service instance #{service_instance_name} not found",
      )

      allow(hula_cloud_foundry).to receive(:delete_service_instance_and_unbind)
        .and_return('delete in progress')
      allow(hula_cloud_foundry).to receive(:create_service_instance)
        .and_return('create in progress')
      hula_cloud_foundry
    end

    before(:all) do
      Struct.new('Service', :name, :plan)
      Struct.new('ServiceInstance', :name)
      Struct.new('App', :name)
    end

    context 'create service' do
      let(:state_under_test) { 'create succeeded' }
      let(:service) { Struct::Service.new('the_service_name', 'the_plan_name') }

      it 'waits for service creation to have succeded' do
        expect(hula_cloud_foundry).to receive(:get_service_status).at_least(:twice)
        expect{cloud_foundry.provision_service(service, {}, service_instance)}.not_to raise_error
      end

      context 'when a timeout error is thrown' do
        let(:retry_timeout) { 0.1 }
        let(:retry_interval) { 1 }

        it 'times out if wrong service instance name is checked' do
          expect(hula_cloud_foundry).to receive(:get_service_status).at_least(:once)
          expect{cloud_foundry.provision_service(service)}.to raise_error(Timeout::Error)
        end
      end

      context 'when get_service_status returns failure' do
        let(:state_under_test) { "create failed" }

        it 'throws when status matches the error condition' do
          expect(hula_cloud_foundry).to receive(:get_service_status).at_least(2).times
          expect{cloud_foundry.provision_service(service, {}, service_instance)}.to raise_error(/Error #{state_under_test} occured for service instance: /)
        end
      end
    end

    context 'block fails' do
      let(:state_under_test) { "provided block fails" }
      let(:service) { Struct::Service.new('the_service_name', 'the_plan_name') }
      let(:app) { Struct::App.new('panda') }

      before(:each) do
        allow(hula_cloud_foundry).to receive(:bind_app_to_service)
        allow(hula_cloud_foundry).to receive(:start_app)
        allow(hula_cloud_foundry).to receive(:unbind_app_from_service)
      end

      it 'unbinds the service if there is an error in the block' do
          expect(hula_cloud_foundry).to receive(:unbind_app_from_service).at_least(1).times

          expect {
            cloud_foundry.bind_service_and_run(app, service_instance) { |a, b|
              raise "ImAnError"
            }
          }.to raise_error("ImAnError")
      end
    end

    context 'delete service' do
      let(:state_under_test) { "Service instance #{service_instance_name} not found" }

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
        let(:state_under_test) { "delete failed" }

        it 'throws when status matches the error condition' do
          err_message = "Error #{state_under_test} occured for service instance: #{service_instance.name}"

          expect(hula_cloud_foundry).to receive(:get_service_status).exactly(2).times
          expect{cloud_foundry.delete_service_instance_and_unbind(service_instance)}.to raise_error(err_message)
        end
      end
    end
  end
end
