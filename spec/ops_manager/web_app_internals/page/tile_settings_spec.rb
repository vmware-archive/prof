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
require 'prof/ops_manager/web_app_internals/page/tile_settings'

RSpec.configure do |config|
  config.include Prof::ExternalSpec::Helpers::Capybara
end

module Prof::OpsManager::WebAppInternals::Page
  describe TileSettings do
    let(:session) { Capybara::Session.new(:poltergeist, app) }
    let(:app) { proc { |_| [200, { 'Content-Type' => 'text/html' }, [sidebar]] } }

    before { session.visit('/edit') }

    describe '#sidebar' do
      let(:sidebar) do
        <<-HTML
        <html><body><ul class="sidebar">
          <li><a href="#config_rabbit_mq">

            Config RabbitMQ
          </a></li>
          <li><a href="#rabbit_mq">

            RabbitMQ
          </a></li>
          <li><a href="#rabbit_mq_policy">

            RabbitMQ Policy
          </a></li>
          <li class="active"><a>

            Other
          </a></li>
        </ul></body></html>
        HTML
      end

      it 'is able to distinguish between titles with similar names' do
        page = TileSettings.new(page: session)
        page = page.sidebar('RabbitMQ')
        expect(page.current_uri.fragment).to eq 'rabbit_mq'

        page = page.sidebar('RabbitMQ Policy')
        expect(page.current_uri.fragment).to eq 'rabbit_mq_policy'

        page = page.sidebar('Config RabbitMQ')
        expect(page.current_uri.fragment).to eq 'config_rabbit_mq'
      end
    end

    describe '#settings_for' do
      let(:sidebar) do
        <<-HTML
        <html><body>
          <ul class="sidebar">
            <li class="active"><a>RabbitMQ</a></li>
          </ul>
          <div class="content">
            #{field}
          </div>
        </body></html>
        HTML
      end

      subject(:settings_for_name) do
        page = TileSettings.new(page: session)
        page.settings_for("RabbitMQ")["name"]
      end

      context 'a Text Area' do
        let(:field) { '<textarea name="name">value</textarea>' }
        it { expect(settings_for_name).to eq 'value' }
      end

      context 'a Text Input' do
        let(:field) { '<input type="text" name="name" value="value"/>' }
        it { expect(settings_for_name).to eq 'value' }
      end

      context 'a Checkbox' do
        let(:field) do
          '<input type="checkbox" name="name" value="checked_value_1" checked />' +
            '<input type="checkbox" name="name" value="checked_value_2" checked="checked" />' +
            '<input type="checkbox" name="name" value="unchecked_value">'
        end
        it { expect(settings_for_name).to match_array %w(checked_value_1 checked_value_2) }

        context 'when nothing is selected' do
          let(:field) { '<input type="checkbox" name="name" value="unchecked_value_1"/>' }
          it { expect(settings_for_name).to be_nil }
        end
      end

      context 'a Radio' do
        let(:field) do
          '<input type="radio" name="name" value="selected_value" selected />' +
            '<input type="radio" name="name" value="unselected_value">'
        end
        it { expect(settings_for_name).to eq 'selected_value' }

        context 'when nothing is selected' do
          let(:field) { '<input type="radio" name="name" value="unselected_value" />' }
          it { expect(settings_for_name).to be_nil }
        end
      end

      context 'a Select' do
        let(:field) do
          <<-HTML
          <select name="name" multiple>
            <option value="value_1">Option 1</option>
            <option selected value="value_2">Option 2</option>
            <option selected value="value_3">Option 3</option>
          </select>
          HTML
        end
        it { expect(settings_for_name).to match_array %w(value_2 value_3) }
      end
    end
  end
end
