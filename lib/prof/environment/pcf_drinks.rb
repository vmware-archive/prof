# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'uri'
require 'hula/bosh_director'
require 'capybara'

require 'prof/cloud_foundry'
require 'prof/ops_manager'
require 'prof/ssh_gateway'
require 'prof/uaa_client'

module Prof
  module Environment
    class NoDirectorVm < StandardError; end

    class PcfDrinks
      def initialize(tempest_config)
        @tempest_config = tempest_config
      end

      def ops_manager
        @ops_manager ||= OpsManager.new(environment_name: ENV.fetch('TEMPEST_ENVIRONMENT'), version: ENV.fetch('OM_VERSION'))
      end

      def cloud_foundry
        @cloud_foundry ||= Prof::CloudFoundry.new(
          domain:   cloud_foundry_domain,
          username: ops_manager.cf_admin_credentials.username,
          password: ops_manager.cf_admin_credentials.password
        )
      end

      def cloud_foundry_domain
        tempest_config.fetch('cloudfoundry').fetch('domain')
      end

      def bosh_director
        @bosh_director ||= Hula::BoshDirector.new(
          target_url:  bosh_director_url,
          username:    bosh_credentials.fetch('identity'),
          password:    bosh_credentials.fetch('password')
        )
      end

      def ssh_gateway
        SshGateway.new(
          gateway_host:     ssh_gateway_config.fetch('host'),
          gateway_username: ssh_gateway_config.fetch('username'),
          gateway_password: ssh_gateway_config['password'],
          ssh_key:          ssh_gateway_config['ssh_key']
        )
      end

      def cloud_foundry_uaa
        @cloud_foundry_uaa ||= UAAClient.new(
          cloud_foundry_domain,
          cloud_controller_client_credentials.identity,
          cloud_controller_client_credentials.password
        )
      end

      private

      attr_reader :tempest_config, :page

      def default_capybara_session
        Capybara::Session.new(Capybara.default_driver)
      end

      def cloud_controller_client_credentials
        @cloud_controller_client_credentials ||= ops_manager.cc_client_credentials
      end

      def forwarded_bosh_port
        @forwarded_bosh_port ||=
          ssh_gateway.with_port_forwarded_to(
            director.hostname,
            25555
          )
      end

      def director
        director = ops_manager.vms_for_job_type('director').first

        if director.nil?
          raise NoDirectorVm, "No director VM found for #{ops_manager.url}"
        else
          director
        end
      end

      def ops_manager_hostname
        URI.parse(ops_manager_config.fetch('url')).hostname
      end

      def ops_manager_config
        tempest_config.fetch('tempest')
      end

      def ssh_gateway_config
        tempest_config.fetch('proxy')
      end

      def bosh_director_url
        return URI("https://127.0.0.1:#{forwarded_bosh_port}").to_s if !tempest_config['proxy'].nil?
        return director.hostname
      end

      def bosh_credentials
        ops_manager.bosh_credentials
      end
    end
  end
end
