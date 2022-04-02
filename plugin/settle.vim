if exists('g:loaded_settle')
    finish
endif

" Return a string containing the absolute path to the Zettelkasten that settle
" uses
function! SettleVimZettelkasten()
    return substitute(system('settle zk'), "\n$", "", "e")
endfunction

" Given a single entry of settle's output, return a list of two elements: the
" project and the title
function! SettleVimParseZettelInformation(args)
    let spl=split(a:args)
    let title=join(spl[1:-1])
    return [spl[0], title]
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
        autocmd BufLeave *.md call system("settle update \"" . expand('%:p') . "\"")
    augroup END
    let l:res=system("settle new --project \"" . a:project . "\" \"" . a:title . "\"")
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
        autocmd BufLeave *.md call system("settle update \"" . expand('%:p') . "\"")
    augroup END
    execute 'FZF ' . SettleVimZettelkasten()
endfunction

" When invoked, prompt the user for input and run SettleNew
function! SettleVimInteractiveSettleNew()
    let project = input("Project: ")
    let title = input("Title: ")
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
    execute "SettleNew '','" . l:title . "'"
endfunction

" Follow the wikilink under cursor, if a note with the corresponding title
" exists
function! SettleVimFollowWikilink()
    let l:title = SettleVimGrabWikilinkTitle()
    let l:results = split(system("settle query \"" . l:title . "\""), "\n")
    let l:to_edit = ''
    for l:found in l:results
        let l:to_edit .= SettleVimZettelPath(l:found)
    endfor
    execute ":edit " . l:to_edit
endfunction

" Export commands
command! -nargs=* SettleNew call SettleVimSettleNew(<args>)
command! -nargs=0 SettleNewUnderLink call SettleVimSettleNewLinkUnderCursor()
command! -nargs=0 SettleNewInteractive call SettleVimInteractiveSettleNew()
command! -nargs=0 SettleEdit call SettleVimSettleEdit()
command! -nargs=0 SettleFollow call SettleVimFollowWikilink()

let g:loaded_settle = 1
