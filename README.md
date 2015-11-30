# Próf

A gem to test Cloud Foundry service brokers

*NOT FOR GENERAL USE, YET.*

## Installation

Simply add Próf to your Gemfile.

## Testing BOSH deployed service brokers

You must set the following environment variables, most of them should be self explanatory:

* `PROF_CF_DOMAIN` - The domain used to push test apps to CF.
* `PROF_CF_URL`
* `PROF_CF_USERNAME`
* `PROF_CF_PASSWORD`
* `BOSH_TARGET`
* `BOSH_USERNAME`
* `BOSH_PASSWORD`
* `PROF_TEST_APP_PATH` - The path to a CF compatible test app on disk
* `BOSH_MANIFEST` - The path to a manifest for the BOSH deployment of the broker under test
* `PROF_CONFIG_FILE_PATH` - The path to a JSON config file on disk, see below for details

Then, simply run `bundle exec prof_test_release`.

### JSON Config

This is the required structure of the file:

```json
{
    "service_broker": {
        "name": "<Service broker name>",
        "label": "<Service broker label>",
        "job_name": "<Service broker BOSH job name>",
		"log_files_by_job": {
			"<BOSH job name>": [
				"<expected log file name>"
			]
		}
    },
    "service_instance": {
        "plan": "<The name of a service plan provided by your broker>"
    },
    "test_app": {
        "name": "<First test app instance name>",
        "alt_name": "<Second test app instance name>"
    }
}
```

## Testing Cloud Foundry Service Broker BOSH Releases

This is typically executed inside system test scripts.

```$ bundle exec prof_test_bosh_service_broker```

## Testing Pivotal Ops Manager products

Currently Próf only works with .zip files, rather than .pivotal files.

Set two environment variables:

* `TEMPEST_CONFIG_FILE_PATH` - path to a file describing the Ops Manager
  environment to test against. See
  [deployments-london](https://github.com/pivotal-cf-experimental/deployments-london).
* `TEMPEST_ARTIFACT_PATH` - path to a .zip file on disk, which is the product
  you want to test.

### Service Brokers and Products

To run tests that upload, deploy and verify a generic Ops Manager product, use `$ bundle exec prof_test_pom_product`.

To run the above *and* service broker-specific tests, use `$ bundle exec prof_test_pom_service_broker` instead.

### Extension Points for Pivotal Ops Manager tests

The two commands to run Ops Manager tests (`prof_test_pom_product` and `prof_test_pom_service_broker`) will look for additional specs to run in `$PWD/spec/prof_extensions/pom/`, before the Ops Manager deployment is cleaned up.
