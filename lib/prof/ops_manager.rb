# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#
require 'opsmgr/api/client'
require 'opsmgr/environments'
require 'ostruct'

module Prof
  class OpsManager
    def initialize(environment_name:, version: "1.7")
      @api = Opsmgr::Api::Client.new(
        Opsmgr::Environments.for(environment_name),
        version
      )

      @api_installation_settings = @api.installation_settings
    end

    attr_reader :url

    def cf_admin_credentials
      OpenStruct.new({
        'username' => 'admin',
        'password' => @api_installation_settings.uaa_admin_password
      })
    end

    def bosh_credentials
      {
        'identity' => 'director',
        'password' => @api_installation_settings.director_password
      }
    end

    def system_domain
      @api_installation_settings.system_domain
    end

    def vms_for_job_type(job_type)
      manifest = @api_installation_settings.as_hash

      product = get_product_for_job(manifest, job_type)
      ips = @api_installation_settings.ips_for_job(product_name: product['identifier'], job_name: job_type)
      vm_credentials = product["jobs"].detect { |job| job["installation_name"] == job_type }['vm_credentials']

      ips.map do |ip|
        OpenStruct.new(
          :hostname => ip,
          :username => vm_credentials.fetch("identity"),
          :password => vm_credentials.fetch("password")
        )
      end
    end

    private

    def get_product_for_job(manifest, job_type)
      manifest["products"].detect do |product|
        product['jobs'].any? { |job| job['identifier'] == job_type }
      end
    end
  end
end
