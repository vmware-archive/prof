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
        class FormError
          def initialize(opts = {})
            @error_element = opts.fetch(:error_element)
          end

          def name
            /[^\[]*\[([^\]]+)\]$/.match(full_name).to_a[1]
          end

          def error
            error_element.text
          end

          def to_s
            "#{name} #{error}"
          end

          private

          attr_reader :error_element

          def full_name
            error_element.find('~ input')[:name]
          end
        end
      end
    end
  end
end
