# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'json'

module Prof
  module ExternalSpec
    module Helpers
      module FileHelper
        def root_path
          defined?(ROOT_PATH) ? ROOT_PATH : Dir.pwd
        end

        def file_path(relative_to_root)
          File.expand_path(relative_to_root, root_path)
        end

        def json_contents(relative_to_root)
          JSON.parse(file_contents(relative_to_root), symbolize_names: true)
        end

        def file_contents(relative_to_root)
          File.read(file_path(relative_to_root))
        end
      end
    end
  end
end
