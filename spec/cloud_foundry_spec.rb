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

  describe 'create service' do
    let!(:options) do
      {
        domain:   "somedomain.com",
        username: "some-user",
        password: "some-password",
        hula_cloud_foundry: hula_cloud_foundry,
      }
    end

    let(:hula_cloud_foundry) do
      hula_cloud_foundry = double
      allow(hula_cloud_foundry).to receive(:get_service_status).and_return(
       'in progress',
       'create succeeded'
      )

      allow(hula_cloud_foundry).to receive(:delete_service_instance_and_unbind)
        .and_return('delete in progress')
      allow(hula_cloud_foundry).to receive(:create_service_instance)
        .and_return('create in progress')
      hula_cloud_foundry
    end

    it 'waits for service creation to have succeded' do
      Struct.new('Service', :name, :plan)
      service = Struct::Service.new('the_service_name', 'the_plan_name')

      expect(hula_cloud_foundry).to receive(:get_service_status).twice

      cloud_foundry.provision_service service do |service_instance|
        expect(service_instance).not_to be_nil
      end
    end
  end
end
