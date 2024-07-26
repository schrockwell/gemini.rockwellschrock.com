# www.schrockwell.com and gmi.schrockwell.com

This is the content and build scripts for building these static sites.

- [http://www.schrockwell.com/](http://www.schrockwell.com/)
- [gemini://gmi.schrockwell.com/](gemini://gmi.schrockwell.com/)

## Nonstandard Gemtext markup

`---` renders as-is in Gemtext, but converts to an `<hr>` in HTML.

`<gemini>` and `</gemini>` toggle Gemini-only scope; the lines between will only be output to Gemtext files.

`<web>` and `</web>` toggle Web-only scope; the lines between will only be output to HTML files.

## Development

Requirements:

- Ruby
- [agate](https://github.com/mbrubeck/agate/releases)
- fswatch (via Homebrew)
- imagemagick (via Homebrew)

```sh
# Just build the sites
./generate.rb

# Run local Web and Gemini servers which auto-rebuild on file changes
./generate.rb server
```

## Deploying to Gemini

Configure the `gemini` SSH host.

```sh
./publish_gmi.sh
```

## Deploying to the Web

Push the `main` branch to GitHub, and the Action will rsync the site to the Web server.
