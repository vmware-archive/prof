# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'rspec/expectations'

RSpec::Matchers.define :have_configuration_fields_on do |tile|
  match do |_ops_manager|
    @tile = tile
    (expected_field_names - actual_field_names).empty?
  end

  chain :including do |*fields|
    @expected_field_names = fields
  end

  failure_message do |_actual|
    [
      'expected:',
      "\t#{expected_field_names.inspect}",
      'to be present in:',
      "\t#{actual_field_names}",
      'but these were not found',
      "\t#{(expected_field_names - actual_field_names).inspect}"
    ].join("\n")
  end

  def expected_field_names
    raise 'Please set including' if @expected_field_names.nil?

    @expected_field_names
  end

  def actual_config
    @actual_config ||= ops_manager.tile_configuration(@tile)
  end

  def actual_field_names
    actual_config.map { |_header, fields| fields.keys }.flatten
  end
end
