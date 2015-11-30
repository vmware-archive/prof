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
        class FlashMessage
          def initialize(opts = {})
            @page = opts.fetch(:page)
          end

          def text
            page.find('.flash-message:not(.in-progress)', wait: 60).text
          end

          def success?
            !error? && page.all('.flash-message.success').any?
          end

          def error?
            page.all('.flash-message.error').any?
          end

          def installation_in_progress?
            page.all('.flash-message.in-progress').any?
          end

          def icmp_error?
            return false unless error?
            error = page.all('.flash-message.error').first.text
            error.include? 'ignorable if ICMP is disabled'
          end

          def ignore_warnings
            page.find('#ignore-install-action').click
          end

          private

          attr_reader :page
        end
      end
    end
  end
end
