# opensub

> A command-line tool to search and download subtitles from opensubtitles.org

## Goals

* A CLI-based subtitle downloader
* Does not require any API key
* Usable through a VPN connection

## Dependencies

- [curl](https://curl.haxx.se/download.html)
- [pup](https://github.com/EricChiang/pup)
- [fzf](https://github.com/junegunn/fzf)
- [unzip](http://infozip.sourceforge.net/UnZip.html#Downloads)

```
pacman -S curl unzip fzf
go install github.com/EricChiang/pup@latest`
```

## How to use

### Usage

`./opensubtitles-dl.sh [-n <name>] [-l <lang>] [-d]`

### Options
```
  -n <name>               TV series or Movie name
  -l <lang>               optional, language
                          e.g.: eng, spa, fre...
                          default: eng
  -a                      optional, download all available subtitles
  -d                      enable debug mode
  -h | --help             display this help message
```

### Examples

Download a Spanish subtitle of "The Witcher" Season 2 Episode 1:

`$ ./opensubtitles-dl.sh -n 'the witcher s02e01' -l spa`

Download all of the subtitles available for "Hackers":

`$ ./opensubtitles-dl.sh -n 'hackers' -a`

