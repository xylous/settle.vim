"if exists('g:loaded_settle')
    "finish
"endif

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
    let prefixDirectory="/"
    if a:args[0] == '[i]'
        let prefixDirectory='/inbox/'
    endif
    return SettleVimZettelkasten() . prefixDirectory . a:args[1] . '.md'
endfunction

"let g:loaded_settle = 1
