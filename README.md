# get-github-release

Utility script to download download github releases

## Installing

### Script Download
The easiest way to install is run in a terminal:
```shell
> curl -sL https://git.io/JeOSF | bash
```
make sure the user has write permissions to `/usr/local/bin`.

### Git Install
After checking out the git repo, run `install.sh local`

### Manual Download
You can download it directly from [github](https://raw.githubusercontent.com/gesquive/get-github-release/master/get-github-release.sh). or run `wget https://raw.githubusercontent.com/gesquive/get-github-release/master/get-github-release.sh`.

Once you have the script, make sure to copy it somewhere on your path like `/usr/local/bin`. Make sure to run `chmod +x /path/to/get-github-release`.

## Usage
```shell
Utility script to download a github release from a public github repo

Usage:
  get-github-release [flags] <REPO>

Flags:
  -q, --quiet     Silence all output
  -d, --dest      The destination path & name (default:PWD)
  -t, --tag       The tag name to download (default:latest)
  -e, --extract   The file to extract and save, this must match the name in the archive
  -h, --help      Show this help and exit
  --version       Show the version and exit
```

## Documentation
This documentation can be found at github.com/gesquive/get-github-release

## License
This package is made available under an MIT-style license. See LICENSE.

## Contributing
PRs are always welcome!
