# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ops_manager/web_app_internals/page/installation_progress'
require 'prof/ops_manager/web_app_internals/page/modal'
require 'prof/ops_manager/web_app_internals/page/tile_settings'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class Dashboard

          class ModalPresent < StandardError; end

          def initialize(opts = {})
            @page = opts.fetch(:page)
          end

          def tile(tile)
            begin
              page.find("#show-#{tile.name}-configure-action").click
            rescue Capybara::ElementNotFound
              page.visit(page.current_url)
              page.find("#show-#{tile.name}-configure-action").click
            end

            TileSettings.new(page: page)
          end

          def tile_configure(target_tile, configuration)
            tile(target_tile).configure(configuration)
          end

          def tile_configuration(target_tile)
            tile_setting_page = tile(target_tile)

            Hash.new.tap do |config|
              tile_setting_page.setting_names.each do |setting_name|
                config[setting_name] = tile_setting_page.settings_for(setting_name)
              end

              tile_setting_page.return_to_dashboard
            end
          end

          def apply_setting(target_tile, field_name, field_value)
            tile(target_tile).set_field_value('Resource Config', field_name, field_value).return_to_dashboard
          end

          def tile_configured?(target_tile)
            page.find("#show-#{target_tile.name}-configure-action")['data-progress'] == '100'
          rescue Capybara::ElementNotFound
            false
          end

          def tile_uninstall(target_tile)
            page.find("#show-#{target_tile.name}-configure-action ~ #open-delete-#{target_tile.name}-modal").click
            modal.confirm
          rescue Capybara::ElementNotFound
          end

          def apply_changes
            check_no_modal!

            page.click_link_or_button 'Apply changes'
            InstallationProgress.new(page: page)
          end

          def pending_changes?
            pending_changes.any?
          end

          def pending_changes
            page.all('.pending-changes-list li').map(&:text)
          end

          private

          attr_reader :page

          def check_no_modal!
            raise ModalPresent, "A modal was present with text: '#{modal.message}'" if modal.present?
          end

          def modal
            Modal.new(page: page)
          end
        end
      end
    end
  end
end
