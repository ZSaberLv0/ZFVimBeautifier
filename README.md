# ZFVimBeautifier

vim script to beautifier plain text or source code by regexp


# WARNING

this plugin format your code by plain regexp,
without any syntax check

it's designed for quick view some dirty code,
designed for lightweight (no need to install other command line tools or config IDE env)

i'm trying hard to make the format step won't break your code logic,
but it's not ensured, use with caution


# how to use

1. use [Vundle](https://github.com/VundleVim/Vundle.vim) or any other plugin manager you like to install

    ```
    Plugin 'othree/eregex.vim'
    Plugin 'ZSaberLv0/ZFVimBeautifier'
    Plugin 'ZSaberLv0/ZFVimBeautifierTemplate'
    ```

    for supported `filetype`s, see [ZFVimBeautifierTemplate](https://github.com/ZSaberLv0/ZFVimBeautifierTemplate)

1. use the function to beautify your current buffer

    ```
    call ZFBeautifier()
    ```

    or, explicitly specify the setting

    ```
    call ZFBeautifier('json', 't:mytemplate')
    ```

    no range support, whole buffer would be processed

# config

* `g:ZFBeautifierSetting`

    main setting of all format options, see format options below

* `let g:ZFBeautifier_autoSetFiletype = 1`

    whether automatically try to update `filetype` when `call ZFBeautifier()`

# format options

all format options are store in `g:ZFBeautifierSetting`, it contains these configs

    ```
    let g:ZFBeautifierSetting['myfiletype'] = {
        \     template : ['t0', 't1'],
        \     templatePost : [],
        \     escape : ['escape0', 'escape1'],
        \     replace : [
        \         ['from0', 'to0'],
        \         ['from1', 'to1'],
        \         ['', 'escape'],
        \     ],
        \     replacePost : [],
        \     func : ['funcNameToCall'],
        \     funcPost : [],
        \     command : ['vim command to call'],
        \     commandPost : [],
        \     updateIndent : 0,
        \     preserveEmptyLineNum : -1,
        \ }
    ```

* `myfiletype` : `filetype` or any string

    can be used in `ZFBeautifier('myfiletype')`

    if none of these type found, `t:default` would be applied

    empty string is considered same as `t:default`

* `template`/`templatePost` : `List` of any string that refer to any of `myfiletype`

    when specified, the referenced config would be appended to current config

    the `xxxPost` means it would be processed after the original `xxx` process finished

* `escape` : `List` of regexp to escape before format

    NOTE: we use `othree/eregex.vim` to substitute,
    which is perl style regexp, instead of vim style

* `replace`/`replacePost` : `List` of each replace regexp pattern

    each pattern would be applied by `othree/eregex.vim`'s `:%S` command

    if `from` is empty, `to` would be used to `escape` during replace phase

* `func`/`funcPost` : vim function name to call

    the function's proto type:

    ```
    " line : text of line
    " iLine : index of line, range in [1, line('$')]
    " setting : current setting
    function! Callback(line, iLine, setting)
        return a:line
    endfunction
    ```

    during format, the function would be called for each line in buffer,
    after applying your custom format steps,
    you must return the modified line

* `command`/`commandPost` : vim command to call
* `updateIndent` : whether update indent after format

    when any of config specify this value as non-zero,
    the indent would be applied

* `preserveEmptyLineNum` : keep how many empty lines

    if there are more than one config specified this value,
    the smallest one would be used

    `-1` means not to trim empty lines,
    `0` means trim all empty lines

