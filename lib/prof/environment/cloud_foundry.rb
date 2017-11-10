# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'hula/bosh_director'
require 'hula/service_broker/client'
require 'hula/bosh_manifest'
require 'hula/socks4_proxy_ssh'
require 'hula/http_proxy_upstream_socks'

require 'prof/cloud_foundry'
require 'prof/ssh_gateway'
require 'prof/uaa_client'

module Prof
  module Environment
    class CloudFoundry
      attr_reader :bosh_service_broker_job_name

      def initialize(
        cloud_foundry_domain:      nil,

        cloud_controller_identity: 'cloud_controller',
        cloud_controller_password: 'cc-secret',

        cloud_foundry_username:    'admin',
        cloud_foundry_password:    'admin',
        cloud_foundry_api_url:      nil,

        bosh_target:               'https://192.168.50.4:25555',
        bosh_username:             'admin',
        bosh_password:             'admin',
        bosh_ca_cert_path:         nil,
        bosh_env_login:            false,

        ssh_gateway_host:          '192.168.50.4',
        ssh_gateway_username:      'vagrant',
        ssh_gateway_password:      'vagrant',
        ssh_gateway_private_key:   nil,

        bosh_service_broker_job_name:,
        bosh_manifest_path:,

        use_proxy:                 true
      )
        @cloud_foundry_domain = cloud_foundry_domain
        @cloud_controller_identity = cloud_controller_identity
        @cloud_controller_password = cloud_controller_password
        @cloud_foundry_username = cloud_foundry_username
        @cloud_foundry_password = cloud_foundry_password
        @bosh_target = bosh_target
        @bosh_username = bosh_username
        @bosh_password = bosh_password
        @bosh_ca_cert_path = bosh_ca_cert_path
        @bosh_env_login = bosh_env_login
        @ssh_gateway_host = ssh_gateway_host
        @ssh_gateway_username = ssh_gateway_username
        @ssh_gateway_password = ssh_gateway_password
        @ssh_gateway_private_key = ssh_gateway_private_key
        @bosh_service_broker_job_name = bosh_service_broker_job_name
        @bosh_manifest_path = bosh_manifest_path
        @cloud_foundry_api_url = cloud_foundry_api_url
        @use_proxy = use_proxy
      end

      def cloud_foundry
        @cloud_foundry ||= ::Prof::CloudFoundry.new(
          domain:   cloud_foundry_domain,
          username: cloud_foundry_username,
          password: cloud_foundry_password,
          api_url:  cloud_foundry_api_url
        )
      end

      def bosh_manifest
        @bosh_manifest ||= Hula::BoshManifest.from_file(bosh_manifest_path)
      end

      def cloud_foundry_domain
        @cloud_foundry_domain ||= bosh_manifest.property('cf.domain')
      end

      def service_broker
        @service_broker ||= Hula::ServiceBroker::Client.new(
          url: URI::HTTPS.build(host: broker_registrar_properties.fetch('host')),
          username: broker_registrar_properties.fetch('username'),
          password: broker_registrar_properties.fetch('password'),
          http_client: http_json_client(use_proxy: use_proxy)
        )
      end

      def service_broker_name
        broker_registrar_properties.fetch('name')
      end

      def bosh_director
        @bosh_director ||= Hula::BoshDirector.new(
          target_url:       bosh_target,
          username:         bosh_username,
          password:         bosh_password,
          manifest_path:    bosh_manifest_path,
          certificate_path: bosh_ca_cert_path,
          env_login:        bosh_env_login
        )
      end

      def ssh_gateway
        opts = {
          gateway_host:     ssh_gateway_host,
          gateway_username: ssh_gateway_username,
        }

        if @ssh_gateway_private_key
          opts[:gateway_private_key] = ssh_gateway_private_key
        else
          opts[:gateway_password] = ssh_gateway_password
        end

        @ssh_gateway ||= Prof::SshGateway.new(opts)
      end

      def cloud_foundry_uaa
        @cloud_foundry_uaa ||= UAAClient.new(
          cloud_foundry_domain,
          cloud_controller_identity,
          cloud_controller_password
        )
      end

      def socks4_proxy
        @socks4_proxy ||= Hula::Socks4ProxySsh.new(
          ssh_username: ssh_gateway_username,
          ssh_password: ssh_gateway_password,
          ssh_host:     ssh_gateway_host
        ).tap(&:start)
      end

      def http_proxy
        @http_proxy ||= Hula::HttpProxyUpstreamSocks.new(socks_proxy: socks4_proxy).tap(&:start)
      end

      private

      attr_reader :cloud_controller_identity, :cloud_controller_password,
                  :cloud_foundry_username, :cloud_foundry_password, :bosh_target, :bosh_username, :bosh_password,
                  :ssh_gateway_host, :ssh_gateway_username, :ssh_gateway_password, :bosh_manifest_path,
                  :cloud_foundry_api_url, :use_proxy, :ssh_gateway_private_key, :bosh_ca_cert_path, :bosh_env_login

      def broker_registrar_properties
        begin
          bosh_manifest.job('broker-registrar').properties.fetch('broker')
        rescue RuntimeError
          # for colocated errands, the errand's instance group might not exist
          bosh_manifest.properties.fetch('broker')
        end
      end

      def http_json_client(use_proxy:)
        proxy = use_proxy ? http_proxy : Hula::ServiceBroker::HttpProxyNull.new
        @http_json_client ||= Hula::ServiceBroker::HttpJsonClient.new(http_proxy: proxy)
      end
    end
  end
end
