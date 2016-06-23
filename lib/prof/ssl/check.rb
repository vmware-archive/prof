# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ssl/result'
require 'prof/ssl/results'

require 'uri'
require 'net/http'
require 'openssl'
require 'ostruct'

module Prof
  module SSL
    class Check
      def initialize(url, proxy=nil)
        @url = URI.parse(url)
        @proxy = proxy || OpenStruct.new(:http_host => nil, :http_address => nil)
      end

      def results
        Results.new(protocols.map { |protocol| check_protocol(protocol) })
      end

      def protocols
        @protocols ||= OpenSSL::SSL::SSLContext::METHODS.reject { |m|
          /_(client|server)$/ =~ m.to_s
        }.reject { |m|
          m == :SSLv2 || m == :SSLv3
        }
      end

      private

      attr_reader :url, :proxy

      def port
        url.port
      end

      def host
        url.host
      end

      def check_protocol(protocol)
        cipher_names(protocol).map { |cipher_name| check_cipher(protocol, cipher_name) }
      end

      def cipher_names(protocol)
        OpenSSL::SSL::SSLContext.new(protocol).ciphers.map(&:first)
      end

      def check_cipher(protocol, cipher_name)
        request = http_request
        request.ssl_version = protocol
        request.ciphers = cipher_name
        begin
          request.get('/')
          Result.new(protocol, cipher_name, true)
        rescue OpenSSL::SSL::SSLError, Errno::ECONNRESET
          Result.new(protocol, cipher_name, false)
        end
      end

      def http_request
        request = Net::HTTP.new(host, port, proxy.http_host, proxy.http_port)
        request.use_ssl = true
        request.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request
      end
    end
  end
end
