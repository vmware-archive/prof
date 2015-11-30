# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'uaa'

module Prof
  class UAAClient
    def initialize(system_domain, cloud_controller_username, cloud_controller_password)
      @system_domain             = system_domain
      @cloud_controller_username = cloud_controller_username
      @cloud_controller_password = cloud_controller_password
    end

    def register_user(user)
      scim.add(:user, scim_info(user))
    end

    def unregister_user(user)
      scim.delete(:user, scim.id(:user, user.username))
    end

    private

    attr_reader :system_domain, :cloud_controller_username, :cloud_controller_password

    def scim_info(user)
      {
        userName: user.username,
        password: user.password,
        emails: [{value: user.email}]
      }
    end

    def scim
      CF::UAA::Scim.new(
        uaa_url,
        auth_header,
        skip_ssl_validation: true
      )
    end

    def auth_header
      token_issuer.client_credentials_grant.auth_header
    end

    def token_issuer
      CF::UAA::TokenIssuer.new(
        uaa_url,
        cloud_controller_username,
        cloud_controller_password,
        skip_ssl_validation: true
      )
    end

    def uaa_url
      "https://uaa.#{system_domain}"
    end
  end
end
