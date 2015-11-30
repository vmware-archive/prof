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
  class EnvironmentManager
    class OpsManagerNotConfigured < StandardError; end

    def initialize(pcf_environment)
      @pcf_environment = pcf_environment
    end

    def isolate_cloud_foundry(&_block)
      cloud_foundry.create_and_target_org(cf_org_name)
      cloud_foundry.create_and_target_space(cf_space_name)
      cloud_foundry.setup_permissive_security_group(cf_org_name, cf_space_name)

      yield

      cloud_foundry.delete_org(cf_org_name)
    end

    def destroy_orphan_tiles
      orphans = orphan_tiles
      return unless orphans.any?

      puts "Removing orphaned tile(s) #{orphans.map(&:name).join(', ')}"
      ops_manager.uninstall_tiles(orphans)
    end

    def destroy_orphan_deployments
      orphans = orphan_deployments
      return unless orphans.any?

      puts "Removing orphaned deployment(s) '#{orphans.join(', ')}'"
      orphans.each do |deployment_name|
        bosh_director.delete_deployment(deployment_name, force: true)
      end
    end

    def uninstall_tiles
      ops_manager.uninstall_tiles(ops_manager.product_tiles)
    end

    def reset
      raise OpsManagerNotConfigured, "Please configure #{ops_manager.url}" unless ops_manager.cf_installed?

      destroy_orphan_tiles
      destroy_orphan_deployments
      uninstall_tiles
    end

    private

    attr_reader :pcf_environment

    def cf_org_name
      @cf_org_name ||= "cf-org-#{SecureRandom.hex(4)}"
    end

    def cf_space_name
      @cf_space_name ||= "cf-space-#{SecureRandom.hex(4)}"
    end

    def cloud_foundry
      pcf_environment.cloud_foundry
    end

    def ops_manager
      pcf_environment.ops_manager
    end

    def orphan_deployments
      tile_guids = pcf_environment.ops_manager.tiles.map(&:guid)
      pcf_environment.bosh_director.deployment_names.reject { |deployment_name| tile_guids.include?(deployment_name) }
    end

    def orphan_tiles
      bosh_deployment_names = pcf_environment.bosh_director.deployment_names
      pcf_environment.ops_manager.product_tiles.reject { |tile| bosh_deployment_names.include?(tile.guid) }
    end

    def bosh_director
      pcf_environment.bosh_director
    end
  end
end
