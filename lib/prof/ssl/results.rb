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
  module SSL
    class Results
      def initialize(results)
        @results = Array(results).flatten
      end

      def supports_protocol?(protocol)
        results_for_protocol(protocol).any?(&:supported?)
      end

      def supports_cipher_set?(cipher_set)
        expected_ciphers  = cipher_set.supported_ciphers
        expected_protocols = cipher_set.supported_protocols

        # 1. Every cipher in the set must exist in the results
        valid = expected_ciphers.all? { |expected_cipher| supported_ciphers.include? expected_cipher }

        # 2. No Ciphers exists in the results but not the cipher set
        valid &= supported_ciphers.all? { |supported_cipher| expected_ciphers.include? supported_cipher }

        # 3. No protocols in the cipher set that are not supported
        valid &= expected_protocols.all? { |expected_protocol| supported_protocols.include? expected_protocol }

        # 4. No protocols supported that are not in the cipher set
        valid &= supported_protocols.all? { |supported_protocol| expected_protocols.include? supported_protocol }
      end

      def protocols
        results.map(&:protocol).uniq
      end

      def supported_ciphers
        @supported_ciphers ||= supported_results.map(&:cipher).uniq
      end

      def supported_protocols
        @supported_protocols ||= supported_results.map(&:protocol).uniq
      end

      def unsupported_protocols
        protocols - supported_protocols
      end

      private

      attr_reader :results

      def supported_results
        results.select(&:supported?)
      end

      def unsupported_results
        results - supported_results
      end

      def results_for_protocol(protocol)
        results.select do |result|
          result.protocol == protocol
        end
      end
    end
  end
end
