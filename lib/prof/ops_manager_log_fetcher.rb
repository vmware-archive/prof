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
  class OpsManagerLogFetcher
    def initialize(ssh_gateway:, host:, username:, password:)
      @ssh_gateway = ssh_gateway
      @host        = host
      @username    = username
      @password    = password
    end

    def fetch_logs(log_name, lines_from_tail = 0)
      read_command = lines_from_tail > 0 ? "tail -n #{lines_from_tail}" : 'cat'
      command = "#{read_command} /tmp/logs/#{log_name}"
      ssh_gateway.execute_on(host, command, user: username, password: password)
    end

    private

    attr_reader :ssh_gateway, :host, :username, :password
  end
end
