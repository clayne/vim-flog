"
" This file contains functions for formatting contextual Floggraph command specifiers.
"

function! flog#floggraph#format#GetCacheCmdRefs(dict, commit) abort
  let l:refs = flog#state#GetCommitRefs(a:commit)
  let a:dict.refs[a:commit.hash] = l:refs
  return l:refs
endfunction

function! flog#floggraph#format#FormatHash(save) abort
  let l:commit = flog#floggraph#commit#GetAtLine('.')
  
  if !empty(l:commit)
    if a:save
      call flog#floggraph#mark#SetInternal('!', '.')
    endif
    return l:commit.hash
  endif

  return ''
endfunction

function! flog#floggraph#format#FormatMarkHash(key) abort
  let l:commit = flog#floggraph#mark#Get(a:key)
  return empty(l:commit) ? '' : l:commit.hash
endfunction

function! flog#floggraph#format#FormatCommitBranch(dict, commit) abort
  let l:local_branch = ''
  let l:remote_branch = ''

  for l:ref in flog#floggraph#format#GetCacheCmdRefs(a:dict, a:commit)
    " Skip non-branches
    if l:ref.tag || l:ref.tail =~# 'HEAD$'
      continue
    endif

    " Get local branch
    if empty(l:ref.remote) && empty(l:ref.prefix)
      let l:local_branch = l:ref.tail
      break
    endif

    " Get remote branch
    if empty(l:remote_branch) && !empty(l:ref.remote)
      let l:remote_branch = l:ref.path
    endif
  endfor

  let l:branch = empty(l:local_branch) ? l:remote_branch : l:local_branch

  return flog#shell#Escape(l:branch)
endfunction

function! flog#floggraph#format#FormatBranch(dict) abort
  let l:commit = flog#floggraph#commit#GetAtLine('.')
  return flog#floggraph#format#FormatCommitBranch(a:dict, l:commit)
endfunction

function! flog#floggraph#format#FormatMarkBranch(dict, key) abort
  let l:commit = flog#floggraph#mark#Get(a:key)
  return flog#floggraph#format#FormatCommitBranch(a:dict, l:commit)
endfunction

function! flog#floggraph#format#FormatCommitLocalBranch(dict, commit) abort
  let l:branch = flog#floggraph#format#FormatCommitBranch(a:dict, a:commit)
  return substitute(l:branch, '.\{-}/', '', '')
endfunction

function! flog#floggraph#format#FormatLocalBranch(dict) abort
  let l:commit = flog#floggraph#commit#GetAtLine('.')
  return flog#floggraph#format#FormatCommitLocalBranch(a:dict, l:commit)
endfunction

function! flog#floggraph#format#FormatMarkLocalBranch(dict, key) abort
  let l:commit = flog#floggraph#mark#Get(a:key)
  return flog#floggraph#format#FormatCommitLocalBranch(a:dict, l:commit)
endfunction

function! flog#floggraph#format#FormatPath() abort
  let l:state = flog#state#GetBufState()
  let l:path = l:state.opts.path

  if !empty(l:state.opts.limit)
    let [l:range, l:limit_path] = flog#args#SplitGitLimitArg(l:state.opts.limit)

    if empty(l:limit_path)
      return ''
    endif

    let l:path = [l:limit_path]
  elseif empty(l:path)
    return ''
  endif

  return join(flog#shell#EscapeList(l:path), ' ')
endfunction

function! flog#floggraph#format#FormatIndexTree(dict) abort
  if empty(a:dict.index_tree)
    let l:cmd = flog#fugitive#GetGitCommand()
    let l:cmd .= ' write-tree'
    let a:dict.index_tree = flog#shell#Run(l:cmd)[0]
  endif
  return a:dict.index_tree
endfunction

function! flog#floggraph#format#HandleCommandItem(dict, item, end) abort
  let l:items = a:dict.items

  let l:formatted_item = ''
  let l:save = v:true

  if a:item !~# '^%'
    let l:formatted_item = a:item
    let l:save = v:false
  elseif has_key(l:items, a:item)
    let l:formatted_item = l:items[a:item]
    let l:save = v:false
  elseif a:item ==# '%%'
    let l:formatted_item = '%'
  elseif a:item ==# '%h'
    let l:formatted_item = flog#floggraph#format#FormatHash(v:true)
  elseif a:item ==# '%H'
    let l:formatted_item = flog#floggraph#format#FormatHash(v:false)
  elseif a:item =~# "^%(h'."
    let l:formatted_item = flog#floggraph#format#FormatMarkHash(a:item[4 : -2])
  elseif a:item =~# '%b'
    let l:formatted_item = flog#floggraph#format#FormatBranch(a:dict)
  elseif a:item =~# "^%(b'."
    let l:formatted_item = flog#floggraph#format#FormatMarkBranch(a:dict, a:item[4 : -2])
  elseif a:item =~# '%l'
    let l:formatted_item = flog#floggraph#format#FormatLocalBranch(a:dict)
  elseif a:item =~# "^%(l'."
    let l:formatted_item = flog#floggraph#format#FormatMarkLocalBranch(a:dict, a:item[4 : -2])
  elseif a:item ==# '%p'
    let l:formatted_item = flog#floggraph#format#FormatPath()
  elseif a:item ==# '%t'
    let l:formatted_item = flog#floggraph#format#FormatIndexTree(a:dict)
  else
    call flog#print#err('error converting "%s"', a:item)
    throw g:flog_unsupported_exec_format_item
  endif

  if empty(l:formatted_item)
    let a:dict.result = ''
    return -1
  endif

  if l:save
    let l:items[a:item] = l:formatted_item
  endif

  let a:dict.result .= l:formatted_item
  return 1
endfunction

function! flog#floggraph#format#FormatCommand(str) abort
  call flog#floggraph#buf#AssertFlogBuf()

  let l:dict = {
        \ 'items': {},
        \ 'refs': {},
        \ 'index_tree': '',
        \ 'result': '',
        \ }

  call flog#format#ParseFormat(a:str, l:dict, function("flog#floggraph#format#HandleCommandItem"))

  return l:dict.result
endfunction