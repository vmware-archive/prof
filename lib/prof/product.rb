# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'yaml'
require 'zip'

module Prof
  class Product
    class InvalidProductPathError < StandardError; end

    attr_reader :path

    def initialize(path:)
      raise InvalidProductPathError, "Invalid path given: '#{path}'" unless path && File.exist?(path)
      @path = File.expand_path(path)
    end

    def name
      metadata.fetch('name')
    end

    def version
      metadata.fetch('product_version')
    end

    def to_s
      "#{name} v#{version}"
    end

    def file
      File.open(path)
    end

    def ==(other)
      self.class == other.class &&
      self.path == other.path
    end
    alias_method :eql?, :==

    private

    def metadata
      @metadata ||= begin
        yaml = Zip::File.open(path) do |zip_file|
          entry = zip_file.glob('metadata/*').first
          entry.get_input_stream.read
        end
        YAML.load(yaml)
      end
    end
  end
end
