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

" Return the path that a Zettel can be found at, given an entry of ewsettle's
" output
function! SettleVimZettelPath(args)
    let l:parsed=SettleVimParseZettelInformation(a:args)
    let l:project = substitute(l:parsed[0], "[\]\[]", "", "ge")
    return SettleVimZettelkasten() . '/' . l:project . '/' . l:parsed[1] . '.md'
endfunction

" Run `settle new` with the provided arguments and edit the file
function! SettleVimSettleNew(project, title, ...)
    augroup SettleVimEditBuffer
        autocmd!
        autocmd BufLeave *.md call system("settle update '" . expand('%:p') . "'")
    augroup END
    let l:res=system("settle new --project '" . a:project . "' '" . a:title . "'")
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
        autocmd BufLeave *.md call system("settle update '" . expand('%:p') . "'")
    augroup END
    execute 'FZF ' . SettleVimZettelkasten()
endfunction

" Export commands
command! -nargs=* SettleNew call SettleVimSettleNew(<f-args>)
command! -nargs=0 SettleEdit call SettleVimSettleEdit(<args>)

let g:loaded_settle = 1
