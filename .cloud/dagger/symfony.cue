package symfony_demo

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	_vendorMount: "/srv/app/vendor": {
		dest: "/srv/app/vendor",
		type: "cache",
		contents: core.#CacheDir & {
			id: "vendor-cache"
		}
	}
	_phpunitMount: "/srv/app/bin/.phpunit": {
		dest: "/srv/app/bin/.phpunit",
		type: "cache",
		contents: core.#CacheDir & {
			id: "phpunit-cache"
		}
	}

	client: {
		filesystem: {
			"./": read: {
				contents: dagger.#FS,
				exclude: [
					".github",
					".editorconfig",
					"CONTRIBUTING.md",
					"README.md",
					"vendor",
					"symfony.cue"
				]
			}
		}
		env: {
			APP_ENV: string
		}
	}

	actions: {
		build: docker.#Build & {
			steps: [
				docker.#Dockerfile & {
					source: client.filesystem."./".read.contents
					dockerfile: {
						path: "./.cloud/docker/php/Dockerfile"
					}
				},
				docker.#Run & {
					command: {
						name: "composer"
						args: ["install"]
					}
					mounts: {
						_vendorMount
					}
				},
				docker.#Run & {
					command: {
						name: "composer"
						args: ["dump-autoload", "--optimize", "--classmap-authoritative"]
					}
				},
			]
		},
		tests: docker.#Run & {
			input: build.output
			command: {
				name: "bin/phpunit"
			}
			mounts: {
				_vendorMount
				_phpunitMount
			}
		},
		linting_yaml: docker.#Run & {
			input: build.output
			command: {
				name: "bin/console"
			  args: ["lint:yaml", "config", "--parse-tags"]
			}
			mounts: {
				_vendorMount
			}
		},
		linting_twig: docker.#Run & {
			input: build.output
			command: {
				name: "bin/console"
			  args: ["lint:twig", "templates", "--env=prod"]
			}
			mounts: {
				_vendorMount
			}
		},
		linting_xliff: docker.#Run & {
			input: build.output
			command: {
				name: "bin/console"
			  args: ["lint:xliff", "translations"]
			}
			mounts: {
				_vendorMount
			}
		},
		linting_container: docker.#Run & {
			input: build.output
			command: {
				name: "bin/console"
			  args: ["lint:container", "--no-debug"]
			}
			mounts: {
				_vendorMount
			}
		},
		phpstan: docker.#Run & {
			input: build.output
			command: {
				name: "vendor/bin/phpstan"
				args: ["analyse"]
			}
			mounts: {
				_vendorMount
			}
		},
	}
}
