# settle.vim

The (n)vim wrapper for [settle](https://github.com/xylous/settle)

## Getting started

### Requirements

- Vim or NeoVim. I've only used it with NVIM v0.6.0 and afterwards, but it
    should work with earlier versions as well without any problem.
- `fzf.vim`
- `settle`
- optional: `xdot`

### Installation

#### Using Pathogen

```
cd ~/.vim
mkdir bundle
cd bundle
git clone https://github.com/xylous/settle.vim.git
```

#### Using Vim-Plug

Add the following line to your vimrc:

```
Plug 'xylous/settle.vim'
```

Then source your vimrc and run `:PlugInstall`

#### Using Vundle

Add the following line to your vimrc:

```
Plugin 'xylous/settle.vim'
```

And then run `vim +PluginInstall +qall` in a shell.

### Usage

[Check the vim-help document](./doc/settle.vim.txt)

Ideally, you should make mappings for the commands that this plugin exports, as
none are made by default.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to
discuss what you would like to change.
