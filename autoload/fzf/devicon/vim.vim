" Copyright (c) 2017 Junegunn Choi
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

" ------------------------------------------------------------------
" Common
" ------------------------------------------------------------------

let s:is_win = has('win32') || has('win64')
let s:layout_keys = ['window', 'up', 'down', 'left', 'right']
let s:bin_dir = expand('<sfile>:h:h:h:h').'/bin/'
let s:bin = {
\ 'preview': s:bin_dir.'preview.sh'}
let s:TYPE = {'dict': type({}), 'funcref': type(function('call')), 'string': type(''), 'list': type([])}
if s:is_win
  if has('nvim')
    let s:bin.preview = split(system('for %A in ("'.s:bin.preview.'") do @echo %~sA'), "\n")[0]
  else
    let s:bin.preview = fnamemodify(s:bin.preview, ':8')
  endif
  let s:bin.preview = 'bash '.escape(s:bin.preview, '\')

  function! s:fzf_call(fn, ...)
    let shellslash = &shellslash
    try
      set noshellslash
      return call(a:fn, a:000)
    finally
      let &shellslash = shellslash
    endtry
  endfunction
else
  function! s:fzf_call(fn, ...)
    return call(a:fn, a:000)
  endfunction
endif

let s:wide = 120

function! s:extend_opts(dict, eopts, prepend)
  if empty(a:eopts)
    return
  endif
  if has_key(a:dict, 'options')
    if type(a:dict.options) == s:TYPE.list && type(a:eopts) == s:TYPE.list
      if a:prepend
        let a:dict.options = extend(copy(a:eopts), a:dict.options)
      else
        call extend(a:dict.options, a:eopts)
      endif
    else
      let all_opts = a:prepend ? [a:eopts, a:dict.options] : [a:dict.options, a:eopts]
      let a:dict.options = join(map(all_opts, 'type(v:val) == s:TYPE.list ? join(map(copy(v:val), "fzf#shellescape(v:val)")) : v:val'))
    endif
  else
    let a:dict.options = a:eopts
  endif
endfunction

function! s:merge_opts(dict, eopts)
  return s:extend_opts(a:dict, a:eopts, 0)
endfunction

function! s:prepend_opts(dict, eopts)
  return s:extend_opts(a:dict, a:eopts, 1)
endfunction

" [[options to wrap], [preview window expression], [toggle-preview keys...]]
function! fzf#devicon#vim#with_preview(...)
  " Default options
  let options = {}
  let window = 'right'

  let args = copy(a:000)

  " Options to wrap
  if len(args) && type(args[0]) == s:TYPE.dict
    let options = copy(args[0])
    call remove(args, 0)
  endif

  " Placeholder expression (TODO/TBD: undocumented)
  let placeholder = get(options, 'placeholder', '{}')

  " Preview window
  if len(args) && type(args[0]) == s:TYPE.string
    if args[0] !~# '^\(up\|down\|left\|right\)'
      throw 'invalid preview window: '.args[0]
    endif
    let window = args[0]
    call remove(args, 0)
  endif

  let preview = ['--preview-window', window, '--preview', (s:is_win ? s:bin.preview : fzf#shellescape(s:bin.preview)).' '.placeholder]

  if len(args)
    call extend(preview, ['--bind', join(map(args, 'v:val.":toggle-preview"'), ',')])
  endif
  call s:merge_opts(options, preview)
  return options
endfunction

function! s:remove_layout(opts)
  for key in s:layout_keys
    if has_key(a:opts, key)
      call remove(a:opts, key)
    endif
  endfor
  return a:opts
endfunction

function! s:reverse_list(opts)
  let tokens = map(split($FZF_DEFAULT_OPTS, '[^a-z-]'), 'substitute(v:val, "^--", "", "")')
  if index(tokens, 'reverse') < 0
    return extend(['--layout=reverse-list'], a:opts)
  endif
  return a:opts
endfunction

function! s:wrap(name, opts, bang)
  " fzf#wrap does not append --expect if sink or sink* is found
  let opts = copy(a:opts)
  let options = ''
  if has_key(opts, 'options')
    let options = type(opts.options) == s:TYPE.list ? join(opts.options) : opts.options
  endif
  if options !~? '--expect' && has_key(opts, 'sink*')
    let Sink = remove(opts, 'sink*')
    let wrapped = fzf#wrap(a:name, opts, a:bang)
    let wrapped['sink*'] = Sink
  else
    let wrapped = fzf#wrap(a:name, opts, a:bang)
  endif
  return wrapped
endfunction

function! s:strip(str)
  return substitute(a:str, '^\s*\|\s*$', '', 'g')
endfunction

function! s:chomp(str)
  return substitute(a:str, '\n*$', '', 'g')
endfunction

function! s:escape(path)
  let path = fnameescape(a:path)
  return s:is_win ? escape(path, '$') : path
endfunction

if v:version >= 704
  function! s:function(name)
    return function(a:name)
  endfunction
else
  function! s:function(name)
    " By Ingo Karkat
    return function(substitute(a:name, '^s:', matchstr(expand('<sfile>'), '<SNR>\d\+_\zefunction$'), ''))
  endfunction
endif

function! s:get_color(attr, ...)
  let gui = has('termguicolors') && &termguicolors
  let fam = gui ? 'gui' : 'cterm'
  let pat = gui ? '^#[a-f0-9]\+' : '^[0-9]\+$'
  for group in a:000
    let code = synIDattr(synIDtrans(hlID(group)), a:attr, fam)
    if code =~? pat
      return code
    endif
  endfor
  return ''
endfunction

let s:ansi = {'black': 30, 'red': 31, 'green': 32, 'yellow': 33, 'blue': 34, 'magenta': 35, 'cyan': 36}

function! s:csi(color, fg)
  let prefix = a:fg ? '38;' : '48;'
  if a:color[0] ==# '#'
    return prefix.'2;'.join(map([a:color[1:2], a:color[3:4], a:color[5:6]], 'str2nr(v:val, 16)'), ';')
  endif
  return prefix.'5;'.a:color
endfunction

function! s:ansi(str, group, default, ...)
  let fg = s:get_color('fg', a:group)
  let bg = s:get_color('bg', a:group)
  let color = (empty(fg) ? s:ansi[a:default] : s:csi(fg, 1)) .
        \ (empty(bg) ? '' : ';'.s:csi(bg, 0))
  return printf("\x1b[%s%sm%s\x1b[m", color, a:0 ? ';1' : '', a:str)
endfunction

for s:color_name in keys(s:ansi)
  execute 'function! s:'.s:color_name."(str, ...)\n"
        \ "  return s:ansi(a:str, get(a:, 1, ''), '".s:color_name."')\n"
        \ 'endfunction'
endfor

function! s:buflisted()
  return filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&filetype") !=? "qf"')
endfunction

function! s:fzf(name, opts, extra)
  let [extra, bang] = [{}, 0]
  if len(a:extra) <= 1
    let first = get(a:extra, 0, 0)
    if type(first) == s:TYPE.dict
      let extra = first
    else
      let bang = first
    endif
  elseif len(a:extra) == 2
    let [extra, bang] = a:extra
  else
    throw 'invalid number of arguments'
  endif

  let eopts  = has_key(extra, 'options') ? remove(extra, 'options') : ''
  let merged = extend(copy(a:opts), extra)
  call s:merge_opts(merged, eopts)
  return fzf#run(s:wrap(a:name, merged, bang))
endfunction

let s:default_action = {
  \ 'ctrl-t': 'tab split',
  \ 'ctrl-x': 'split',
  \ 'ctrl-v': 'vsplit' }

function! s:action_for(key, ...)
  let default = a:0 ? a:1 : ''
  let Cmd = get(get(g:, 'fzf_action', s:default_action), a:key, default)
  return type(Cmd) == s:TYPE.string ? Cmd : default
endfunction

function! s:open(cmd, target)
  if stridx('edit', a:cmd) == 0 && fnamemodify(a:target, ':p') ==# expand('%:p')
    return
  endif
  execute a:cmd s:escape(a:target)
endfunction

function! s:warn(message)
  echohl WarningMsg
  echom a:message
  echohl None
  return 0
endfunction

function! s:fill_quickfix(list, ...)
  if len(a:list) > 1
    call setqflist(a:list)
    copen
    wincmd p
    if a:0
      execute a:1
    endif
  endif
endfunction

" ------------------------------------------------------------------
" Devicon Common
" ------------------------------------------------------------------

" The follow was copied from the `fzf` plugin. It is declared there (and here)
" with a script scope so we don't have direct access to it
function! s:fzf_expand(fmt)
  return s:fzf_call('expand', a:fmt, 1)
endfunction
function! s:devicon_common_sink(action, lines) abort
  if len(a:lines) < 2
    return
  endif
  let key = remove(a:lines, 0)
  let Cmd = get(a:action, key, 'e')

  " This is there devicon stripping happens
  " It is AFTER we grab the first item as the key as this allows
  " actions to work correctly
  let lines = map(a:lines, "join(split(v:val, ' ')[1:], '')")

  if type(Cmd) == type(function('call'))
    return Cmd(lines)
  endif
  if len(lines) > 1
    augroup fzf_swap
      autocmd SwapExists * let v:swapchoice='o'
            \| call s:warn('fzf: E325: swap file exists: '.s:fzf_expand('<afile>'))
    augroup END
  endif
  try
    let empty = empty(s:fzf_expand('%')) && line('$') == 1 && empty(getline(1)) && !&modified
    let autochdir = &autochdir
    set noautochdir
    for item in lines
      if empty
        execute 'e' s:escape(item)
        let empty = 0
      else
        call s:open(Cmd, item)
      endif
      if !has('patch-8.0.0177') && !has('nvim-0.2') && exists('#BufEnter')
            \ && isdirectory(item)
        doautocmd BufEnter
      endif
    endfor
  catch /^Vim:Interrupt$/
  finally
    let &autochdir = autochdir
    silent! autocmd! fzf_swap
  endtry
endfunction

" ------------------------------------------------------------------
" Files - Modified with Devicons
" ------------------------------------------------------------------
function! s:shortpath()
  let short = fnamemodify(getcwd(), ':~:.')
  if !has('win32unix')
    let short = pathshorten(short)
  endif
  let slash = (s:is_win && !&shellslash) ? '\' : '/'
  return empty(short) ? '~'.slash : short . (short =~ escape(slash, '\').'$' ? '' : slash)
endfunction

function! fzf#devicon#vim#files(dir, ...)
  if !executable('devicon-lookup')
    return s:warn('devicon-lookup is not found. It can be installed with `cargo install devicon-lookup`')
  endif

  let args = {}
  if !empty(a:dir)
    if !isdirectory(expand(a:dir))
      return s:warn('Invalid directory')
    endif
    let slash = (s:is_win && !&shellslash) ? '\\' : '/'
    let dir = substitute(a:dir, '[/\\]*$', slash, '')
    let args.dir = dir
  else
    let dir = s:shortpath()
  endif

  let args.options = ['-m', '--ansi', '--prompt', strwidth(dir) < &columns / 2 - 20 ? dir : '> ']
  let args.source = $FZF_DEFAULT_COMMAND.' | devicon-lookup'

  let args._action = get(g:, 'fzf_action', s:default_action)
  let args.options = ' --expect='.join(keys(args._action), ',')
  function! args.sink(lines) abort
    return s:devicon_common_sink(self._action, a:lines)
  endfunction
  let args['sink*'] = remove(args, 'sink')

  return s:fzf('files', args, a:000)
endfunction

" ------------------------------------------------------------------
" Locate - Modified with Devicons
" ------------------------------------------------------------------
function! fzf#devicon#vim#locate(query, ...)
  if !executable('devicon-lookup')
    return s:warn('devicon-lookup is not found. It can be installed with `cargo install devicon-lookup`')
  endif

  let args = {}

  let args.source = 'locate '.a:query.' | devicon-lookup'
  let args.options = '-m --prompt "Locate> "'

  function! args.sink(lines) abort
    return s:devicon_common_sink(self._action, a:lines)
  endfunction
  let args['sink*'] = remove(args, 'sink')

  return s:fzf('locate', args, a:000)
endfunction

" ------------------------------------------------------------------
" GFiles[?] - Modified with Devicons
" ------------------------------------------------------------------
function! s:get_git_root()
  let root = split(system('git rev-parse --show-toplevel'), '\n')[0]
  return v:shell_error ? '' : root
endfunction

function! fzf#devicon#vim#gitfiles(args, ...)
  if !executable('devicon-lookup')
    return s:warn('devicon-lookup is not found. It can be installed with `cargo install devicon-lookup`')
  endif

  let root = s:get_git_root()
  if empty(root)
    return s:warn('Not in git repo')
  endif
  if a:args !=# '?'
    let args = {}

    let args.source = 'git ls-files '.a:args.(s:is_win ? '' : ' | uniq').' | devicon-lookup'
    let args.dir = root
    let args.options = '-m --prompt "GitFiles> "'

    function! args.sink(lines) abort
      return s:devicon_common_sink(self._action, a:lines)
    endfunction
    let args['sink*'] = remove(args, 'sink')

    return s:fzf('gfiles', args, a:000)
  endif

  " Here be dragons!
  " We're trying to access the common sink function that fzf#wrap injects to
  " the options dictionary.
  let wrapped = fzf#wrap({
  \ 'source':  'git -c color.status=always status --short --untracked-files=all | devicon-lookup',
  \ 'dir':     root,
  \ 'options': ['--ansi', '--multi', '--nth', '2..,..', '--tiebreak=index', '--prompt', 'GitFiles?> ', '--preview', 'sh -c "(git diff --color=always -- {-1} | sed 1,4d; cat {-1}) | head -500"']
  \})
  call s:remove_layout(wrapped)
  let wrapped.common_sink = remove(wrapped, 'sink*')
  function! wrapped.newsink(lines)
    let lines = extend(a:lines[0:0], map(a:lines[1:], 'substitute(v:val[3:], ".* -> ", "", "")'))
    return s:devicon_common_sink(self._action, lines)
  endfunction
  let wrapped['sink*'] = remove(wrapped, 'newsink')
  return s:fzf('gfiles-diff', wrapped, a:000)
endfunction

" ------------------------------------------------------------------
" Ag / Rg - TODO: Required devicon-lookup changes to support regex for
" filename
"
" These are correctly prefixed just don't do anything new yet
" ------------------------------------------------------------------
function! s:ag_to_qf(line, has_column)
  let parts = split(a:line, '[^:]\zs:\ze[^:]')
  let text = join(parts[(a:has_column ? 3 : 2):], ':')
  let dict = {'filename': &autochdir ? fnamemodify(parts[0], ':p') : parts[0], 'lnum': parts[1], 'text': text}
  if a:has_column
    let dict.col = parts[2]
  endif
  return dict
endfunction

function! s:ag_handler(lines, has_column)
  if len(a:lines) < 2
    return
  endif

  let cmd = s:action_for(a:lines[0], 'e')
  let list = map(filter(a:lines[1:], 'len(v:val)'), 's:ag_to_qf(v:val, a:has_column)')
  if empty(list)
    return
  endif

  let first = list[0]
  try
    call s:open(cmd, first.filename)
    execute first.lnum
    if a:has_column
      execute 'normal!' first.col.'|'
    endif
    normal! zz
  catch
  endtry

  call s:fill_quickfix(list)
endfunction

function! s:devicon_grep_sink(items, has_column)
  let items = map(a:items, "join(split(v:val, ' ')[1:], '')")

  call s:ag_handler(items, a:has_column)
endfunction

" query, [[ag options], options]
function! fzf#devicon#vim#ag(query, ...)
  if type(a:query) != s:TYPE.string
    return s:warn('Invalid query argument')
  endif
  let query = empty(a:query) ? '^(?=.)' : a:query
  let args = copy(a:000)
  let ag_opts = len(args) > 1 && type(args[0]) == s:TYPE.string ? remove(args, 0) : ''
  let command = ag_opts . ' ' . fzf#shellescape(query)
  return call('fzf#vim#ag_raw', insert(args, command, 0))
endfunction

" ag command suffix, [options]
function! fzf#devicon#vim#ag_raw(command_suffix, ...)
  if !executable('ag')
    return s:warn('ag is not found')
  endif
  return call('fzf#devicon#vim#grep', extend(['ag --nogroup --column --color '.a:command_suffix, 1], a:000))
endfunction

" command (string), has_column (0/1), [options (dict)], [fullscreen (0/1)]
function! fzf#devicon#vim#grep(grep_command, has_column, ...)
  if !executable('devicon-lookup')
    return s:warn('devicon-lookup is not found. It can be installed with `cargo install devicon-lookup`')
  endif

  let words = []
  for word in split(a:grep_command)
    if word !~# '^[a-z]'
      break
    endif
    call add(words, word)
  endfor
  let words   = empty(words) ? ['grep'] : words
  let name    = join(words, '-')
  let capname = join(map(words, 'toupper(v:val[0]).v:val[1:]'), '')
  let opts = {
  \ 'column':  a:has_column,
  \ 'source':  a:grep_command.' | devicon-lookup --color --prefix :',
  \ 'options': ['--ansi', '--prompt', capname.'> ',
  \             '--multi', '--bind', 'alt-a:select-all,alt-d:deselect-all',
  \             '--color', 'hl:4,hl+:12']
  \}
  function! opts.sink(lines)
    return s:devicon_grep_sink(a:lines, self.column)
  endfunction
  let opts['sink*'] = remove(opts, 'sink')
  return s:fzf(name, opts, a:000)
endfunction

" ------------------------------------------------------------------
let &cpoptions = s:cpo_save
unlet s:cpo_save

