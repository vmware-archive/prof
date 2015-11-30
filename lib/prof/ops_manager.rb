# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'capybara'
require 'opsmanager_client/client'
require 'forwardable'

require 'prof/ops_manager/web_app_internals'
require 'prof/ops_manager/rails_500_error'
require 'prof/tile'
require 'json'

module Prof
  class OpsManager
    extend Forwardable

    def initialize(url:, username:, password:, page: default_capybara_session, log_fetcher: null_log_fetcher)
      @url         = url
      @username    = username
      @password    = password
      @page        = page
      @log_fetcher = log_fetcher
    end

    attr_reader :url

    def_delegators :web_app_internals,
                   :apply_changes

    def_delegators :opsmanager_client,
                   :cc_client_credentials,
                   :cf_admin_credentials,
                   :cf_installed?,
                   :delete_unused_products,
                   :system_domain,
                   :upgrade_product,
                   :vms_for_job_type

    def_delegators :dashboard,
                   :apply_setting,
                   :tile,
                   :tile_configuration,
                   :tile_configure

    # Add ability to get hold of the capybara session
    # while transitioning code over to page objects
    def browser(&_block)
      yield page, url
    end

    def uninstall_tile(*tile_or_tiles)
      tiles = Array(tile_or_tiles).flatten
      return if tiles.empty?

      tiles.each { |t| web_app_internals.tile_uninstall(t) }
      web_app_internals.apply_changes
    end
    alias_method :uninstall_tiles, :uninstall_tile

    def setup_tile(tile)
      puts "Adding #{tile.name}"
      add_tile(tile)

      puts "Installing update"
      apply_changes
    rescue Rails500Error => e
      puts "FAILED: '#{e.message}'\n"
      logs = log_fetcher.fetch_logs('production.log', 500)
      raise Rails500Error, "#{e.message}\n---------------\n#{logs}"
    end

    def add_tile(tile)
      opsmanager_client.add_product(tile)
    end

    def upload_product(product)
      puts "Uploading product #{product.name}"
      opsmanager_client.upload_product(product)
      Tile.new(name: product.name, version: product.version)
    end

    def product_tiles
      tiles.reject{|t| ['cf', 'microbosh', 'p-bosh'].include?(t.name) }
    end

    def tiles
      opsmanager_client.send(:installed_products).map {|tempest_product|
        Tile.new(
          name:    tempest_product.type,
          version: tempest_product.version,
          guid:    tempest_product.guid
        )
      }
    end

    def vms_for_job_type(job_type)
      opsmanager_client.vms_for_job_type(job_type)
    end

    private

    attr_reader :username, :password, :page, :log_fetcher

    def default_capybara_session
      Capybara::Session.new(Capybara.default_driver)
    end

    def web_app_internals
      @web_app_internals ||= WebAppInternals.new(dashboard, opsmanager_client, page, url)
    end

    def opsmanager_client
      @opsmanager_client ||= ::OpsmanagerClient::Client.new(url, username, password)
    end

    def dashboard
      @dashboard ||= login_page.login.tap { page.visit(url) unless page.current_url == url }
    end

    def login_page
      @login_page ||= WebAppInternals::Page::Login.new(page: page, url: url, username: username, password: password)
    end

    def null_log_fetcher
      NullLogFetcher.new
    end

    class NullLogFetcher
      def fetch_logs(_, _)
        return 'No Log fetcher configured.'
      end
    end
  end
end
