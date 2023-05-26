if exists('g:loaded_settle')
    finish
endif

" Update metadata upon finishing editing a note
" Set title autocompletion for markdown buffers only
augroup settle_vim
    autocmd!
    autocmd BufWritePost *.md call system('settle -Su "' . expand('%:p') . '"')
    autocmd FileType markdown setlocal completefunc=settle#complete_ins_note
augroup END

" Run `settle new` with the provided arguments and edit the file
function! settle#new(project, title)
    let l:res=system('settle -S --project "' . a:project . '" --create "' . a:title . '"')
    " If we have invalid output, i.e. with errors, print the error message and
    " abort
    if l:res[0] != '['
        echom l:res
        return 1
    endif
    let l:path = settle#parse_zettel_path(l:res)
    execute 'edit ' . l:path
endfunction

" Create the wikilink under cursor, if it doesn't exist already
function! settle#new_from_link()
    let l:title = settle#link_under_cursor()
    execute 'settle#new "","' . l:title . '"'
endfunction

" When invoked, prompt the user for input and run SettleNew
function! settle#new_from_prompt()
    let project = input('Project: ', '', 'custom,settle#complete_cmd_project')
    let title = input('Title: ')
    if title != ''
        execute 'SettleNew project,title'
    else
        echo 'no title specified; abort'
    endif
endfunction

" Open an instance of FZF on the query results
function! settle#query(...)
    let query = join(a:000)
    let command = 'settle query --format "%P" ' . query
    let flags = {'options': ['--enabled', '--delimiter', '/', '--with-nth', '-1'], 'source': command}
    call fzf#run(fzf#vim#with_preview(fzf#wrap(flags)))
endfunction

" If xdot is found on the user's system, create a graph in settle's default
" configuration directory ('zk.gv') and open it with xdot.
function! settle#graph()
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
        echo "settle.vim: couldn't find 'xdot' program; install it to visualise graph"
    endif
endfunction

" Follow the wikilink under cursor, if a note with the corresponding title
" exists
function! settle#follow_link()
    let l:title = settle#link_under_cursor()
    let l:results = split(system('settle -Qe -f "%P" -t "' . l:title . '"'), '\n')
    let l:to_edit = ''
    for l:found in l:results
        let l:to_edit .= l:found
    endfor
    if ! empty(l:to_edit)
        execute ':edit ' . l:to_edit
        call settle#link_stack_add(bufnr('%'), bufnr('#'))
    else
        echo 'settle.vim: no such note'
    endif
endfunction

" Move to the note that invoked this one
function! settle#follow_backlink()
    let current_buffer_num = bufnr('%')
    let backlink_num = settle#link_stack_pop(current_buffer_num)
    if empty(backlink_num)
        echomsg "settle.vim: no backlinks to move to"
    else
        execute ':b ' . backlink_num
    endif
endfunction

" Return a string containing the absolute path to the Zettelkasten that settle
" uses
function! settle#zettelkasten_path()
    return substitute(system('settle ls path'), "\n$", "", "e")
endfunction

" Given a single entry of settle's output, return a list of two elements: the
" project and the title
function! settle#parse_zettel(args)
    let no_newline=substitute(a:args, '\n', '', 'ge')
    let project=matchstr(l:no_newline, '\[\zs.*\ze\] .*')
    let title=matchstr(l:no_newline, '\[.*\] \zs.*\ze')
    return [project, title]
endfunction

" Return the path that a Zettel can be found at, given an entry of settle's
" output
function! settle#parse_zettel_path(args)
    let l:parsed = settle#parse_zettel(a:args)
    let l:project = substitute(l:parsed[0], "[\]\[]", "", "ge")
    if l:project != ''
        let l:project=l:project . '/'
    endif
    let l:title = substitute(l:parsed[1], '\"', '\\\"', "ge" )
    return settle#zettelkasten_path() . '/' . l:project . l:title . '.md'
endfunction

" Return the wikilink under cursor, without newlines or tabs
function! settle#link_under_cursor()
    normal "ayil
    return substitute(getreg('a'), '\(\n\|\s\)\+', ' ', 'ge')
endfunction

" Add `backlink` to the buffer-local variable `b:settle_stack`, which tracks all
" backlinks of this note
function! settle#link_stack_add(buffer, backlink)
    let old = settle#link_stack_get(a:buffer)
    if empty(old)
        call setbufvar(a:buffer, 'settle_stack', [a:backlink])
    else
        let new = [a:backlink] + old
        call setbufvar(a:buffer, 'settle_stack', new)
    endif
endfunction

" Remove the first element of the buffer-local variable `b:settle_stack` and
" return it
function! settle#link_stack_pop(buffer)
    let old = settle#link_stack_get(a:buffer)
    call setbufvar(a:buffer, 'settle_stack', old[1:])
    if empty(old)
        return []
    else
        return old[0]
    endif
endfunction

" Return the buffer-local variable `b:settle_stack`
function! settle#link_stack_get(buffer)
    return getbufvar(a:buffer, 'settle_stack')
endfunction

" Return a list of projects in the Zettelkasten via `settle projects`.
" Intended to be used in command completion
function! settle#complete_cmd_project(A,L,P)
    return system('settle ls projects')
endfunction

" Autocomplete in insert-mode with note titles
function! settle#complete_ins_note(findstart, base)
    let notes = split(system('settle query --format "%t"'), '\n')
    if a:findstart
        " vim requires us to find the start of the base word for autocompletion
        " words are delimited by spaces, tabs, and square parentheses, so we're
        " going to go from cursor position backwards until we encounter one of
        " those characters
        let line = getline('.')
        let start = col('.') - 1
        while start > 0 && (line[start - 1] != ' ' && line[start - 1] != '\t'
                    \ && line[start - 1] != '[')
            let start -= 1
        endwhile
        return start
    else
        " store all valid matches into this variable
        let res = []
        " note that if the word base is empty, then everything is matched
        for m in notes
            if m =~ '^' . a:base
                call add(res, m)
            endif
        endfor
        return res
    endif
endfunction

"""COMMANDS"""

command! -nargs=* SettleNew call settle#new(<args>)
command! -nargs=0 SettleNewFromLink call settle#new_from_link()
command! -nargs=0 SettleNewFromPrompt call settle#new_from_prompt()
command! -nargs=* SettleQuery call settle#query(<args>)
command! -nargs=0 SettleGraph call settle#graph()
command! -nargs=0 SettleFollow call settle#follow_link()
command! -nargs=0 SettleBacklink call settle#follow_backlink()

"""TEXT OBJECTS"""

" NOTE: even if the cursor isn't on the link, it will still select it

" match everything between `[[` and `]]` but not the square parentheses
" themselves
function! s:inside_wikilink()
    let l:link_regex='\[\[\zs\_.\{-}\ze\]\]'
    if search(l:link_regex, 'ceW')
        normal v
        call search(l:link_regex, 'bcW')
    endif
endfunction

" match an entire link, both the square parentheses and what's inside them
function! s:around_wikilink()
    let l:link_regex='\zs\[\[\_.\{-}]\]\ze'
    if search(l:link_regex, 'ceW')
        normal v
        call search(l:link_regex, 'bcW')
    endif
endfunction

xnoremap <silent> il :call <sid>inside_wikilink()<CR>
onoremap il :normal vil<CR>

xnoremap <silent> al :call <sid>around_wikilink()<CR>
onoremap al :normal val<CR>

let g:loaded_settle = 1
