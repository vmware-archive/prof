# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'faraday'
require 'faraday_middleware'

module Prof
  class PushedTestApp
    def initialize(opts = {})
      @name = opts.fetch(:name)
      @url  = opts.fetch(:url)
    end

    attr_reader :name, :url

    def write(key, value)
      app_connection.put("/testdata/key/#{key}/value/#{value}")
    end

    def read(key)
      app_connection.get("/testdata/key/#{key}").body
    end

    private

    def app_connection
      Faraday.new(url: url, ssl: { verify: false }) do |faraday|
        faraday.response :json, content_type: /\bjson$/
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
