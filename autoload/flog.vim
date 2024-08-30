"
" This file contains public Flog API functions.
"

function! flog#Version() abort
  return '3.0.0'
endfunction

function! flog#Exec(cmd, blur = v:false, static = v:false, tmp = v:false) abort
  if empty(a:cmd)
    return ''
  endif

  if !flog#floggraph#buf#IsFlogBuf()
    exec a:cmd
    return a:cmd
  endif

  let l:graph_win = flog#win#Save()
  let l:should_auto_update = flog#floggraph#opts#ShouldAutoUpdate()

  call flog#floggraph#side_win#Open(a:cmd, a:blur, a:tmp)

  if !a:static && !l:should_auto_update
    if flog#win#Is(l:graph_win)
      call flog#floggraph#buf#Update()
    else
      call flog#floggraph#buf#InitUpdateHook(flog#win#GetSavedBufnr(l:graph_win))
    endif
  endif

  return a:cmd
endfunction

function! flog#ExecTmp(cmd, blur = v:false, static = v:false) abort
  return flog#Exec(a:cmd, a:blur, a:static, v:true)
endfunction

function! flog#Format(cmd) abort
  return flog#floggraph#format#FormatCommand(a:cmd)
endfunction

" Deprecations

function! flog#run_raw_command(...) abort
  call flog#deprecate#Function('flog#run_raw_command', 'flog#Exec')
endfunction

function! flog#run_command(...) abort
  call flog#deprecate#Function('flog#run_command', 'flog#Exec', 'flog#Format(...), ...')
endfunction

function! flog#run_tmp_command(...) abort
  call flog#deprecate#Function('flog#run_tmp_command', 'flog#ExecTmp')
endfunction
