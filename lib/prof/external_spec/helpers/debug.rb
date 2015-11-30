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
  module ExternalSpec
    module Helpers
      module Debug

        def recording_exceptions
          yield
        rescue Exception => ex
          @recorded_exception = ex
          raise
        end

        def save_exceptions
          yield
        rescue Exception => ex
          ops_manager.browser do |page|
            name = "failure"
            puts "Saving failure data for '#{name}'"
            page.save_page("#{name}.html")
            page.save_screenshot("#{name}.png")
          end
          raise
        end

        def save_exception_output(example)
          unless @recorded_exception
            return unless example.respond_to?(:exception)
            return unless example.respond_to?(:full_description)
            return unless respond_to?(:ops_manager)
            return unless example.exception
          end

          ops_manager.browser do |page|
            name = example.full_description.gsub(/\W/, '_')
            puts "Saving failure data for '#{name}'"
            page.save_page("#{name}.html")
            page.save_screenshot("#{name}.png")
          end
        end
      end
    end
  end
end
