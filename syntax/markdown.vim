" colour just the link contents; default colour is purple-ish

syntax region settleWikilink start=/\[\[/ end=/\]\]/

if !exists("g:settle_wikilink_hl_guifg")
    let g:settle_wikilink_hl_guifg="#e647e0"
endif

if exists("g:settle_wikilink_hl_enable") && g:settle_wikilink_hl_enable
    execute "highlight default settleWikilink guifg=" . g:settle_wikilink_hl_guifg
endif
