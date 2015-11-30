# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ops_manager/web_app_internals/page/form_field'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class CheckboxField < FormField
          def initialize(name:, value:, checked:)
            super(name: name, value: value)
            @checked = checked
          end

          private

          attr_reader :checked

          def selector
            super + "[value$='#{value}']"
          end

          def set_value(field)
            field.set(checked)
          end
        end
      end
    end
  end
end
