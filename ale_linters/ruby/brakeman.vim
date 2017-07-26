" Author: Eddie Lebow https://github.com/elebow
" Description: Brakeman, a static analyzer for Rails security

let g:ale_ruby_brakeman_options =
\   get(g:, 'ale_ruby_brakeman_options', '')

function! ale_linters#ruby#brakeman#Handle(buffer, lines) abort
    if len(a:lines) == 0
        return []
    endif

    try
        let l:result = json_decode(join(a:lines, ''))
    catch /E474/
        " Ignore invalid JSON
        return []
    endtry

    let l:output = []

    for l:warning in l:result.warnings
        " Brakeman always outputs paths relative to the Rails app root
        let l:rails_root = ale#ruby#FindRailsRoot(a:buffer)
        let l:warning_file = l:rails_root . '/' . l:warning.file

        if !ale#path#IsBufferPath(a:buffer, l:warning_file)
          continue
        endif

        let l:text = l:warning.warning_type . ' ' . l:warning.message . ' (' . l:warning.confidence . ')'
        let l:line = l:warning.line != v:null ? l:warning.line : 1

        call add(l:output, {
        \    'lnum': l:line,
        \    'type': 'W',
        \    'text': l:text,
        \})
    endfor

    return l:output
endfunction

function! ale_linters#ruby#brakeman#GetCommand(buffer) abort
    let l:rails_root = ale#ruby#FindRailsRoot(a:buffer)

    if l:rails_root ==? ''
        return ''
    endif

    return 'brakeman -f json -q '
    \    . ale#Var(a:buffer, 'ruby_brakeman_options')
    \    . ' -p ' . ale#Escape(l:rails_root)
endfunction

call ale#linter#Define('ruby', {
\    'name': 'brakeman',
\    'executable': 'brakeman',
\    'command_callback': 'ale_linters#ruby#brakeman#GetCommand',
\    'callback': 'ale_linters#ruby#brakeman#Handle',
\    'lint_file': 1,
\})
