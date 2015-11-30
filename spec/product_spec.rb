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
require 'prof/product'

describe Prof::Product do

  let(:path) { 'spec/assets/file.pivotal' }

  subject(:product) { described_class.new(path: path) }

  describe 'name' do
    let(:path) { 'spec/assets/product.pivotal' }

    it 'reads it from the metadata because that is the source of truth' do
      expect(product.name).to eq('p-foo')
    end
  end

  describe 'version' do
    let(:path) { 'spec/assets/product.pivotal' }

    it 'reads it from the metadata because that is the source of truth' do
      expect(product.version).to eq('1.2.3.4.alpha.1.aaaaaa')
    end
  end

  describe 'to_s' do
    let(:path) { 'spec/assets/product.pivotal' }

    it 'reads it from the metadata because that is the source of truth' do
      expect(product.to_s).to eq('p-foo v1.2.3.4.alpha.1.aaaaaa')
    end
  end

  describe '== & eql?' do

    it 'is a value object' do
      second = described_class.new(path: path)
      third  = described_class.new(path: 'spec/assets/different_file.pivotal')

      expect(subject).to eq(second)
      expect(subject).to eql(second)
      expect(subject).to_not equal(second)

      expect(subject).to_not eq(third)
      expect(subject).to_not eql(third)
      expect(subject).to_not equal(third)
    end

    it 'does not equal products with different absolute paths' do
      one = nil
      two = nil

      Dir.chdir('spec/assets')                     { one = described_class.new(path: 'file.pivotal') }
      Dir.chdir('spec/assets/different_directory') { two = described_class.new(path: 'file.pivotal') }

      expect(one).to_not eq(two)
      expect(one).to_not eql(two)
      expect(one).to_not equal(two)
    end

    context 'when path is nil' do
      let(:path) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(Prof::Product::InvalidProductPathError)
      end
    end

    context 'when the product does not exist' do
      let(:path) { 'spec/assets/missing.pivotal' }

      it 'raises an error' do
        expect { subject }.to raise_error(Prof::Product::InvalidProductPathError)
      end
    end
  end
end
