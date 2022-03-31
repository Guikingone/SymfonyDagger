package symfony_demo

import (
	"dagger.io/dagger"
	"dagger.io/dagger/core"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	_vendorMount: "/vendor": {
		dest: "/srv/app/vendor",
		type: "Cache",
		contents: core.#CacheDir & {
			id: "vendor-cache"
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
			APP_ENV: string,
			APP_DIR: string
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
				},
				docker.#Run & {
					command: {
						name: "composer"
						args: ["dump-autoload", "--optimize", "--classmap-authoritative"]
					}
				},
			]
		}
		tests: docker.#Run & {
			input: build.output
			command: {
				name: "bin/phpunit"
			}
		}
	}
}
