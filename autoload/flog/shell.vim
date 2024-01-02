"
" This file contains functions for working with shell commands.
"

function! flog#shell#Escape(str) abort
  if has('win32') || get(g:, 'flog_use_builtin_shellescape')
    return shellescape(a:str)
  endif
  return escape(a:str, ' *?[]{}`$\%#"|!<();&>' . "\n\t'")
endfunction

function! flog#shell#EscapeList(list) abort
  return map(copy(a:list), 'flog#shell#Escape(v:val)')
endfunction

function! flog#shell#Run(cmd) abort
  let l:output = systemlist(a:cmd)
  if !empty(v:shell_error)
    call flog#print#err(join(l:output, "\n"))
    throw g:flog_shell_error
  endif
  return l:output
endfunction
