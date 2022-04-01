package symfony_docker

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

	actions: versions: {
		"8.0": _
		"8.1": _
		[tag=string]: {
			build: docker.#Build & {
				#Run: docker.#Run & {
					command: name: "apt-get"
				}
				steps: [
					docker.#Pull & {
						source: "php:\(tag)-cli"
					},
					#Run & {
						command: args: ["update", "-y"]
					},
					#Run & {
						command: args: ["install", "-y", "--no-install-recommends", "libzip-dev", "zip", "git"]
					},
					#Run & {
						command: args: ["clean"]
					},
					docker.#Copy & {
						contents: client.filesystem."./".read.contents
						dest: "/srv/app"
					},
				]
			}
		}
	}
}
