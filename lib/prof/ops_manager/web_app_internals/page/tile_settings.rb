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
require 'prof/ops_manager/web_app_internals/page/form'
require 'uri'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class TileSettings
          def initialize(opts = {})
            @page = opts.fetch(:page)

            check_on_settings!
          end

          def setting_names
            page.all('.sidebar li').map(&:text)
          end

          def set_field_value(setting_name, field_name, field_value)
            sidebar(setting_name)
            update(field_name => field_value)
          end

          def settings_for(setting_name)
            sidebar(setting_name)

            config = {}
            page.all(".content #{fields_selector}").each do |input|
              config[input['name']] = if config[input['name']]
                                        [input.value] + Array(config[input['name']])
                                      else
                                        input.value
                                      end
            end
            config
          end

          def configure(configuration)
            configuration.each { |sidebar_name, config| sidebar(sidebar_name).update(config) }
            return_to_dashboard
          end

          def update(config = {}, &block)
            form.update config, &block
            self
          end

          def sidebar(next_settings_name, &_block)
            return self if next_settings_name == current_setting_name

            page.find('.sidebar li a', text: /^\s*#{next_settings_name}\s*$/).click

            if block_given?
              yield page
              return_to_dashboard
            else
              TileSettings.new(page: page)
            end
          end

          def return_to_dashboard
            page.click_on 'Installation Dashboard'
            Dashboard.new(page: page)
          end

          def current_uri
            URI(page.current_url)
          end

          private

          attr_reader :page

          def current_setting_name
            page.find('.sidebar li.active').text
          end

          def fields_selector
            'input[type="text"],textarea,input[type="checkbox"][checked],input[type="radio"][selected],select'
          end

          def form
            @form ||= Form.new(page: page, form_element: page.find('.content form'))
          end

          def check_on_settings!
            return if current_uri.path.end_with?('edit')
            raise "Expected to be on a settings page, but am on #{page.current_url}"
          end
        end
      end
    end
  end
end
