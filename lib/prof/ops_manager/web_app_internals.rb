# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ops_manager/web_app_internals/page/dashboard'
require 'prof/ops_manager/web_app_internals/page/flash_message'
require 'prof/ops_manager/web_app_internals/page/login'
require 'prof/tile'

module Prof
  class OpsManager
    class WebAppInternals
      def initialize(dashboard, opsmanager_client, page, url)
        @dashboard      = dashboard
        @page           = page
        @opsmanager_client = opsmanager_client
        @url            = url
      end

      def apply_changes
        visit
        check_nothing_in_progress!
        return unless dashboard.pending_changes?
        raise 'Could not apply changes' unless dashboard.apply_changes.install_successful?
      end

      def tile_uninstall(tile)
        return unless opsmanager_client.product_type_installed?(tile)
        visit
        check_nothing_in_progress!
        raise 'Uninstall was not successful' unless dashboard.tile_uninstall(tile)
      end

      private

      attr_reader :dashboard, :page, :opsmanager_client, :url

      def visit
        page.visit(url) unless page.current_url == url
      end

      def flash_message
        Page::FlashMessage.new(page: page)
      end

      def check_nothing_in_progress!
        raise 'Installation already in progress' if flash_message.installation_in_progress?
      end

      def add_cf_tile_if_needed
        unless page.has_selector?("a[id='show-cf-configure-action']")
          page.find('#add-cf', visible: false).trigger('click')
        end
      end
    end
  end
end
