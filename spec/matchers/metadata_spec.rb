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
require 'prof/matchers/metadata'

# expect(manifest).to have_metadata_version

RSpec.describe "Metadata Matchers" do

  subject(:manifest) do
    {
      'metadata_version' => '1.3',
      'job_types' => [
        { 'name' => 'dontcare' },
        {
          'name' => 'cassandra_agent',
          'resource_definitions' => [
            {
              'name' => 'ram',
              'constraints' => {
                'min' => 1_024
              }
            },
          ],
          'instance_definitions' => [
            {
              'name' => 'instances',
              'label' => 'Instances',
              'constraints' => {
                'min' => 3
              },
              'default' => 3
            }
          ],
          'job_templates' => [
            'template1',
            'template2'
          ]
        }
      ]
    }
  end

  describe '#have_metadata_version' do
    it "matches when the version is the same" do
      expect(manifest).to have_metadata_version('1.3')
    end

    it "doesn't match when the version is not the same" do
      expect {
        expect(manifest).to have_metadata_version('1.4')
      }.to raise_error(/Metadata version does not match. Expected version 1.4, actual version was 1.3/)
    end
  end

  describe '#has_job_type matcher' do
    it 'finds a valid job type' do
      expect(manifest).to have_job_type('cassandra_agent')
    end

    it "doesn't find an invalid job type" do
      expect {
        expect(manifest).to have_job_type('cassandra_agent_do_not_exist')
      }.to raise_error(/Could not find job type: cassandra_agent_do_not_exist in metadata/)
    end

    describe "#with_template" do
      it "matches when the template is present" do
        expect(manifest).to have_job_type('cassandra_agent').with_template('template1')
      end

      it "doesn't match when the template is not present" do
        expect {
          expect(manifest).to have_job_type('cassandra_agent').with_template('invalid_template')
        }.to raise_error(/Could not find template 'invalid_template' for job cassandra_agent in metadata/)
      end
    end

    describe '#with_constraint' do
      it 'fails when used alone' do
        expect {
          expect(manifest).to have_job_type('cassandra_agent').with_constraint(:min, 3)
        }.to raise_error(/Can not use `with_contraint` without `with_instance_definition` or `with_resource_definition`/)
      end
    end

    describe '#with_attribute_value' do
      it 'fails when used alone' do
        expect {
          expect(manifest).to have_job_type('cassandra_agent').with_attribute_value(:label, "Instances")
        }.to raise_error(/Can not use `with_attribute_value` without `with_instance_definition` or `with_resource_definition`/)
      end
    end

    describe '#with_default' do
      it 'fails when used alone' do
        expect {
          expect(manifest).to have_job_type('cassandra_agent').with_default(3)
        }.to raise_error(/Can not use `with_default` without `with_instance_definition` or `with_resource_definition`/)
      end
    end

    describe '#with_instance_definition' do

      context 'when instance definition exists' do

        it 'matches when instance definition exists' do
          expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances')
        end

        describe '#with_constraint' do

          context 'constraint exists' do
            it 'matches when the value is correct' do
              expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_constraint(:min, 3)
            end

            it 'fails to match when the value is incorrect' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_constraint(:min, 5)
              }.to raise_error(/Expected constraint min value to be 5 but it was 3 for definition instances in job type: cassandra_agent/)

            end
          end

          context "constraint doesn't exist" do
            it 'fails to match for an instance definition that does not have the constraint' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_constraint(:donotexist, 5)
              }.to raise_error(/Could not find constraint donotexist for definition instances in job type: cassandra_agent/)
            end
          end
        end

        describe '#with_default' do

          context 'default exists' do
            it 'matches when the value is correct' do
              expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_default(3)
            end

            it 'fails to match when the value is incorrect' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_default(5)
              }.to raise_error(/Expected attribute default value to be 5 but it was 3 for definition instances in job type: cassandra_agent/)
            end
          end

          context "default doesn't exist" do
            it 'fails to match for an instance definition that does not have the default' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_resource_definition('ram').with_default(5)
              }.to raise_error(/Could not find attribute default for definition ram in job type: cassandra_agent/)
            end
          end
        end

        describe '#with_attribute_value' do

          context 'attribute exists' do
            it 'matches when the value is correct' do
              expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_attribute_value(:label, "Instances")
            end

            it 'fails to match when the value is incorrect' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_attribute_value(:label, "This is not really a label")
              }.to raise_error(/Expected attribute label value to be This is not really a label but it was Instances for definition instances in job type: cassandra_agent/)
            end
          end

          context "attribute doesn't exist" do
            it 'fails to match for an attribute that does not exist' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('instances').with_attribute_value(:nonexistentattribute, "nonexistent")
              }.to raise_error(/Could not find attribute nonexistentattribute for definition instances in job type: cassandra_agent/)
            end
          end
        end
      end

      context "when instance definition doesn't exist" do
        it 'fails to match' do
          expect {
            expect(manifest).to have_job_type('cassandra_agent').with_instance_definition('invalid_instance_definition')
          }.to raise_error(/Could not find instance type: invalid_instance_definition for job type: cassandra_agent/)
        end

      end
    end

    describe '#with_resource_definition' do

      context 'when resource definition exists' do

        it 'matches' do
          expect(manifest).to have_job_type('cassandra_agent').with_resource_definition('ram')
        end

        describe '#with_constraint' do

          context 'constraint exists' do
            it 'matches when the value is correct' do
              expect(manifest).to have_job_type('cassandra_agent').with_resource_definition('ram').with_constraint(:min, 1_024)
            end

            it 'fails to match when the value is incorrect' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_resource_definition('ram').with_constraint(:min, 5)
              }.to raise_error(/Expected constraint min value to be 5 but it was 1024 for definition ram in job type: cassandra_agent/)

            end
          end

          context "constraint doesn't exist" do
            it 'fails to match for an resource definition that does not have the constraint' do
              expect {
                expect(manifest).to have_job_type('cassandra_agent').with_resource_definition('ram').with_constraint(:donotexist, 5)
              }.to raise_error(/Could not find constraint donotexist for definition ram in job type: cassandra_agent/)
            end
          end
        end

      end

      context "when resource definition doesn't exist" do
        it 'fails to match' do
          expect {
            expect(manifest).to have_job_type('cassandra_agent').with_resource_definition('invalid_resource_definition')
          }.to raise_error(/Could not find resource type: invalid_resource_definition for job type: cassandra_agent/)
        end
      end
    end
  end
end
