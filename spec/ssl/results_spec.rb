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
require 'prof/ssl/cipher_set'
require 'prof/ssl/results'
require 'prof/ssl/result'

describe Prof::SSL::Results do

  subject(:ssl_results) { described_class.new(results) }

  describe '#supports_protocol?' do

    let(:results) do
      [
        Prof::SSL::Result.new('TLSv1', 'ABC', true),
        Prof::SSL::Result.new('TLSv1', 'DEF', false),
        Prof::SSL::Result.new('SSLv3', 'ABC', false),
        Prof::SSL::Result.new('SSLv3', 'DEF', false)
      ]
    end

    context 'when it does not support a version' do
      it 'returns false' do
        expect(ssl_results.supports_protocol?('SSLv3')).to be(false)
      end
    end

    context 'when it does support a version' do
      it 'returns true' do
        expect(ssl_results.supports_protocol?('TLSv1')).to be(true)
      end
    end

    context 'when it has not tested that version' do
      it 'returns false' do
        expect(ssl_results.supports_protocol?('FOOBAR')).to be(false)
      end
    end
  end

  describe '#supports_cipher_set?' do
    context 'when results only include all of the ciphers and protocols' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        [
          Prof::SSL::Result.new('TLSv1_2', 'UBER', true),
          Prof::SSL::Result.new('TLSv1_1', 'UBER', true),
          Prof::SSL::Result.new('TLSv1',   'UBER', false),

          Prof::SSL::Result.new('TLSv1_2', 'UNTER', false)
        ]
      end

      it 'returns true' do
        expect(ssl_results.supports_cipher_set?(cipher_set)).to be(true)
      end
    end

    context 'when a cipher is supported only in one of the protocols' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER', 'UBERX4'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        [
          Prof::SSL::Result.new('TLSv1_1', 'UBERX4', true),
          Prof::SSL::Result.new('TLSv1_2', 'UBER', true),
          Prof::SSL::Result.new('TLSv1_1', 'UBER', false), # UBER is not supported for TLSv1_1
          Prof::SSL::Result.new('TLSv1',   'UBER', false)
        ]
      end

      it 'returns true' do
        expect(ssl_results.supports_cipher_set?(cipher_set)).to be(true)
      end
    end

    context 'when no results are returned' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) { [] }

      it 'returns false' do
        expect(ssl_results.supports_cipher_set?(cipher_set)).to be(false)
      end
    end

    context 'when results test a subset of the ciphers and protocols but some are not supported' do
      let(:cipher_set) {
        Prof::SSL::CipherSet.new(
          supported_ciphers: ['UBER', 'UBERX4'],
          supported_protocols: %w(TLSv1_2 TLSv1_1)
        )
      }

      let(:results) do
        [
          Prof::SSL::Result.new('TLSv1_2', 'UBERX4', false),
          Prof::SSL::Result.new('TLSv1_1', 'UBERX4', false),
          Prof::SSL::Result.new('TLSv1',   'UBERX4', false),
          Prof::SSL::Result.new('TLSv1_2', 'UBER',   true),
          Prof::SSL::Result.new('TLSv1_1', 'UBER',   true),
          Prof::SSL::Result.new('TLSv1',   'UBER',   false)
        ]
      end

      it 'returns false' do
        expect(ssl_results.supports_cipher_set?(cipher_set)).to be(false)
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
        [
          Prof::SSL::Result.new('TLSv1_2', 'UNTER', true),

          Prof::SSL::Result.new('TLSv1_2', 'UBER', true),
          Prof::SSL::Result.new('TLSv1_1', 'UBER', true),
          Prof::SSL::Result.new('TLSv1',   'UBER', false)
        ]
      end

      it 'returns false' do
        expect(ssl_results.supports_cipher_set?(cipher_set)).to be(false)
      end
    end
  end

  describe '#protocol' do
    let(:results) do
      [
        Prof::SSL::Result.new('v1', '_', true),
        Prof::SSL::Result.new('v1', '_', false),
        Prof::SSL::Result.new('v2', '_', false),
        Prof::SSL::Result.new('v3', '_', false)
      ]
    end

    it 'returns unique protocol' do
      expect(ssl_results.protocols).to eql(%w(v1 v2 v3))
    end
  end

  describe '#supported_protocol' do
    let(:results) do
      [
        Prof::SSL::Result.new('v1', '_', true),
        Prof::SSL::Result.new('v1', '_', false),
        Prof::SSL::Result.new('v2', '_', true),
        Prof::SSL::Result.new('v3', '_', false)
      ]
    end

    it 'retuns an array containing only supported protocol' do
      expect(ssl_results.supported_protocols).to eq(%w(v1 v2))
    end
  end

  describe '#unsupported_protocol' do
    let(:results) do
      [
        Prof::SSL::Result.new('v1', '_', true),
        Prof::SSL::Result.new('v1', '_', false),
        Prof::SSL::Result.new('v2', '_', true),
        Prof::SSL::Result.new('v3', '_', false)
      ]
    end

    it 'returns an array containing only supported protocol' do
      expect(ssl_results.unsupported_protocols).to eq(['v3'])
    end
  end

end
