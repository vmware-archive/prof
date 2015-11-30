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
require 'prof/ssl/results'
require 'prof/ssl/result'
require 'prof/ssl/cipher_set'
require 'prof/matchers/only_support_ssl_with_cipher_set'

RSpec.describe 'Matcher only support SSL cipher set' do
  describe '#only_support_ssl_with_cipher_set' do
    let(:checker) { instance_double(Prof::SSL::Check) }
    let(:url) { 'https://foobar.com' }
    let(:http_url) { 'http://foobar.com' }

    let(:results) {
      Prof::SSL::Results.new([
        Prof::SSL::Result.new('TLSv1',   'UBER',  false),
        Prof::SSL::Result.new('TLSv1_1', 'UBER',  true),
        Prof::SSL::Result.new('TLSv1_2', 'UBER',  true),
        Prof::SSL::Result.new('TLSv1',   'UNTER', false),
        Prof::SSL::Result.new('TLSv1_1', 'UNTER', false),
        Prof::SSL::Result.new('TLSv1_2', 'UNTER', false)
      ])
    }

    let(:cipher_set) {
      Prof::SSL::CipherSet.new(
        supported_ciphers: ['UBER'],
        supported_protocols: %w(TLSv1_2 TLSv1_1)
      )
    }

    before do
      allow(Prof::SSL::Check).to receive(:new).and_return(checker)
      allow(checker).to receive(:results).and_return(results)

      stub_request(:get, http_url).to_raise(Errno::ECONNREFUSED.new('Connection refused - connect(2) for "foobar.com" port 80'))
    end

    it 'matches' do
      expect(url).to only_support_ssl_with_cipher_set(cipher_set)
    end

    context 'when proxy is used' do
       let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['SHA', 'MD5'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        Prof::SSL::Results.new([
          Prof::SSL::Result.new('TLSv1_2', 'SHA', true),
          Prof::SSL::Result.new('TLSv1_1', 'MD5', true),
          Prof::SSL::Result.new('TLSv1',   'ASE256', false)
        ])
      end

      let(:proxy) { double('proxy') }
      let(:proxy_host) { "proxy_host" }
      let(:proxy_port) { "8023"}

      before do
        allow(proxy).to receive(:http_host).and_return(proxy_host)
        allow(proxy).to receive(:http_port).and_return(proxy_port)
      end

      it 'http request should be performed' do
        expect(proxy).to receive(:http_host).and_return(proxy_host)
        expect(proxy).to receive(:http_port).and_return(proxy_port)

        expect(url).to only_support_ssl_with_cipher_set(cipher_set).with_proxy(proxy)
      end

      it 'does not report http enabled when there is an HTTPGatewayTimeOut' do
        request = double('request')
        allow(Net::HTTP).to receive(:new).and_return(request)
        allow(request).to receive(:get).and_return(Net::HTTPGatewayTimeOut.new(nil, nil, nil))

        expect(url).to only_support_ssl_with_cipher_set(cipher_set).with_proxy(proxy)
      end
    end

    context 'when results support a subset of the ciphers and protocols' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER', 'UNTER'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        Prof::SSL::Results.new([
          Prof::SSL::Result.new('TLSv1_2', 'UNTER', true),
          Prof::SSL::Result.new('TLSv1_1', 'UBER', true),
          Prof::SSL::Result.new('TLSv1',   'UBER', false)
        ])
      end

      it 'matches' do
        expect(url).to only_support_ssl_with_cipher_set(cipher_set)
      end
    end

    context 'when no results are returned' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) { Prof::SSL::Results.new([]) }

      it 'raises error' do
        expect { expect(url).to only_support_ssl_with_cipher_set(cipher_set) }.to(
          raise_error /The server is missing support for "UBER"/
        )
      end
    end

    context 'when results test a subset of the ciphers and protocols but some are not supported' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        Prof::SSL::Results.new([
          Prof::SSL::Result.new('TLSv1_2', 'UBER', false),
          Prof::SSL::Result.new('TLSv1_1', 'UBER', true),
          Prof::SSL::Result.new('TLSv1',   'UBER', false)
        ])
      end

      it 'raises error' do
        expect { expect(url).to only_support_ssl_with_cipher_set(cipher_set) }.to(
          raise_error /The server is missing support for "TLSv1_2"/
        )
      end
    end

    context 'when results include ciphers or protocols not specified in cipher set' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        Prof::SSL::Results.new([
          Prof::SSL::Result.new('TLSv1_2', 'UNTER', true),

          Prof::SSL::Result.new('TLSv1_2', 'UBER', true),
          Prof::SSL::Result.new('TLSv1_1', 'UBER', true),
          Prof::SSL::Result.new('TLSv1',   'UBER', false)
        ])
      end

      it 'raises error' do
        expect { expect(url).to only_support_ssl_with_cipher_set(cipher_set) }.to(
          raise_error /The server supports "UNTER" when it should not/
        )
      end
    end

    context 'when http port is open' do
      before do
        stub_request(:get, http_url)
      end

      it 'raises error' do
        expect {
          expect(url).to only_support_ssl_with_cipher_set(cipher_set)
        }.to(raise_error /The server supports HTTP when it should not/)
      end
    end
  end
end
