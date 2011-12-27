" File:        shelp.vim
" Author:      Jia Wei (ayheos@gmail.com)
" Last Change: Dec 13, 2011
" Version:     0.9.1
" License:      GPL.
"=============================================================================
" Utilities to run all kinds of shell
" See documentation in accompanying help file

scriptencoding gbk 

let s:cpo_save = &cpo
set cpo&vim

if exists("g:shelp_flag")
    finish "stop loading the script
endif
let g:shelp_flag = expand('<sfile>')

" Add the popup menu.
amenu .600 PopUp.-Sep-    :
"important! not delete below
"==========================================================================
"dynamic-insert-menu-here
"==========================================================================

" Add the toolbar icon.
" an .600 ToolBar.-sep-		<Nop>
"==========================================================================
"dynamic-insert-toolbar-here
"==========================================================================


func <SID>IsExists(type)
    let pattern = "/^" . escape(a:type,'\') . "$/j"
    silent! exe 'silent! 1vimgrep '.pattern.' '.g:shelp_flag
    redi @s>
        silent! cl -1
    redi end

    if @s =~ escape(a:type,'\')
        return 0 
    else
        return -1
    endif
endfun

func <SID>DynamicMenuIns()
    let flag = escape('"dynamic-insert-menu-here','"')
    let shell = inputdialog('Add New Shell Command(Nothing Just Ignore):','','')
    if shell == ''
        return
    endif

    if <SID>NameCheck(shell) == -1
        echoerr "the same item is there!"
        return
    endif

    let newmenu = 'an <silent> .600 PopUp.Run\ '.shell.'(&R) :call <SID>RunMe("'.shell.'")<CR>'
    let retcode = <SID>IsExists(newmenu)
    if retcode == 0
        return
    endif

    let importantInfo = "%s/^".flag."$/".flag
    exe "echo system('vim -e -c \"".importantInfo."\\r".escape(newmenu,'()\&:"')."/\" -c \"wq\" ".g:shelp_flag."')"
    
    exe newmenu
endfun

func <SID>DynamicMenuDel()
    let shell = inputdialog('Delelt Old Shell Command(Nothing Just Ignore):','','')
    if shell == ''
        return
    endif

    if <SID>NameCheck(shell) == -1
        return
    endif

    let oldmenu = 'an <silent> .600 PopUp.Run\ '.shell.'(&R) :call <SID>RunMe("'.shell.'")<CR>'
    let retcode = <SID>IsExists(oldmenu)
    if retcode == -1
        return
    endif

    let importantInfo = "/^".escape(oldmenu,'\:"')."$"
    exe "echo system('vim -e -c \"".importantInfo."\" -c \"d\" -c \"wq\" ".g:shelp_flag."')"

    exe 'aun <silent> .600 PopUp.Run\ '.shell.'(&R)'
endfun


func <SID>DynamicToolBarIns()
    let shell = inputdialog('Add New Shell Command On Toolbar(Nothing Just Ignore):','','')
    if shell == ''
        return
    endif

    if <SID>NameCheck(shell) == -1
        return
    endif

    let newtb = 'an .600 ToolBar.* :call <SID>RunMe("'.shell.'")<CR>|tmenu ToolBar.* :'.shell
    let retcode = <SID>IsExists(newtb)
    if retcode == 0
        echoerr "the same item is there!"
        return
    endif
    
    if has('browse')
        let iconfile = browse(0, 'Select the Icon File(better if 18*18px): ', '', '')
        let iconfile = fnamemodify(iconfile, ':p')
    else
        let iconfile = inputdialog('Input the Icon File: ','','')
    endif

    if iconfile == '' || !filereadable(iconfile)
        let iconfile = inputdialog('Input the vim default Icon number(0-30): ','','')
        if iconfile == '' || (iconfile !~ "^[0-2][0-9]$" && iconfile != 30)
            return
        else
            let newtb = 'an .600 ToolBar.BuiltIn'.iconfile.' :call <SID>RunMe("'.shell.'")<CR>|tmenu ToolBar.BuiltIn'.iconfile.' :'.shell
        endif
    else
        let newtb = 'an .600 ToolBar.'.shell.' :call <SID>RunMe("'.shell.'")<CR>|tmenu ToolBar.'.shell.' :'.shell
        let icondir = $VIM . "/vimfiles/bitmaps"
        let icondir = <SID>SysPath(icondir)
        
        if !isdirectory(icondir)
            call mkdir(icondir, "p", 0700)
        endif

        if !isdirectory(icondir)
            echoerr "mkdir ".icondir." error,please create it manual!"
            return
        endif

        let icontype = <SID>SysIcon()
        let cpcode = <SID>SysCopy(iconfile,<SID>SysPath(icondir.'/'.shell.icontype))
        if cpcode == -1
            return
        endif
    endif


    let flag = escape('"dynamic-insert-toolbar-here','"')
    let importantInfo = "%s/^".flag."$/".flag
    exe "echo system('vim -e -c \"".importantInfo."\\r".escape(newtb,'()\&:"')."/\" -c \"wq\" ".g:shelp_flag."')"
    
    exe newtb
endfun

func <SID>DynamicToolBarDel()
    let shell = inputdialog('Delelt Old Shell Command On Toolbar(Nothing Just Ignore):','','')
    if shell == ''
        return
    endif

    if <SID>NameCheck(shell) == -1
        return
    endif

    ""let oldmenu = 'an .600 ToolBar.'.shell.' :'.shell.'<CR>|tmenu ToolBar.'.shell.' :'.shell
    let oldmenu = 'an .600 ToolBar.* :call <SID>RunMe("'.shell.'")<CR>|tmenu ToolBar.* :'.shell
    let retcode = <SID>IsExists(oldmenu)
    if retcode == -1
        return
    endif

    let spos = stridx(@s,"ToolBar.")
    let epos = stridx(@s," ",spos)
    let partmenu = strpart(@s,spos+8,epos-spos-8)

    let importantInfo = "/^".escape(oldmenu,'\:"')."$"
    exe "echo system('vim -e -c \"".importantInfo."\" -c \"d\" -c \"wq\" ".g:shelp_flag."')"

    exe 'aun .600 ToolBar.'.partmenu
endfun

func <SID>RunMe(type)
    let stype = ''
    if a:type[strlen(a:type)-1] == '!'
        let name = ''
        let stype = strpart(a:type,0,strlen(a:type)-1)
    else
        let name = inputdialog('Enter Input Args,split by space(Nothing Just Ignore):','','')
        let stype = a:type
    endif

    if name != ''
        "copy output to clipboard
        redi @+>
            let filename = bufname('%')
            if stype[0] == '!'
                exe "echo system('".strpart(stype,1)." ".filename." ".name."')"
            else
                exe stype." ".name
            endif
        redi end
    endif
endfun

func <SID>SysCopy(srcfile,destfile)
    if has("win32") || has("win95") || has("win64") || has("win16")
        silent exe '!copy '.escape(a:srcfile,"!").' '.escape(a:destfile,"!")
    else
        silent exe '!cp '.escape(a:srcfile,"!").' '.escape(a:destfile,"!")
    endif

    if !filereadable(a:destfile)
        echoerr "copy file ".a:srcfile." to destdir ".a:destfile." error,please copy it manual!"
        return -1
    else
        return 0
    endif
endfun

func <SID>SysPath(path)
    if has("win32") || has("win95") || has("win64") || has("win16")
        let path = substitute(a:path, '/', '\', 'g')
    endif

    return path
endfun

func <SID>SysIcon()
    if has("win32") || has("win95") || has("win64") || has("win16")
        return ".bmp"
    endif

    return ".xpm"
endfun

func <SID>NameCheck(name)
    if a:name !~? "^[!a-z0-9_-]*$"
        echoerr "your input must be alphanum or -_-"
        return -1
    endif
    return 0
endfun

if !hasmapto('<Plug>RM_RunmeInsert')
    nmap <silent> <unique> <Leader>ri <Plug>RM_RunmeInsert
endif
if !hasmapto('<Plug>RM_RunmeDelete')
    nmap <silent> <unique> <Leader>rd <Plug>RM_RunmeDelete
endif
nmap <silent> <unique> <script> <Plug>RM_RunmeInsert   :call <SID>DynamicMenuIns()<CR>
nmap <silent> <unique> <script> <Plug>RM_RunmeDelete   :call <SID>DynamicMenuDel()<CR>

if !hasmapto('<Plug>RM_Tb_RunmeInsert')
    nmap <silent> <unique> <Leader>rI <Plug>RM_Tb_RunmeInsert
endif
if !hasmapto('<Plug>RM_Tb_RunmeDelete')
    nmap <silent> <unique> <Leader>rD <Plug>RM_Tb_RunmeDelete
endif
nmap <silent> <unique> <script> <Plug>RM_Tb_RunmeInsert   :call <SID>DynamicToolBarIns()<CR>
nmap <silent> <unique> <script> <Plug>RM_Tb_RunmeDelete   :call <SID>DynamicToolBarDel()<CR>


" restore 'cpo'
let &cpo = s:cpo_save
unlet s:cpo_save

"vim:ft=vim:
