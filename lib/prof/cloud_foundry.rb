# Copyright (c) 2014-2016 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'forwardable'
require 'hula/cloud_foundry'

require 'prof/marketplace_service'
require 'prof/pushed_test_app'
require 'prof/service_instance'

module Prof
  class CloudFoundry
    extend Forwardable

    attr_reader :api_url, :domain, :username, :password, :retry_timeout, :retry_interval

    def_delegators :hula_cloud_foundry,
                   :add_public_service_broker,
                   :app_env,
                   :create_org,
                   :target_org,
                   :create_space,
                   :target_space,
                   :create_and_target_org,
                   :create_and_target_space,
                   :create_service_instance,
                   :delete_org,
                   :delete_space,
                   :delete_service_instance_and_unbind,
                   :push_app_and_start,
                   :remove_service_broker,
                   :service_brokers,
                   :setup_permissive_security_group,
                   :app_vcap_services,
                   :marketplace,
                   :info

    def initialize(opts = {})
      @domain   = opts.fetch(:domain)
      @api_url  = opts.fetch(:api_url) { "https://api.#{domain}" }
      @username = opts.fetch(:username)
      @password = opts.fetch(:password)

      @retry_interval = opts.fetch(:retry_interval) { 5 }
      @retry_timeout  = opts.fetch(:retry_timeout)  { 720 }

      @hula_cloud_foundry = opts.fetch(:hula_cloud_foundry) if opts.key?(:hula_cloud_foundry)
    end

    def push_and_keep_app(app, pushed_app_name = "cf-app-#{SecureRandom.hex(4)}")
      deployed_app    = PushedTestApp.new(name: pushed_app_name, url: hula_cloud_foundry.url_for_app(pushed_app_name))

      hula_cloud_foundry.push_app(app.path, deployed_app.name)
      [deployed_app.name, deployed_app.url]
    end

    def push_app(app, &_block)
      pushed_app_name = "cf-app-#{SecureRandom.hex(4)}"
      deployed_app    = PushedTestApp.new(name: pushed_app_name, url: hula_cloud_foundry.url_for_app(pushed_app_name))

      hula_cloud_foundry.push_app(app.path, deployed_app.name)

      yield deployed_app
    ensure
      hula_cloud_foundry.delete_app deployed_app.name
    end

    def enable_diego_and_start_app(app)
      hula_cloud_foundry.enable_diego_for_app(app.name)
      hula_cloud_foundry.start_app(app.name)
    end

    def push_app_and_bind_with_service(app, service, &_block)
      push_app(app) do |pushed_app|
        provision_service(service) do |service_instance|
          bind_service_and_run(pushed_app, service_instance) do
            yield pushed_app, service_instance
          end
        end
      end
    end

    def push_app_and_bind_with_service_instance(app, service_instance, &_block)
      push_app(app) do |pushed_app|
        bind_service_and_run(pushed_app, service_instance) do
          yield pushed_app, service_instance
        end
      end
    end

    def bind_service_and_keep_running(pushed_app_name, service_instance_name)
      hula_cloud_foundry.bind_app_to_service(pushed_app_name, service_instance_name)
      hula_cloud_foundry.start_app(pushed_app_name)
    end

    def bind_service_and_run(pushed_app, service_instance, &_block)
      hula_cloud_foundry.bind_app_to_service(pushed_app.name, service_instance.name)
      hula_cloud_foundry.start_app(pushed_app.name)

      yield

      hula_cloud_foundry.unbind_app_from_service(pushed_app.name, service_instance.name)
    end

    def unbind_app_from_service(pushed_app, service_instance)
      hula_cloud_foundry.unbind_app_from_service(pushed_app.name, service_instance.name)
    end

    def provision_and_create_service_key(service, &_block)
      provision_service(service) do |service_instance|
        create_service_key(service_instance) do |service_key, service_key_data|
          yield service_instance, service_key, service_key_data
        end
      end
    end

    def list_service_keys(service_instance)
      hula_cloud_foundry.list_service_keys(service_instance.name)
    end

    def create_service_key(service_instance, &_block)
      service_key_name = "#{service_instance.name}-#{SecureRandom.hex(4)}"
      hula_cloud_foundry.create_service_key(service_instance.name, service_key_name)
      service_key_raw = hula_cloud_foundry.service_key(service_instance.name, service_key_name)
      service_key_data = JSON.parse(
        service_key_raw.split("\n").slice(2..-1).join
      )

      yield service_key_name, service_key_data

      hula_cloud_foundry.delete_service_key(service_instance.name, service_key_name)
    end

    def delete_service_key(service_instance, service_key)
      hula_cloud_foundry.delete_service_key(service_instance.name, service_key)
    end

    def provision_and_keep_service(service)
      service_instance = ServiceInstance.new

      hula_cloud_foundry.create_service_instance(service.name, service_instance.name, service.plan)
      service_instance.name
    end

    def provision_service(service, options = {}, &_block)
      service_instance = ServiceInstance.new

      hula_cloud_foundry.create_service_instance(service.name, service_instance.name, service.plan)
      wait_for_service_state(service_instance, "create succeeded", "create failed")

      yield service_instance if block_given?

    ensure
      hula_cloud_foundry.delete_service_instance_and_unbind(service_instance.name, options)
    end

    def delete_service_instance_and_unbind(service_instance, options = {})
      hula_cloud_foundry.delete_service_instance_and_unbind(service_instance.name, options)

      wait_for_service_state(service_instance, "Service instance #{service_instance.name} not found", "delete failed")
    end

    def auth_token
      hula_cloud_foundry.auth_token
    end

    private

    def wait_for_service_state(service_instance, expected_state, failure_state)
      Timeout::timeout(retry_timeout) do
        loop do
          status = hula_cloud_foundry.get_service_status(service_instance.name)
          return if status.include? expected_state
          raise "Error #{failure_state} occured for service instance: #{service_instance.name}" if status.include? failure_state
          sleep retry_interval
        end
      end
    end

    def hula_cloud_foundry
      @hula_cloud_foundry ||= Hula::CloudFoundry.new(
        api_url:  api_url,
        domain:   domain,
        username: username,
        password: password
      )
    end
  end
end
