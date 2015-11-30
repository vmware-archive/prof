# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ops_manager/web_app_internals/page/modal'
require 'prof/ops_manager/web_app_internals/page/flash_message'
require 'prof/ops_manager/web_app_internals/page/rails_500'

require 'nokogiri'

module Prof
  class OpsManager

    class InstallationError < StandardError; end

    class WebAppInternals
      module Page
        class InstallationProgress
          MAX_INSTALL_STEP_SECONDS = 60 * 45

          class TimeoutWaitingForStep < InstallationError; end

          def initialize(page:, output: STDOUT)
            @page   = page
            @output = output

            if flash_message.icmp_error?
              flash_message.ignore_warnings
            end

            raise InstallationError, flash_message.text if flash_message.error?
          end

          def install_successful?
            install_steps.each do |step|
              wait_until_completed step
            end

            if modal.success?
              modal.confirm
              return true
            else
              output.puts modal.message
              modal.confirm
              return false
            end
          end

          private

          attr_reader :page, :output

          def log(dt, _step)
            elapsed_time = sprintf('%02i:%02i:%02i', dt / 3600, dt / 60, dt % 60)
            output.puts " done. [#{elapsed_time}]"
          end

          def wait_until_completed(step)
            start = Time.now
            output.print "Running step [#{step.index}/#{step.total}]: #{step}..."
            page.document.synchronize(MAX_INSTALL_STEP_SECONDS, errors: [TimeoutWaitingForStep]) do
              raise TimeoutWaitingForStep, "Timed out after #{MAX_INSTALL_STEP_SECONDS} seconds waiting for #{step.name} to finish.\n\n#{verbose_output}" unless step.finished?
            end
            duration = Time.now - start

            log(duration, step)
          end

          def modal
            Modal.new(page: page)
          end

          def flash_message
            FlashMessage.new(page: page)
          end

          def install_steps
            @install_steps ||= begin
              step_nodes = page.all('#install-steps .step')
              raise rails_500.error if rails_500?
              raise 'No install steps found' if step_nodes.empty?

              step_nodes.map.with_index(1) do |node, index|
                InstallStep.new(node: node, page: page, index: index, total: step_nodes.size)
              end
            end
          end

          def verbose_output
            Nokogiri::HTML(page.html).css('.output').text
          end

          def rails_500?
            rails_500.matches?
          end

          def rails_500
            Rails500.new(page: page)
          end

          class InstallStep
            class InstallStepNotPresent < InstallationError; end

            def initialize(node:, page:, index: index, total: total)
              @id    = node['data-step-id']
              @page  = page
              @index = index
              @total = total
            end

            def name
              node.text
            end

            def finished?
              state == 'finished'
            end

            def state
              node['data-step-state']
            end

            def to_s
              name
            end

            attr_reader :index, :total

            private

            attr_reader :page, :id

            def node
              page.find("[data-step-id='#{id}']")
            rescue Capybara::ElementNotFound
              raise InstallStepNotPresent, "The install step '#{id}'' is no longer on the page - has Ops Manager crashed?"
            end
          end
        end
      end
    end
  end
end
