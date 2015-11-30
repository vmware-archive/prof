# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

shared_examples_for 'upgradable product' do
  it 'persists data across product upgrades' do
    cloud_foundry.push_app_and_bind_with_service(test_app, old_service) do |pushed_app|
      puts 'Inserting test data into instance...'
      pushed_app.write('test_key', 'test_value')
      expect(pushed_app.read('test_key')).to eq('test_value')

      puts "Uploading #{new_product}..."
      ops_manager.upload_product(new_product)

      puts "Upgrading to #{new_product}..."
      ops_manager.upgrade_product(new_product)

      puts "Deploying #{new_product}..."
      ops_manager.apply_changes

      puts 'Retreiving test data from instance...'
      expect(pushed_app.read('test_key')).to eq('test_value')
      puts 'The data survived! :)'
    end
  end
end
