package e2e

import (
	"regexp"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_helper "github.com/lonegunmanb/terraform-module-test-helper"
	"github.com/stretchr/testify/assert"
)

func TestExamplesStartup(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/startup", terraform.Options{
		Upgrade: true,
		Vars: map[string]interface{}{
			"client_id":     "",
			"client_secret": "",
		},
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		aksId, ok := output["test_aks_id"].(string)
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ContainerService/managedClusters/.+"), aksId)
	})
}

func TestExamplesWithoutMonitor(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/without_monitor", terraform.Options{
		Upgrade: true,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		aksId, ok := output["test_aks_without_monitor_id"].(string)
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ContainerService/managedClusters/.+"), aksId)
		identity, ok := output["test_aks_without_monitor_identity"].(map[string]interface{})
		assert.True(t, ok)
		assert.NotNil(t, identity)
		assert.NotEmptyf(t, identity, "identity should not be empty")
		principleId, ok := identity["principal_id"]
		assert.True(t, ok)
		assert.NotEqual(t, "", principleId)
	})
}

func TestExamplesNamedCluster(t *testing.T) {
	test_helper.RunE2ETest(t, "../../", "examples/named_cluster", terraform.Options{
		Upgrade: true,
	}, func(t *testing.T, output test_helper.TerraformOutput) {
		aksId, ok := output["test_aks_named_id"].(string)
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ContainerService/managedClusters/.+"), aksId)
		identity, ok := output["test_aks_named_identity"].(map[string]interface{})
		assert.True(t, ok)
		assert.NotNil(t, identity)
		assert.NotEmptyf(t, identity, "identity should not be empty")
		identityId, ok := identity["user_assigned_identity_id"]
		assert.True(t, ok)
		assert.Regexp(t, regexp.MustCompile("/subscriptions/.+/resourceGroups/.+/providers/Microsoft.ManagedIdentity/userAssignedIdentities/.+"), identityId)
	})
}
