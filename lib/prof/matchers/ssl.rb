# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/ssl/check'

require 'rspec/expectations'

RSpec::Matchers.define :support_ssl_protocol do |expected|
  match do |url|
    actual = Prof::SSL::Check.new(url, @proxy).results.supported_protocols
    actual.include?(expected)
  end

  chain :with_proxy do |proxy|
    @proxy = proxy
  end
end

RSpec::Matchers.define :support_ssl_protocols do |expected|
  match do |url|
    @results = ssl_results(url)

    expected.all? do |protocol, is_supported|
      @results.supported_protocols.include?(protocol) == is_supported
    end
  end

  chain :with_proxy do |proxy|
    @proxy = proxy
  end

  failure_message do |_|
    unexpectedly_supported   = expected.reject { |_, supported| supported }.keys & @results.supported_protocols
    unexpectedly_unsupported = expected.select { |_, supported| supported }.keys & @results.unsupported_protocols

    "expected SSL support: #{expected.inspect}, but" + to_sentence(
      [("#{unexpectedly_supported} unexpectedly supported" if unexpectedly_supported.any?),
       ("#{unexpectedly_unsupported} unexpectedly unsupported" if unexpectedly_unsupported.any?)].compact
    )
  end

  private

  attr_reader :ssh_gateway

  def ssl_results(url)
    if ssh_gateway
      uri = URI.parse(url)
      ssh_gateway.with_port_forwarded_to(uri.host, uri.port) do |forwarded_port|
        ssl_check_url("https://localhost:#{forwarded_port}")
      end
    else
      ssl_check_url(url)
    end
  end

  def ssl_check_url(url)
    Prof::SSL::Check.new(url, @proxy).results
  end
end
