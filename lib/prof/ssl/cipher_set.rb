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
    class CipherSet
      def initialize(supported_ciphers: [], supported_protocols: [])
        @supported_ciphers   = supported_ciphers
        @supported_protocols = supported_protocols
      end

      attr_reader :supported_ciphers, :supported_protocols

      # This list is based on the Mozilla Modern cipher list https://wiki.mozilla.org/Security/Server_Side_TLS 2015-02-05
      # we have removed some of the supported ciphers due to the version of openssl used on the stemcel:
      ##'ECDHE-ECDSA-AES128-GCM-SHA256'
      #'ECDHE-ECDSA-AES256-GCM-SHA384'
      #'DHE-DSS-AES128-GCM-SHA256'
      #'kEDH+AESGCM'
      #'ECDHE-ECDSA-AES128-SHA256'
      #'ECDHE-ECDSA-AES128-SHA'
      #'ECDHE-ECDSA-AES256-SHA384'
      #'ECDHE-ECDSA-AES256-SHA'
      #'DHE-DSS-AES128-SHA256'
      #'DHE-DSS-AES256-SHA'
      #
      # It appears the nginx will enable DHE-RSA-AES256-GCM-SHA384 when ECDHE-RSA-AES256-GCM-SHA384 is specified
      # We believe DHE-RSA-AES256-GCM-SHA384 to be strong, but it is not part of the official mozilla modern lists.
      # This has been added to the list of our supported ciphers
      PIVOTAL_MODERN = new(
        supported_ciphers: [
          'ECDHE-RSA-AES128-GCM-SHA256',
          'ECDHE-RSA-AES256-GCM-SHA384',
          'DHE-RSA-AES128-GCM-SHA256',
          'ECDHE-RSA-AES128-SHA256',
          'ECDHE-RSA-AES128-SHA',
          'ECDHE-RSA-AES256-SHA384',
          'ECDHE-RSA-AES256-SHA',
          'DHE-RSA-AES128-SHA256',
          'DHE-RSA-AES128-SHA',
          'DHE-RSA-AES256-SHA256',
          'DHE-RSA-AES256-SHA',
          'DHE-RSA-AES256-GCM-SHA384'
        ],
        supported_protocols: [:TLSv1_2, :TLSv1_1]
      )
    end
  end
end
