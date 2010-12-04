let s:save_cpo = &cpo
set cpo&vim

let s:source = { 'name': 'rhythmbox' }
let s:plfile = "'" . expand('<sfile>:p:h') . "/rhythmbox.pl'"
let s:songs = []

function! unite#sources#rhythmbox#toggle()
  call system('perl '.s:plfile.' --toggle')
endfunction

function! unite#sources#rhythmbox#play(id)
  call system('perl '.s:plfile.' --play '.s:songs[a:id].uri)
endfunction

function! s:source.gather_candidates(args, context)
  if index(a:args, '!') >= 0
    call unite#sources#rhythmbox#toggle()
  endif
  for line in split(system('perl '.s:plfile), "\n")
    let v = split(line, "\t")
    call add(s:songs, {
    \ "id": len(s:songs),
    \ "artist": v[0],
    \ "album":  v[1],
    \ "title":  v[2],
    \ "uri":    v[3]})
  endfor
  return map(copy(s:songs), '{
  \ "word": join([v:val.artist, v:val.album, v:val.title], '' - ''),
  \ "source": "rhythmbox",
  \ "kind": "command",
  \ "action__command": "call unite#sources#rhythmbox#play(''".v:val.id."'')"
  \ }')
endfunction

function! unite#sources#rhythmbox#define()
  return executable('perl') ? [s:source] : []
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
