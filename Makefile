DAGGER = dagger

.DEFAULT_GOAL := dagger-build

dagger-build: ## Run the build step
dagger-build:
	$(DAGGER) do build --plan .cloud/dagger/symfony.cue

dagger-tests: ## Run the tests step
dagger-tests:
	$(DAGGER) do tests --plan .cloud/dagger/symfony.cue
