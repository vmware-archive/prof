# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'spec_helper'

require 'prof/external_spec/helpers/capybara'
require 'prof/ops_manager/web_app_internals/page/form'
require 'prof/ops_manager/web_app_internals/page/form_field'
require 'prof/ops_manager/web_app_internals/page/form_fields'
require 'prof/ops_manager/web_app_internals/page/checkbox_field'
require 'prof/ops_manager/web_app_internals/page/select_field'

module Prof
  class OpsManager
    class WebAppInternals
      module Page
        describe Form do
          let(:html) do
            <<-HTML
            <html>
            <body>
              <form>
                <input type="text" name="rabbitmq-broker[server_admin_credentials][identity]" value="original"/>
                <input type="checkbox" name="rabbitmq-broker[plugins][]" value="mqtt"/>
                <input type="checkbox" name="rabbitmq-broker[plugins][]" value="stomp" checked="checked" />

                <select name="rabbitmq-broker[server_admin_credentials][selectbox]">
                  <option value="original" selected="selected">original</option>
                  <option value="new_value">new_value</option>
                </select>

                <a href="#">Save</a>
              </form>
              <div class="flash-message success"></div>
              </body>
              </html>
            HTML
          end
          let(:session) { Capybara::Session.new(:poltergeist, app) }
          let(:app) do
            proc do |env|
              [200, {"Content-Type" => "text/html"}, [html]]
            end
          end
          let(:opts) {
            { page: session, form_element: session }
          }
          let(:form) {Form.new(opts)}

          before(:each) do
            session.visit('/')
          end


          describe "#update" do
            context "when provided FormField instances" do
              let(:fields) do
                FormFields.new(
                  [
                    FormField.new(name: 'rabbitmq-broker[server_admin_credentials][identity]', value: 'admin'),
                    CheckboxField.new(name: 'rabbitmq-broker[plugins][]', value: "mqtt", checked: true),
                    SelectField.new(name: 'rabbitmq-broker[server_admin_credentials][selectbox]', value: "new_value")
                  ]
                )
              end

              it "updates the fields" do
                expect{
                  form.update(fields)
                }.to change {
                  session.find('[name$="rabbitmq-broker[server_admin_credentials][identity]"]').value()
                }.from("original").to("admin").and change{
                  session.find('[name$="rabbitmq-broker[plugins][]"][value$="mqtt"]').checked?
                }.from(false).to(true).and change{
                  session.find('[name$="rabbitmq-broker[server_admin_credentials][selectbox]"]').value()
                }.from("original").to("new_value")
              end
            end

            context "when provided a hash of string => string" do
              let(:fields) do
                {
                    'rabbitmq-broker[server_admin_credentials][identity]' => 'admin',
                    'rabbitmq-broker[server_admin_credentials][selectbox]' => 'new_value'
                }
              end

              it "updates the fields" do
                expect{
                  form.update(fields)
                }.to change {
                  session.find('[name$="rabbitmq-broker[server_admin_credentials][identity]"]').value()
                }.from("original").to("admin").and change{
                  session.find('[name$="rabbitmq-broker[server_admin_credentials][selectbox]"]').value()
                }.from("original").to("new_value")
              end
            end
          end
        end
      end
    end
  end
end
