" Copyright (c) 2015 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

let s:cpo_save = &cpoptions
set cpoptions&vim
let s:is_win = has('win32') || has('win64')

function! s:defs(commands)
  let prefix = get(g:, 'fzf_command_prefix', '')
  if prefix =~# '^[^A-Z]'
    echoerr 'g:fzf_command_prefix must start with an uppercase letter'
    return
  endif
  for command in a:commands
    let name = ':'.prefix.matchstr(command, '\C[A-Z]\S\+')
    if 2 != exists(name)
      execute substitute(command, '\ze\C[A-Z]', prefix, '')
    endif
  endfor
endfunction

function! s:p(bang, ...)
  let preview_window = get(g:, 'fzf_preview_window', a:bang && &columns >= 80 || &columns >= 120 ? 'right': '')
  if len(preview_window)
    return call('fzf#devicon#vim#with_preview', add(copy(a:000), preview_window))
  endif
  return {}
endfunction

call s:defs([
\'command!      -bang -nargs=? -complete=dir FilesWithDevicons       call fzf#devicon#vim#files(<q-args>, s:p(<bang>0), <bang>0)',
\'command!      -bang -nargs=? GitFilesWithDevicons                  call fzf#devicon#vim#gitfiles(<q-args>, <q-args> == "?" ? {} : s:p(<bang>0), <bang>0)',
\'command!      -bang -nargs=? GFilesWithDevicons                    call fzf#devicon#vim#gitfiles(<q-args>, <q-args> == "?" ? {} : s:p(<bang>0), <bang>0)',
\'command!      -bang -nargs=+ -complete=dir LocateWithDevicons      call fzf#devicon#vim#locate(<q-args>, s:p(<bang>0), <bang>0)',
\'command!      -bang -nargs=* AgWithDevicons                        call fzf#devicon#vim#ag(<q-args>, s:p(<bang>0), <bang>0)',
\'command!      -bang -nargs=* RgWithDevicons                        call fzf#devicon#vim#grep("rg --column --line-number --no-heading --color=always --smart-case ".shellescape(<q-args>), 1, s:p(<bang>0), <bang>0)'])

let &cpoptions = s:cpo_save
unlet s:cpo_save

