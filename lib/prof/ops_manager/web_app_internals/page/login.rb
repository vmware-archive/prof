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
require 'prof/ops_manager/web_app_internals/page/dashboard'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class Login
          def initialize(page:, url:, username:, password:, version:)
            @page     = page
            @url      = url
            @username = username
            @password = password
            @version  = version

            resp = page.visit login_url

            if resp['status'] == 'fail'
              raise StandardError.new("Failed to fetch url: #{login_url}")
            end
          end

          def login
            puts "Logging into tempest at #{login_url}"
            if login_via_uaa?
              uaa_login
            else
              basic_login
            end

            Dashboard.new(page: page)
          end

          private

          attr_reader :page, :url, :username, :password, :version

          def login_url
            if login_via_uaa?
              uaa_login_url
            else
              basic_login_url
            end
          end

          def login_via_uaa?
            version >= Gem::Version.new("1.7")
          end

          def uaa_login_url
            URI.join(url, "uaa/login")
          end

          def basic_login_url
            URI.join(url, 'login')
          end

          def uaa_login
            page.fill_in 'username', with: username
            page.fill_in 'password', with: password
            page.click_on 'Sign in'
          end

          def basic_login
            page.fill_in 'login[user_name]', with: username
            page.fill_in 'login[password]', with: password
            page.click_on 'login-action'
          end
        end
      end
    end
  end
end
