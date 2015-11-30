# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ops_manager/web_app_internals/page/form_error'
require 'prof/ops_manager/web_app_internals/page/flash_message'
require 'prof/ops_manager/web_app_internals/page/form_fields'
require 'prof/ops_manager/web_app_internals/page/form_field'
require 'prof/ops_manager/web_app_internals/page/select_field'
require 'prof/ops_manager/web_app_internals/page/checkbox_field'
require 'prof/ops_manager/web_app_internals/page/click_field'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class Form
          def initialize(opts = {})
            @page         = opts.fetch(:page)
            @form_element = opts.fetch(:form_element)
          end

          def update(config = {}, &_block)
            case config
            when Array
              update_list(config)
            when Hash, FormFields
              raise "Add button on page #{page.current_url}, maybe you should update a list?" if add_button

              update_fields(config)
            else
              raise "Unrecognised config #{config.inspect}"
            end

            yield self, page if block_given?

            form_element.click_on 'Save'

            # raise "Failed to save, the server 500ed" if page.status_code.to_i >= 500
            raise "Failed to save, no success message. #{error_message}" unless success?
          end

          private

          attr_reader :form_element, :page

          def update_list(list)
            raise "No add button on page #{page.current_url}, are you sure you want to update a list?" unless add_button
            clear_list

            list.each do |item_config|
              add_button.click

              update_fields(item_config)
            end
          end

          def clear_list
            form_element.all('.with-delete-record').each(&:click)
          end

          def add_button
            form_element.first(:link_or_button, 'Add')
          end

          def update_fields(config)
            if(config.is_a? FormFields)
              update_fields_from_form_fields(config)
            else
              update_fields_from_string_hash(config)
            end
          end

          def update_fields_from_string_hash(config)
            config.each do |field, value|
              selector = field_to_selector(field)
              input    = form_element.all(selector).last

              raise "Could not find element with selector #{selector}" unless input

              if input.tag_name == 'select'
                input.find(:option, value).select_option
              else
                input.set(value)
              end
            end
          end

          def update_fields_from_form_fields(config)
            config.each do |field|
              field.set(form_element)
            end
          end

          def field_to_selector(field)
            if field.include?('[') && field.include?(']')
              "[name='#{field}']"
            else
              "[name$='#{field}]']"
            end
          end

          def success?
            flash_message.success?
          end

          def error_message
            "#{flash_message.text} #{errors.join(', ')}"
          end

          def flash_message
            FlashMessage.new(page: page)
          end

          def errors
            form_element.all('.help-block').map do |error_element|
              FormError.new(error_element: error_element)
            end
          end
        end
      end
    end
  end
end
