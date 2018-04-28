" ZFVimBeautifier.vim - vim script to beautifier code by plain regexp
" Author:  ZSaberLv0 <http://zsaber.com/>

let g:ZFBeautifier_loaded=1


" filetype : {
"     template : ['t0', 't1'],
"     templatePost : [],
"     escape : ['escape0', 'escape1'],
"     replace : [
"         ['from0', 'to0'],
"         ['from1', 'to1'],
"         ['', 'escape'],
"     ],
"     replacePost : [],
"     func : ['funcNameToCall'],
"     funcPost : [],
"     command : ['vim command to call'],
"     commandPost : [],
"     updateIndent : 0 or 1,
"     preserveEmptyLineNum : number of empty lines to preserve, -1 to disable,
" }
if !exists('g:ZFBeautifierSetting')
    let g:ZFBeautifierSetting = {}
endif

if !exists('g:ZFBeautifier_autoSetFiletype')
    let g:ZFBeautifier_autoSetFiletype = 1
endif

function! ZFBeautifier(...)
    let searchSaved = @/

    if a:0 > 0
        call s:setFileType(a:1)
    else
        if &filetype == ''
            call s:setFileType(expand('%:e'))
        endif
    endif

    let setting = s:getSetting(a:000)
    call s:processEscape(setting)
    call s:processCommand(setting)
    call s:processFunc(setting)
    call s:processReplace(setting)
    call s:processReplacePost(setting)
    call s:processFuncPost(setting)
    call s:processCommandPost(setting)
    call s:processIndent(setting)
    call s:processEmptyLine(setting)
    call s:processEscapeRestore(setting)

    let @/ = searchSaved
endfunction

function! ZFBeautifierShowSetting(...)
    echo s:getSetting(a:000)
endfunction

function! ZFBeautifierGetSetting(...)
    return s:getSetting(a:000)
endfunction

function! s:setFileType(name)
    if g:ZFBeautifier_autoSetFiletype && match(a:name, '[^a-z0-9_]') == -1
        execute 'set filetype=' . a:name
    endif
endfunction
function! s:getSetting(params)
    let nameList = []
    if len(a:params) > 0
        for item in a:params
            if item == ''
                call add(nameList, 't:default')
            else
                call add(nameList, item)
            endif
        endfor
    else
        call add(nameList, &filetype)
    endif

    return s:updateSetting(nameList)
endfunction


function! s:updateSetting(nameList)
    let exist = 0
    for name in a:nameList
        if exists('g:ZFBeautifierSetting[name]')
            let exist = 1
            break
        endif
    endfor
    if !exist
        call insert(a:nameList, 't:default', 0)
    endif

    let setting = {
                \     'template' : copy(a:nameList),
                \     'templatePost' : [],
                \     'escape' : [],
                \     'replace' : [],
                \     'replacePost' : [],
                \     'func' : [],
                \     'funcPost' : [],
                \     'command' : [],
                \     'commandPost' : [],
                \     'updateIndent' : 0,
                \     'preserveEmptyLineNum' : -1,
                \ }
    let applied = []

    for name in a:nameList
        while len(setting['template']) > 0 || len(setting['templatePost']) > 0
            if len(setting['template']) > 0
                let name = setting['template'][len(setting['template']) - 1]
                call remove(setting['template'], len(setting['template']) - 1)
                let isPost = 0
            else
                let name = setting['templatePost'][0]
                call remove(setting['templatePost'], 0)
                let isPost = 1
            endif
            if name == ''
                let name = 't:default'
            endif

            let alreadyApplied = 0
            for t in applied
                if t == name
                    let alreadyApplied = 1
                    break
                endif
            endfor
            if alreadyApplied
                continue
            endif

            call add(applied, name)

            if exists('g:ZFBeautifierSetting[name]')
                call s:updateSettingFromTemplate(setting, g:ZFBeautifierSetting[name], isPost)
            endif
        endwhile
    endfor

    return setting
endfunction
function! s:extend(list, ext, isPost)
    if a:isPost
        call extend(a:list, a:ext)
    else
        call extend(a:list, a:ext, 0)
    endif
endfunction
function! s:updateSettingFromTemplate(setting, template, isPost)
    let setting = a:setting
    let template = a:template

    if exists('template["template"]')
        call s:extend(setting['template'], template['template'], a:isPost)
    endif
    if exists('template["templatePost"]')
        call s:extend(setting['templatePost'], template['templatePost'], a:isPost)
    endif

    if exists('template["escape"]')
        call s:extend(setting['escape'], template['escape'], a:isPost)
    endif

    if exists('template["replace"]')
        call s:extend(setting['replace'], template['replace'], a:isPost)
    endif
    if exists('template["replacePost"]')
        call s:extend(setting['replacePost'], template['replacePost'], a:isPost)
    endif

    if exists('template["func"]')
        call s:extend(setting['func'], template['func'], a:isPost)
    endif
    if exists('template["funcPost"]')
        call s:extend(setting['funcPost'], template['funcPost'], a:isPost)
    endif

    if exists('template["command"]')
        call s:extend(setting['command'], template['command'], a:isPost)
    endif
    if exists('template["commandPost"]')
        call s:extend(setting['commandPost'], template['commandPost'], a:isPost)
    endif

    if exists('template["updateIndent"]') && template['updateIndent']
        let setting['updateIndent'] = 1
    endif

    if exists('template["preserveEmptyLineNum"]') && template['preserveEmptyLineNum'] >= 0
        if setting['preserveEmptyLineNum'] < 0 || template['preserveEmptyLineNum'] < setting['preserveEmptyLineNum']
            let setting['preserveEmptyLineNum'] = template['preserveEmptyLineNum']
        endif
    endif
endfunction

let s:escapeL = 'ZFVBtl'
let s:escapeR = 'ZFVBtr'
function! s:escape(iLine, escape)
    let line = getline(a:iLine)
    let pos = match(line, a:escape)
    let str = matchstr(line, a:escape)
    if pos <= 0
        return
    endif

    let t = s:base64_encode(str)
    let t = substitute(t, '+', 'ZFVBPlus', 'g')
    let t = substitute(t, '/', 'ZFVBSlash', 'g')
    let t = substitute(t, '=', 'ZFVBEqual', 'g')
    call setline(a:iLine, strpart(line, 0, pos) . s:escapeL . t . s:escapeR . strpart(line, len(str)))
endfunction
function! s:processEscape(setting)
    if len(a:setting['escape']) > 0
        for iLine in range(1, line('$'))
            for escape in a:setting['escape']
                call s:escape(iLine, escape)
            endfor
        endfor
    endif
endfunction

function! s:processEscapeRestore(setting)
    for iLine in range(1, line('$'))
        let line = getline(iLine)
        let pos = match(line, s:escapeL . '.*' . s:escapeR, 'g')
        let str = matchstr(line, s:escapeL . '.*' . s:escapeR, 'g')
        if pos <= 0
            continue
        endif

        let t = strpart(str, len(s:escapeL), len(str) - len(s:escapeL) - len(s:escapeR))
        let t = substitute(t, 'ZFVBPlus', '+', 'g')
        let t = substitute(t, 'ZFVBSlash', '/', 'g')
        let t = substitute(t, 'ZFVBEqual', '=', 'g')
        let t = s:base64_decode(t)
        call setline(iLine, strpart(line, 0, pos) . t . strpart(line, len(str)))
    endfor
endfunction

function! s:replace(from, to)
    if len(a:from) <= 0
        for iLine in range(1, line('$'))
            call s:escape(iLine, a:to)
        endfor
    else
        execute ':silent! %S/' . a:from . '/' . a:to . '/g'
    endif
endfunction
function! s:processReplace(setting)
    for replace in a:setting['replace']
        call s:replace(replace[0], replace[1])
    endfor
endfunction
function! s:processReplacePost(setting)
    for replace in a:setting['replacePost']
        call s:replace(replace[0], replace[1])
    endfor
endfunction

function! s:processFunc(setting)
    for func in a:setting['func']
        for iLine in range(1, line('$'))
            let line = getline(iLine)
            execute 'let line = ' . func . '(line, iLine, a:setting)'
            call setline(iLine, line)
        endfor
    endfor
endfunction
function! s:processFuncPost(setting)
    for func in a:setting['funcPost']
        for iLine in range(1, line('$'))
            let line = getline(iLine)
            execute 'let line = ' . func . '(line, iLine, a:setting)'
            call setline(iLine, line)
        endfor
    endfor
endfunction

function! s:processCommand(setting)
    for command in a:setting['command']
        execute command
    endfor
endfunction
function! s:processCommandPost(setting)
    for command in a:setting['commandPost']
        execute command
    endfor
endfunction

function! s:processIndent(setting)
    if a:setting['updateIndent']
        normal! gg=G
    endif
endfunction

function! s:processEmptyLine(setting)
    if a:setting['preserveEmptyLineNum'] >= 0
        let n = a:setting['preserveEmptyLineNum']
        let t = '\r'
        for i in range(n)
            let t .= '\r'
        endfor
        execute ':silent! %S/\n([ \t]*\n){' . (n + 1) . ',}/' . t . '/g'
    endif
endfunction

function! s:base64_encode(str)
python << python_base64
import string
import base64
import vim
str = vim.eval("a:str")
result = base64.b64encode(str)
vim.command("let l:result='%s'"% result)
python_base64
    return l:result
endfunction
function! s:base64_decode(str)
python << python_base64
import string
import base64
import vim
str = vim.eval("a:str")
result = base64.b64decode(str)
vim.command("let l:result='%s'"% result)
python_base64
    return l:result
endfunction

