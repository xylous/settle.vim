# Changelog

## v0.4.3 - 2023-02-25

- add `:SettleGraph` command, for opening up a graph of the entire Zettelkasten
    using xdot

## v0.4.2 - 2023-02-23

- update system calls to conform with `settle v0.39.0`'s new command structure

## v0.4.1 - 2022-04-11

- when running SettleNewInteractive, provide TAB completion for projects by
    using `settle projects` (requires settle v0.36.3)

## v0.4.0 - 2022-04-02

- add a command to follow the wikilink under cursor
- add a function to get the proper title of a wikilink, without newlines or tabs
- add a wikilink text object, mapped to `il`

## v0.3.4 - 2022-03-29

- fix: strip newlines when creating Zettel from links
- fix: escape double quotes when following paths
- fix: use double quotes to pass arguments to `settle` so that single quotes
    work

## v0.3.3 - 2022-03-13

- add a command to create Zettel interactively, by prompting the user for input

## v0.3.2 - 2022-03-12

- add a command to create the Zettel with the title of the wiki-style link under
    the cursor

## v0.3.1 - 2022-03-12

- fix: when running `:SettleNew` without a project, don't use double forward
    slashes in the path
- fix: delimit arguments to `:SettleNew` by commas, not by whitespace

## v0.3.0 - 2022-03-12

- use FZF when running `:SettleEdit`
- conform to settle v0.36.0: use projects
- update `:SettleNew`'s argument structure

## v0.2.0 - 2022-01-17

- update commands to be compatible with settle v0.34.0

## v0.1.0 - 2021-12-15

- add commands to:
    - use `settle new` and then open the newly created file
    - open and edit Zettel based on a query/pattern match
- after editing a Zettel, update its metadata in the database
