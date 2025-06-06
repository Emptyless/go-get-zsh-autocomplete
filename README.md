# 'go get' zsh autocompletions

Inspired by [spf13/cobra completions](https://github.com/spf13/cobra/blob/main/site/content/completions/_index.md), this
repo reproduces similar autocompletions for the 'go get' command based on already locally fetched
packages in the `GOMODCACHE` and uses `git ls-remote` to fetch possible versions for those packages.

> No issues were found during local development and or local usage but your mileage may vary. The author(s) are not responsible 
  for any issues that you may encounter or results thereof when using resources from this repository. Usage is 100%
  at own risk. Submit issues to the Github issue tracker if found.

## Getting Started

Ensure that `Z Shell` (zsh) and Go are installed, e.g. on linux with apt:

```
apt install zsh
apt install golang
```

Or on Mac with (using [Brew](https://brew.sh)):

```
brew install zsh
brew install go
```

Commpletions are based on the `GOMODCACHE` location, if `go` was just installed, verify this location
using `go env GOMODCACHE`

To use ZSH autocompletions, the autocompletion system must have been initialized. If not, ensure that the
following is part of your `~/.zshrc`
```
autoload -Uz compinit
compinit
```

Install the completions using 1 of 2 methods:


1) by appending the file to some `$fpath`, e.g. in `~/.zshrc`:

```
git clone https://github.com/Emptyless/go-zsh-autocomplete
echo "" >> ~/.zshrc
cat go-zsh-autocomplete/_go-zsh-autocomplete.zsh >> ~/.zshrc
```

2) by referencing the _go-zsh-autocomplete.zsh file

```
git clone https://github.com/Emptyless/go-zsh-autocomplete
echo "" >> ~/.zshrc
echo -n "source " >> ~/.zshrc
pwd | tr -d '\n' >> ~/.zshrc
echo "go-zsh-autocomplete/_go-zsh-autocomplete.zsh" >> ~/.zshrc
echo "" >> ~/.zshrc
```

Source the zshrc:

```
source ~/.zshrc
```

And now for any package that is in the GOMODCACHE (see `go env GOMODCACHE`), autocompletion is enabled:

```
go get github<tab>
```

will display all locally cached Github packages. For some <user> and <repo>, fetch the tags and branches using:

```
go get github.com/<user>/<repo>@<tab>
```

which will display all possible branches and tags to use for `go get`

## Oh My ZSH

When using [Oh My Zsh](https://ohmyz.sh), there is a recommended location to store completions:

```
git clone github.com/Emptyless/go-zsh-autocomplete
echo '#!/bin/sh\n' > ~/.oh-my-zsh/completions/_go-zsh-autocomplete.zsh
cat ./go-zsh-autocomplete/_go-zsh-autocomplete.zsh >> ~/.oh-my-zsh/completions/_go-zsh-autocomplete.zsh
chmod +x ~/.oh-my-zsh/completions/_go-zsh-autocomplete.zsh
```

## Debugging

Ensure that the `$ZSH_GO_COMP_DEBUG_FILE` variable is set to some filepath, e.g.

```
export ZSH_GO_COMP_DEBUG_FILE=debug.txt
go get github.com/<tab>
```

## Development

Add the zsh shebang before development and set the debug variable

```
#!/bin/zsh
export ZSH_GO_COMP_DEBUG_FILE=debug.txt
```
