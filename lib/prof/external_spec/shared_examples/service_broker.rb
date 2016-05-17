# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

shared_examples_for 'a service broker which logs to syslog' do
  it 'logs to syslog' do
    root_prompt = "[sudo] password for vcap:"

    broker_ip = broker_host || environment.service_broker.url.host
    result = ssh_gateway.execute_on(broker_ip, "grep -c #{syslog_tag} /var/log/syslog", root: true)[root_prompt.length..-1]
    nginx_syslog_line_count = Integer(result.strip)
    expect(nginx_syslog_line_count).to be > 0
  end
end

shared_examples_for 'a service broker' do
  let(:syslog_tag) { "Cf#{environment.service_broker_name.capitalize}BrokerNginxAccess" }

  describe 'service broker' do
    it_behaves_like 'a service broker which logs to syslog'
  end
end
