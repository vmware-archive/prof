# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ops_manager/rails_500_error'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        class Rails500
          def initialize(page:)
            @page = page
          end

          def matches?
            page.all('.error-page.rails-env-production').any?
          end

          def error
            Rails500Error.new(message)
          end

          private

          attr_reader :page

          def message
            page.all('.error').map(&:text).join("\n")
          end
        end
      end
    end
  end
end
