# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

shared_examples_for 'a basic service' do
  it 'allows a user to use the service' do
    cloud_foundry.push_app_and_bind_with_service(test_app, service) do |pushed_app|
      pushed_app.write('test_key', 'test_value')
      expect(pushed_app.read('test_key')).to eq('test_value')
    end
  end
end

shared_examples_for 'a service that has distinct instances' do
  it 'has distinct instances' do
    service_broker.provision_and_bind(service.name, service.plan) do |binding_1|
      service_client_1 = service_client_builder(binding_1)
      service_client_1.write('test_key', 'test_value')

      service_broker.provision_and_bind(service.name, service.plan) do |binding_2|
        service_client_2 = service_client_builder(binding_2)
        service_client_2.write('test_key', 'another_test_value')
        expect(service_client_1.read('test_key')).to eq('test_value')
        expect(service_client_2.read('test_key')).to eq('another_test_value')
      end
    end
  end
end

shared_examples_for 'a service that can be shared by multiple applications' do
  it 'allows two applications to share the same instance' do
    service_broker.provision_instance(service.name, service.plan) do |service_instance|
      service_broker.bind_instance(service_instance, service.name, service.plan) do |binding_1|
        service_client_1 = service_client_builder(binding_1)
        service_client_1.write('shared_test_key', 'test_value')
        expect(service_client_1.read('shared_test_key')).to eq('test_value')

        service_broker.bind_instance(service_instance, service.name, service.plan) do |binding_2|
          service_client_2 = service_client_builder(binding_2)
          expect(service_client_2.read('shared_test_key')).to eq('test_value')
        end

        expect(service_client_1.read('shared_test_key')).to eq('test_value')
      end
    end
  end
end

shared_examples_for 'a service which preserves data across binding and unbinding' do
  it 'preserves data across binding and unbinding' do
    service_broker.provision_instance(service.name, service.plan) do |service_instance|
      service_broker.bind_instance(service_instance, service.name, service.plan) do |binding|
        service_client_builder(binding).write('unbound_test_key', 'test_value')
      end

      service_broker.bind_instance(service_instance, service.name, service.plan) do |binding|
        expect(service_client_builder(binding).read('unbound_test_key')).to eq('test_value')
      end
    end
  end
end

shared_examples_for 'a service which preserves data when recreating the broker VM' do
  it 'preserves data when recreating vms' do
    service_broker.provision_and_bind(service.name, service.plan) do |binding|
      service_client = service_client_builder(binding)
      service_client.write('test_key', 'test_value')
      expect(service_client.read('test_key')).to eq('test_value')

      bosh_director.recreate_all([environment.bosh_service_broker_job_name])

      expect(service_client.read('test_key')).to eq('test_value')
    end
  end
end

shared_examples_for 'a persistent cloud foundry service' do
  describe 'a persistent cloud foundry service' do
    it_behaves_like 'a service that has distinct instances'
    it_behaves_like 'a service that can be shared by multiple applications'
    it_behaves_like 'a service which preserves data across binding and unbinding'
    if !method_defined?(:manually_drain)
      it_behaves_like 'a service which preserves data when recreating the broker VM'
    end
  end
end

# DEPRECATED
shared_examples_for 'a service which preserves data when recreating VMs' do
  it do
    pending "switch shared example to 'a service which preserves data when recreating the broker VM'"
  end
end

shared_examples_for 'a multi-tenant service' do
  it do
    pending "switch shared example to 'a persistent cloud foundry service'"
  end
end
