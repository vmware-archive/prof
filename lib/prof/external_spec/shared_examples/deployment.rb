# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

shared_examples_for 'a deployment which allows log access via bosh' do
  it 'allows log access via bosh' do
    log_files_by_job.each_pair do |job_name, log_files|
      expect(bosh_director.job_logfiles(job_name)).to include(*log_files)
    end
  end
end

shared_examples_for 'a deployment' do
  describe 'deployment' do
    it_behaves_like 'a deployment which allows log access via bosh'
  end
end
