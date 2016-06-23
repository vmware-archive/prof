# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'spec_helper'
require 'prof/ssl/check'

RSpec.describe Prof::SSL::Check do
  describe '#check' do
    let(:url) { 'https://foobar.com:8443/' }
    let(:http) { instance_double(Net::HTTP) }
    let(:proxy) { double('proxy') }
    let(:proxy_host) { 'proxy_host' }
    let(:proxy_port) { 12345 }

    subject(:check) { described_class.new(url, proxy) }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:get)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:verify_mode=)
      allow(http).to receive(:ssl_version=)
      allow(http).to receive(:ciphers=)

      allow(proxy).to receive(:http_host).and_return(proxy_host)
      allow(proxy).to receive(:http_port).and_return(proxy_port)
    end

    describe '#results' do
      context 'when a proxy is provided' do
        it 'uses the correct host and port, and the proxy' do
          expect(Net::HTTP).to receive(:new).with('foobar.com', 8443, proxy_host, proxy_port)

          check.results
        end
      end

      context 'when no proxy is provided' do
        subject(:check) { described_class.new(url) }

        it 'uses the correct host and port' do
          expect(Net::HTTP).to receive(:new).with('foobar.com', 8443, nil, nil)

          check.results
        end
      end

      it 'sets no verify as we are checking protocols not certificates' do
        expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_NONE).at_least(:once)

        check.results
      end

      it 'sets use ssl' do
        expect(http).to receive(:use_ssl=).with(true).at_least(:once)

        check.results
      end

      it 'cycles through the ciphers for each ssl version' do
        check.protocols.each do |protocol|
          ciphers = OpenSSL::SSL::SSLContext.new(protocol).ciphers.map(&:first)
          ciphers.each do |cipher|
            expect(http).to receive(:ssl_version=).with(protocol)
            expect(http).to receive(:ciphers=).with(cipher)
          end
        end

        check.results
      end

      context 'when ssl errors are raised' do
        before do
          allow(http).to receive(:get){
            raise OpenSSL::SSL::SSLError
          }
        end

        it 'returns failures' do
          results = check.results
          expect(results.supported_protocols).to eql([])
        end
      end

      context 'when a request is succesful' do
        it 'returns successes' do
          results = check.results
          expect(results.supported_protocols).to eql(results.protocols)
        end

        it 'returns the correct supported versions' do
          expect(check.results.supported_protocols).to eql(subject.protocols)
        end
      end
    end

    describe '#protocols' do

      let(:protocols) { check.protocols }

      it 'does not return any server versions' do
        expect(protocols).to_not include { |n| n =~ /_server/ }
      end

      it 'does not return any client versions' do
        expect(protocols).to_not include { |n| n =~ /_client/ }
      end

      it 'returns tlsv1' do
        expect(protocols).to include(:TLSv1)
      end

      it 'returns sslv3' do
        expect(protocols).to include(:SSLv23)
      end
    end
  end
end
