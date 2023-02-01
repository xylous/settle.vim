if exists('g:loaded_settle')
    finish
endif

" Return a string containing the absolute path to the Zettelkasten that settle
" uses
function! SettleVimZettelkasten()
    return substitute(system('settle ls path'), "\n$", "", "e")
endfunction

" Given a single entry of settle's output, return a list of two elements: the
" project and the title
function! SettleVimParseZettelInformation(args)
    let no_newline=substitute(a:args, '\n', '', 'ge')
    let project=matchstr(l:no_newline, '\[\zs.*\ze\] .*')
    let title=matchstr(l:no_newline, '\[.*\] \zs.*\ze')
    return [project, title]
endfunction

" Return the path that a Zettel can be found at, given an entry of settle's
" output
function! SettleVimZettelPath(args)
    let l:parsed = SettleVimParseZettelInformation(a:args)
    let l:project = substitute(l:parsed[0], "[\]\[]", "", "ge")
    if l:project != ''
        let l:project=l:project . '/'
    endif
    let l:title = substitute(l:parsed[1], '\"', '\\\"', "ge" )
    return SettleVimZettelkasten() . '/' . l:project . l:title . '.md'
endfunction

" Run `settle new` with the provided arguments and edit the file
function! SettleVimSettleNew(project, title)
    augroup SettleVimEditBuffer
        autocmd!
        autocmd BufLeave *.md call system('settle -Su "' . expand('%:p') . '"')
    augroup END
    let l:res=system('settle -S --project "' . a:project . '" --create "' . a:title . '"')
    " If we have invalid output, i.e. with errors, print the error message and
    " abort
    if l:res[0] != '['
        echom l:res
        return 1
    endif
    let l:path=SettleVimZettelPath(l:res)
    execute 'edit ' . l:path
endfunction

" Open an instance of FZF on the main Zettelkasten directory
function! SettleVimSettleEdit()
    augroup SettleVimEditBuffer
        autocmd!
        autocmd BufLeave *.md call system('settle -Su "' . expand('%:p') . '"')
    augroup END
    execute 'FZF ' . SettleVimZettelkasten()
endfunction

" When invoked, prompt the user for input and run SettleNew
function! SettleVimInteractiveSettleNew()
    let project = input('Project: ', '', 'custom,SettleVimAutocompleteProject')
    let title = input('Title: ')
    if title != ''
        execute 'SettleNew project,title'
    else
        echo 'no title specified; abort'
    endif
endfunction

" Define a wikilink text object as everything between `[[` and a matching `]]`
" Beware that, even if the cursor isn't on the link, it will still select it
" Also, if you're on a different line than the beginning `[[` of the wikilink
" you want to select, it's not going to work properly.
function! s:wikilink_textobj()
    let l:link_regex='\[\[\zs\_.\{-}\ze\]\]'
    if search(l:link_regex, 'ceW')
        normal v
        call search(l:link_regex, 'bcW')
    endif
endfunction

xnoremap <silent> il :<C-u>call <sid>wikilink_textobj()<CR>
onoremap il :<C-u>normal vil<CR>

" Return the wikilink under cursor, without newlines or tabs
function! SettleVimGrabWikilinkTitle()
    normal "ayil
    return substitute(getreg('a'), '[\n\t]', ' ', 'ge')
endfunction

" Create the wikilink under cursor, if it doesn't exist already
function! SettleVimSettleNewLinkUnderCursor()
    let l:title = SettleVimGrabWikilinkTitle()
    execute 'SettleNew "","' . l:title . '"'
endfunction

" Follow the wikilink under cursor, if a note with the corresponding title
" exists
function! SettleVimFollowWikilink()
    let l:title = SettleVimGrabWikilinkTitle()
    let l:results = split(system('settle -Qe -t "' . l:title . '"'), '\n')
    let l:to_edit = ''
    for l:found in l:results
        let l:to_edit .= SettleVimZettelPath(l:found)
    endfor
    if len(l:to_edit) != 0
        execute ':edit ' . l:to_edit
    else
        echo 'settle.vim: no such note'
    endif
endfunction

" Return a list of projects in the Zettelkasten via `settle projects`.
" Intended to be used in command completion
function! SettleVimAutocompleteProject(A,L,P)
    return system('settle ls projects')
endfunction

" If xdot is found on the user's system, create a graph in settle's default
" configuration directory ('zk.gv') and open it with xdot.
function! SettleVimGraphView()
    if len($XDG_CONFIG_HOME) != 0
        let l:dir = $XDG_CONFIG_HOME . "/settle/"
    else
        let l:dir = $HOME . "/.config/settle/"
    endif
    let l:graph_file = "zk.gv"

    if executable("xdot")
        echo "settle.vim: loading graph with xdot..."
        call system("settle -Q --graph >" . l:dir . l:graph_file)
        call system("xdot " . l:dir . l:graph_file)
    else
        echo "settle.vim: couldn't find xdot to open the graph; abort"
    endif
endfunction

" Export commands
command! -nargs=* SettleNew call SettleVimSettleNew(<args>)
command! -nargs=0 SettleNewUnderLink call SettleVimSettleNewLinkUnderCursor()
command! -nargs=0 SettleNewInteractive call SettleVimInteractiveSettleNew()
command! -nargs=0 SettleEdit call SettleVimSettleEdit()
command! -nargs=0 SettleFollow call SettleVimFollowWikilink()
command! -nargs=0 SettleGraph call SettleVimGraphView()

let g:loaded_settle = 1
