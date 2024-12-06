

# Basic lint checking
lintCheck:
	# The configuration is done piece-wise in order to skip the
	# kube-compare reference tree. Those yamls are augmented with
	# golang templating and are not expected to be legal yaml.
	yamllint -c .yamllint.yaml telco-core/configuration/*yaml
	yamllint -c .yamllint.yaml telco-core/configuration/reference-crs
	yamllint -c .yamllint.yaml telco-core/configuration/template-values
	yamllint -c .yamllint.yaml telco-core/install/

ci-validate: lintCheck check-reference

.PHONY: check-reference

check-reference:
        $(MAKE) -C ./telco-core/configuration check
