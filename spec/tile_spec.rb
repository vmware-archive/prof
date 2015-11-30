# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'prof/tile'

describe Prof::Tile do
  let(:name) { 'NAME' }
  let(:version) { 'VERSION' }

  subject { described_class.new(name: name, version: version) }

  describe '#name' do
    it 'has one' do
      expect(subject.name).to eql(name)
    end
  end

  describe '#version' do
    it 'has one' do
      expect(subject.version).to eql(version)
    end
  end

  describe '#to_s' do
    it 'is the name and version' do
      expect(subject.to_s).to eql("NAME vVERSION")
    end
  end
end
