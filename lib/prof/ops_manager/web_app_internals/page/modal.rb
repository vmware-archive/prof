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
        class Modal

          ModalStillPresent = Class.new(StandardError)

          def initialize(page:)
            @page = page
          end

          def confirm
            # We have spent a long time trying to debug unreliable clicking of confirm
            # in both Selenium and Poltegeist. The box is animated which we think is causing
            # issues with where the browser is clicking. A sleep will resolve this, and has
            # lowest complexity.
            Kernel.sleep(3)

            confirm_button.click

            await_modal_disappearance!
            true
          end

          def success?
            /success/ =~ modal['id']
          end

          def failure?
            /failure/ =~ modal['id']
          end

          def message
            modal.find('.modal-body').text
          end

          def present?
            page.all(modal_css_selector).any? || page.all('.modal-backdrop').any?
          rescue Capybara::Poltergeist::ObsoleteNode
            false
          end

          private

          attr_reader :page

          def await_modal_disappearance!
            # Modal takes a long time to disappear as the next page can take a
            # long time to load
            page.document.synchronize(60, errors: [ModalStillPresent]) do
              raise ModalStillPresent if present?
            end
          end

          def modal_css_selector
            '.modal.in'
          end

          def modal
            page.find(modal_css_selector)
          end

          def confirm_button
            modal.find('.modal-footer .btn-primary')
          end

          def poltergeist?
            page.driver.class.to_s == 'Capybara::Poltergeist::Driver'
          end
        end
      end
    end
  end
end
