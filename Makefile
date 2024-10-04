

# Basic lint checking
lintCheck:
	yamllint -c ylcfg.yaml telco-core/configuration/ns.yaml
	#yamllint -c ylcfg.yaml telco-core/configuration/*yaml
	#yamllint -c ylcfg.yaml telco-core/configuration/reference-crs
	#yamllint -c ylcfg.yaml telco-core/configuration/template-values
	#yamllint -c ylcfg.yaml telco-core/install/

ci-validate: lintCheck
