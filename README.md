fzf :purple_heart: devicon :heart: vim
===============

Things is a fork of `fzf.vim` that adds in support for devicons via the `devicon-lookup` tool

This fork is compatible side by side with `fzf.vim` however it is NOT required! The commands
that this plugin exports are post-fixed so as to NOT conflict with the originals

Installation
------------

fzf.devicon.vim depends on BOTH the basic Vim plugin of [the main fzf
repository][fzf] and [the fzf.vim plugin][fzf.vim] which means you need to **set up both "fzf" and
"fzf.vim" on Vim**.
[README-VIM][README-VIM].

[fzf-main]: https://github.com/junegunn/fzf
[README-VIM]: https://github.com/junegunn/fzf/blob/master/README-VIM.md

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'coreyja/fzf.devicon.vim'
```

`fzf#install()` makes sure that you have the latest binary, but it's optional,
so you can omit it if you use a plugin manager that doesn't support hooks.

Commands
--------

| Command                       | List                                                                    |
| ---                           | ---                                                                     |
| `:FilesWithDevicons [PATH]`   | Files (runs `$FZF_DEFAULT_COMMAND` if defined)                          |
| `:GFilesWithDevicons [OPTS]`  | Git files (`git ls-files`)                                              |
| `:GFilesWithDevicons?`        | Git files (`git status`)                                                |
| `:AgWithDevicons [PATTERN]`   | [ag][ag] search result (`ALT-A` to select all, `ALT-D` to deselect all) |
| `:RgWithDevicons [PATTERN]`   | [rg][rg] search result (`ALT-A` to select all, `ALT-D` to deselect all) |
| `:LocateWithDevicons PATTERN` | `locate` command output                                                 |

- Most commands support `CTRL-T` / `CTRL-X` / `CTRL-V` key
  bindings to open in a new tab, a new split, or in a new vertical split
- Bang-versions of the commands (e.g. `Ag!`) will open fzf in fullscreen
- You can set `g:fzf_command_prefix` to give the same prefix to the commands
    - e.g. `let g:fzf_command_prefix = 'Fzf'` and you have `FzfFiles`, etc.

License
-------

MIT

[fzf]:       https://github.com/junegunn/fzf
[fzf.vim]:   https://github.com/junegunn/fzf.vim
[run]:       https://github.com/junegunn/fzf/blob/master/README-VIM.md#fzfrun
[vimrc]:     https://github.com/junegunn/dotfiles/blob/master/vimrc
[ag]:        https://github.com/ggreer/the_silver_searcher
[rg]:        https://github.com/BurntSushi/ripgrep
[us]:        https://github.com/SirVer/ultisnips
