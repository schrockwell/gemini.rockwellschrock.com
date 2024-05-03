# www.schrockwell.com and gmi.schrockwell.com

This is the content and build scripts for building these static sites.

- [http://www.schrockwell.com/](http://www.schrockwell.com/)
- [gemini://gmi.schrockwell.com/](gemini://gmi.schrockwell.com/)

## Development

Requirements:

- Ruby
- [agate](https://github.com/mbrubeck/agate/releases)

```sh
# Just build the sites
./generate.rb

# Run local Web and Gemini servers which auto-rebuild on file changes
./generate.rb server
```

## Deploying

Configure the `gemini` SSH host.

```sh
./publish_gmi.sh
```
