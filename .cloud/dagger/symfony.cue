package symfony_demo

import (
	"dagger.io/dagger"
	"universe.dagger.io/docker"
)

dagger.#Plan & {
	_vendorMount: "/srv/app/vendor": {
		dest: "/srv/app/vendor",
		type: "cache",
		contents: id: "vendor-cache"
	}
	_phpunitMount: "/srv/app/bin/.phpunit": {
		dest: "/srv/app/bin/.phpunit",
		type: "cache",
		contents: id: "phpunit-cache"
	}

	client: {
		filesystem: {
			"./": read: {
				contents: dagger.#FS,
				exclude: [".github", ".editorconfig", "CONTRIBUTING.md", "README.md", "vendor", "symfony.cue"]
			}
		}
		env: {
			APP_ENV: string
		}
	}

	actions: {
		build: docker.#Build & {
			#Run: docker.#Run & {
				command: name: "composer"
			}
			steps: [
				docker.#Dockerfile & {
					source: client.filesystem."./".read.contents
					dockerfile: path: "./.cloud/docker/php/Dockerfile"
				},
				#Run & {
					command: args: ["install"]
					mounts: _vendorMount
				},
				#Run & {
					command: args: ["dump-autoload", "--optimize", "--classmap-authoritative"]
				},
			]
		}
		#Run: docker.#Run & {
			input: build.output
			mounts: _vendorMount
		}
		tests: #Run & {
			command: name: "bin/phpunit"
			mounts: {
				_vendorMount,
				_phpunitMount
			}
		}
		linting: {
			[string]: #Run & {
				command: name: "bin/console"
			}
			yaml: command: args: ["lint:yaml", "config", "--parse-tags"]
			xlif: command: args: ["lint:xliff", "translations"]
			container: command: args: ["lint:container", "--no-debug"]
			twig: command: args: ["lint:twig", "templates", "--env=prod"]
		}
		phpstan: #Run & {
			command: {
				name: "vendor/bin/phpstan"
				args: ["analyse"]
			}
		}
	}
}
