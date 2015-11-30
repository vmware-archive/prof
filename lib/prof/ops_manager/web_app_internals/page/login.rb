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
          def initialize(page:, url:, username:, password:)
            @page     = page
            @url      = url
            @username = username
            @password = password

            resp = page.visit login_url

            if resp['status'] == 'fail'
              raise StandardError.new("Failed to fetch url: #{login_url}")
            end
          end

          def login
            puts "Logging into tempest at #{login_url}"
            page.fill_in 'login[user_name]', with: username
            page.fill_in 'login[password]', with: password
            page.click_on 'login-action'

            Dashboard.new(page: page)
          end

          private

          attr_reader :page, :url, :username, :password

          def login_url
            URI.join(url, 'login')
          end
        end
      end
    end
  end
end
