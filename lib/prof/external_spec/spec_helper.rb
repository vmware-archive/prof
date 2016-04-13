# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'opsmgr/ui_helpers/config_helper'
require 'prof/external_spec/helpers/capybara'
require 'prof/external_spec/helpers/file_helper'
require 'prof/external_spec/helpers/product_path'

require 'rspec_junit_formatter'
require 'capybara/webkit'
require 'opsmgr/log'
require 'pry'

Opsmgr::Log.stdout_mode!

RSpec.configure do |config|
  config.formatter = :documentation
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.include Prof::ExternalSpec::Helpers::Capybara
  config.include Prof::ExternalSpec::Helpers::FileHelper
  config.include Prof::ExternalSpec::Helpers::ProductPath

  config.add_formatter RSpecJUnitFormatter, 'rspec.xml'

  config.full_backtrace = true
  config.fail_fast = false

  config.before(:all) do
    setup_browser(:webkit)
  end
end
