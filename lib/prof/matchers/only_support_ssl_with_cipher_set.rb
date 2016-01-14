# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'ostruct'

require 'prof/ssl/check'
require 'rspec/matchers/english_phrasing'

module Prof
  module Matchers
    def only_support_ssl_with_cipher_set(*args)
      OnlySupportSslWithCipherSet.new(*args)
    end

    # Current problems
    # 1. The OSX openssl library may not support all of the ciphers that need to be tested for a cipher suite
    # 2. Some of the ciphers are actually expressions (kEDH+AESGCM) these need to be expanded to the ciphers they represent

    class OnlySupportSslWithCipherSet

      def initialize(cipher_set)
        @cipher_set = cipher_set
      end

      def matches?(https_url)
        @https_url    = https_url
        @results      = ssl_results
        @http_enabled = http_connection_accepted?
        results.supports_cipher_set?(cipher_set) && !@http_enabled
      end

      def with_proxy(proxy)
        @proxy = proxy
        self
      end

      def failure_message
        [
          ("The server is missing support for#{RSpec::Matchers::EnglishPhrasing.list(server_missing_supported_ciphers)}" if server_missing_supported_ciphers.any?),
          ("The server supports#{RSpec::Matchers::EnglishPhrasing.list(server_extra_ciphers)} when it should not" if server_extra_ciphers.any?),
          ("The server is missing support for#{RSpec::Matchers::EnglishPhrasing.list(server_missing_supported_protocols)}" if server_missing_supported_protocols.any?),
           ("The server supports#{RSpec::Matchers::EnglishPhrasing.list(server_extra_protocols)} when it should not" if server_extra_protocols.any?),
          ("The server supports HTTP when it should not" if http_enabled)
        ].compact.join("\n")
      end

      private

      attr_reader :cipher_set, :results, :https_url, :http_enabled

      def proxy
        @proxy ||= OpenStruct.new(:http_host => nil, :http_address => nil)
      end

      def server_missing_supported_ciphers
        cipher_set.supported_ciphers - results.supported_ciphers
      end

      def server_extra_ciphers
        results.supported_ciphers - cipher_set.supported_ciphers
      end

      def server_missing_supported_protocols
        cipher_set.supported_protocols - results.supported_protocols
      end

      def server_extra_protocols
        results.supported_protocols - cipher_set.supported_protocols
      end

      def http_connection_accepted?
        begin
          response = Net::HTTP.new(http_uri.host, http_uri.port, proxy.http_host, proxy.http_port).get('/')
          !response.instance_of?(Net::HTTPGatewayTimeOut)
        rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
          false
        end
      end

      def http_uri
        http_uri = URI(https_url)
        http_uri.scheme = 'http'
        http_uri.port = 80
        http_uri
      end

      def ssl_results
        Prof::SSL::Check.new(https_url, @proxy).results
      end
    end
  end
end
