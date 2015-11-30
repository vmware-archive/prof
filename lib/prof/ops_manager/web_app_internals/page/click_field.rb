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
        class ClickField < FormField
          def initialize(name:, expected_state: )
            super(name: name, value: nil)
            @expected_state = expected_state
          end

          private

          attr_reader :expected_state

          def selector
            super + ":not([type=hidden])"
          end

          def set_value(field)
            unless field.checked? == expected_state
              field.click
            end
          end
        end
      end
    end
  end
end
