" colour just the link contents; default colour is purple-ish

syntax match settleWikilinkContents /\[\[\zs.\{-}\ze\]\]/hs=s+2,he=e-2

if !exists("g:settle_wikilink_hl_guifg")
    let g:settle_wikilink_hl_guifg="#e647e0"
endif
execute "highlight default settleWikilinkContents guifg=" . g:settle_wikilink_hl_guifg
