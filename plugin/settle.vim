if exists('g:loaded_settle')
    finish
endif

" Return a string containing the absolute path to the Zettelkasten that settle
" uses
function! SettleVimZettelkasten()
    return substitute(system('settle zettelkasten'), "\n$", "", "e")
endfunction

" Given a single entry of settle's output, return a list of two elements
" containing the 'inbox marker' (`[i]` for inbox, `[p]` for permanent/not inbox)
" and the title of the Zettel
function! SettleVimParseZettelInformation(args)
    let spl=split(a:args)
    let title=join(spl[1:-1])
    return [spl[0], title]
endfunction

" Return the path that a Zettel can be found at, given a *parsed* entry of
" settle's output (see above)
function! SettleVimZettelPath(args)
    let l:prefixDirectory="/"
    if a:args[0] == '[i]'
        let l:prefixDirectory='/inbox/'
    endif
    return SettleVimZettelkasten() . l:prefixDirectory . a:args[1] . '.md'
endfunction

" Run `settle new` with the provided arguments and edit the file
function! SettleVimSettleNew(args)
    augroup SettleVimEditBuffer
        autocmd!
        autocmd BufLeave *.md call system("settle update '" . expand('%:p') . "'")
    augroup END
    let l:res=system('settle new ' . a:args)
    " If we have invalid output, i.e. with errors, print the error message and
    " abort
    if l:res[0] != '['
        echom l:res
        return 1
    endif
    let l:parsed=SettleVimParseZettelInformation(l:res)
    let l:path=SettleVimZettelPath(l:parsed)
    execute 'edit ' . l:path
endfunction

" Edit files whose title matches `pattern`, as per `settle query` results, and
" update their metadata automatically on buffer exit
function! SettleVimSettleEdit(pattern)
    augroup SettleVimEditBuffer
        autocmd!
        autocmd BufLeave *.md call system("settle update '" . expand('%:p') . "'")
    augroup END
    let l:results=split(system("settle query '" . a:pattern . "'"), "\n")
    for res in l:results
        let l:parsed=SettleVimParseZettelInformation(l:res)
        let l:path=SettleVimZettelPath(l:parsed)
        execute 'edit ' . l:path
    endfor
endfunction

" Export commands
command! -nargs=* SettleNew call SettleVimSettleNew(<args>)
command! -nargs=* SettleEdit call SettleVimSettleEdit(<args>)

let g:loaded_settle = 1
