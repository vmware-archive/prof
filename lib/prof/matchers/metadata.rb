# Copyright (c) 2014-2015 Pivotal Software, Inc.
# All rights reserved.
# THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
#

RSpec::Matchers.define :have_metadata_version do |version|
  actual_version = 'NOT_SET'
  match do |actual|
    actual_version = actual['metadata_version']
    actual_version == version.to_s
  end

  failure_message do
    "Metadata version does not match. Expected version #{version}, actual version was #{actual_version}"
  end
end

RSpec::Matchers.define :have_job_type do |job_name|
  error_message = ''
  match do |actual|
    begin
      metadata = MetadataWrapper.new(actual)

      job = metadata.job(job_name: job_name)
      return !!job unless @instance_name || @resource_name || @template_name

      return job.has_template?(template_name: @template_name) if @template_name

      definition = @instance_name ? job.instance_definition(definition_name: @instance_name) : job.resource_definition(definition_name: @resource_name)
      return !! definition unless @attribute || @constraint

      return definition.has_attribute_with_value?(@attribute, @value) if @attribute

      definition.has_constraint_with_value?(@constraint, @value)
    rescue MetadataError => error
      error_message = error.message
      false
    end
  end

  chain :with_template do |template_name|
    @template_name = template_name.to_s
  end

  chain :with_instance_definition do |instance_name|
    @instance_name = instance_name.to_s
  end

  chain :with_resource_definition do |resource_name|
    @resource_name = resource_name.to_s
  end

  chain :with_constraint do |constraint, value|
    raise MetadataError.new("Can not use `with_contraint` without `with_instance_definition` or `with_resource_definition`") unless @resource_name || @instance_name
    @constraint = constraint.to_s
    @value = value
  end

  chain :with_attribute_value do |attribute, value|
    raise MetadataError.new("Can not use `with_attribute_value` without `with_instance_definition` or `with_resource_definition`") unless @resource_name || @instance_name
    @attribute = attribute.to_s
    @value = value
  end

  chain :with_default do |value|
    raise MetadataError.new("Can not use `with_default` without `with_instance_definition` or `with_resource_definition`") unless @resource_name || @instance_name
    @attribute = 'default'
    @value = value
  end

  failure_message do
    error_message
  end

  class MetadataError < StandardError; end

  class MetadataWrapper
    def initialize(metadata)
      @metadata = metadata
    end

    def job(job_name:)
      job = jobs.find { |j| j['name'] == job_name.to_s }.tap do |j|
        raise MetadataError.new("Could not find job type: #{job_name} in metadata") unless j
      end

      MetadataJob.new(job)
    end

    private

    attr_reader :metadata

    def jobs
      metadata['job_types']
    end
  end

  class MetadataJob
    def initialize(job)
      @job = job
    end

    def has_template?(template_name:)
      job['job_templates'].include?(template_name).tap do |result|
        raise MetadataError.new("Could not find template '#{template_name}' for job #{job_name} in metadata") unless result
      end
    end

    def instance_definition(definition_name:)
      instance_definition = instance_definitions.find { |definition| definition['name'] == definition_name }.tap do |instance|
        raise MetadataError.new("Could not find instance type: #{definition_name} for job type: #{job_name}") unless instance
      end
      MetadataDefinition.new(instance_definition, job_name)
    end

    def resource_definition(definition_name:)
      resource_definition = resource_definitions.find { |definition| definition['name'] == definition_name }.tap do |resource|
        raise MetadataError.new("Could not find resource type: #{definition_name} for job type: #{job_name}") unless resource
      end
      MetadataDefinition.new(resource_definition, job_name)
    end

    private

    attr_reader :job

    def job_name
      job['name']
    end

    def instance_definitions
      job['instance_definitions']
    end

    def resource_definitions
      job['resource_definitions']
    end

  end

  class MetadataDefinition
    def initialize(definition, job_name)
      @job_name = job_name
      @definition = definition
    end

    def has_attribute_with_value?(attribute, value)
      actual_value = definition.fetch(attribute) do
        raise MetadataError.new("Could not find attribute #{attribute} for definition #{definition_name} in job type: #{job_name}")
      end

      return true if actual_value == value
      raise MetadataError.new("Expected attribute #{attribute} value to be #{value} but it was #{actual_value} for definition #{definition_name} in job type: #{job_name}")
    end

    def has_constraint_with_value?(constraint, value)
      actual_value = definition['constraints'].fetch(constraint) do
        raise MetadataError.new("Could not find constraint #{constraint} for definition #{definition_name} in job type: #{job_name}")
      end

      return true if actual_value == value
      raise MetadataError.new("Expected constraint #{constraint} value to be #{value} but it was #{actual_value} for definition #{definition_name} in job type: #{job_name}")
    end

    private

    attr_reader :definition, :job_name

    def definition_name
      definition['name']
    end
  end

end
