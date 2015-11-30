# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class FormField

          def initialize(name:, value:)
            @name = name
            @value = value
          end

          def set(form_element)
            field = find_field(form_element)
            raise "Could not find element with name #{name} and selector #{selector}" unless field
            set_value(field)
          end

          private

          attr_reader :name, :value

          def find_field(form_element)
            form_element.all(selector).last
          end

          def set_value(field)
            field.set(value)
          end

          def selector
            if name.include?('[') && name.include?(']')
              "[name='#{name}']"
            else
              "[name$='[#{name}]']"
            end
          end
        end
      end
    end
  end
end
