%DEFINE VARIABLE 1
%DEFINE STRING_VAR 2
%DEFINE NUMBER 3
%DEFINE STRING 4
%DEFINE QUOTE 5
%DEFINE CHAR 6
%DEFINE UNKNOWN 7
%DEFINE LABEL 8

os_run_basic:
	mov word [orig_stack], sp		

	mov word [load_point], ax		

	mov word [prog], ax			

	add bx, ax				
	dec bx
	dec bx
	mov word [prog_end], bx			

	call clear_ram				

	cmp si, 0				
	je mainloop

	mov di, string_vars			
	call os_string_copy

mainloop:
	call get_token				

	cmp ax, STRING				
	je .keyword				

	cmp ax, VARIABLE			
	je near assign				

	cmp ax, STRING_VAR			
	je near assign

	cmp ax, LABEL				
	je mainloop

	mov si, err_syntax			
	jmp error

.keyword:
	mov si, token				

	mov di, alert_cmd
	call os_string_compare
	jc near do_alert

	mov di, askfile_cmd
	call os_string_compare
	jc near do_askfile

	mov di, call_cmd
	call os_string_compare
	jc near do_call

	mov di, cls_cmd
	call os_string_compare
	jc near do_cls

	mov di, cursor_cmd
	call os_string_compare
	jc near do_cursor

	mov di, curschar_cmd
	call os_string_compare
	jc near do_curschar

	mov di, curscol_cmd
	call os_string_compare
	jc near do_curscol

	mov di, curspos_cmd
	call os_string_compare
	jc near do_curspos

	mov di, delete_cmd
	call os_string_compare
	jc near do_delete

	mov di, do_cmd
	call os_string_compare
	jc near do_do

	mov di, end_cmd
	call os_string_compare
	jc near do_end

	mov di, for_cmd
	call os_string_compare
	jc near do_for

	mov di, getkey_cmd
	call os_string_compare
	jc near do_getkey

	mov di, gosub_cmd
	call os_string_compare
	jc near do_gosub

	mov di, goto_cmd
	call os_string_compare
	jc near do_goto

	mov di, if_cmd
	call os_string_compare
	jc near do_if

	mov di, include_cmd
	call os_string_compare
	jc near do_include

	mov di, ink_cmd
	call os_string_compare
	jc near do_ink

	mov di, input_cmd
	call os_string_compare
	jc near do_input

	mov di, len_cmd
	call os_string_compare
	jc near do_len

	mov di, listbox_cmd
	call os_string_compare
	jc near do_listbox

	mov di, load_cmd
	call os_string_compare
	jc near do_load

	mov di, loop_cmd
	call os_string_compare
	jc near do_loop

	mov di, move_cmd
	call os_string_compare
	jc near do_move

	mov di, next_cmd
	call os_string_compare
	jc near do_next

	mov di, number_cmd
	call os_string_compare
	jc near do_number

	mov di, page_cmd
	call os_string_compare
	jc near do_page

	mov di, pause_cmd
	call os_string_compare
	jc near do_pause

	mov di, peek_cmd
	call os_string_compare
	jc near do_peek

	mov di, peekint_cmd
	call os_string_compare
	jc near do_peekint

	mov di, poke_cmd
	call os_string_compare
	jc near do_poke

	mov di, pokeint_cmd
	call os_string_compare
	jc near do_pokeint

	mov di, port_cmd
	call os_string_compare
	jc near do_port

	mov di, print_cmd
	call os_string_compare
	jc near do_print

	mov di, rand_cmd
	call os_string_compare
	jc near do_rand

	mov di, read_cmd
	call os_string_compare
	jc near do_read

	mov di, rem_cmd
	call os_string_compare
	jc near do_rem

	mov di, rename_cmd
	call os_string_compare
	jc near do_rename

	mov di, return_cmd
	call os_string_compare
	jc near do_return

	mov di, save_cmd
	call os_string_compare
	jc near do_save

	mov di, serial_cmd
	call os_string_compare
	jc near do_serial

	mov di, size_cmd
	call os_string_compare
	jc near do_size

	mov di, sound_cmd
	call os_string_compare
	jc near do_sound

	mov di, string_cmd
	call os_string_compare
	jc near do_string

	mov di, waitkey_cmd
	call os_string_compare
	jc near do_waitkey

	mov si, err_cmd_unknown			
	jmp error

clear_ram:
	pusha
	mov al, 0

	mov di, variables
	mov cx, 52
	rep stosb

	mov di, for_variables
	mov cx, 52
	rep stosb

	mov di, for_code_points
	mov cx, 52
	rep stosb

	mov di, do_loop_store
	mov cx, 10
	rep stosb

	mov byte [gosub_depth], 0
	mov byte [loop_in], 0

	mov di, gosub_points
	mov cx, 20
	rep stosb

	mov di, string_vars
	mov cx, 1024
	rep stosb

	mov byte [ink_colour], 7		

	popa
	ret

assign:
	cmp ax, VARIABLE			
	je .do_num_var

	mov di, string_vars			
	mov ax, 128
	mul bx					
	add di, ax

	push di

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp ax, QUOTE
	je .second_is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars			
	mov ax, 128
	mul bx					
	add si, ax

	pop di
	call os_string_copy

	jmp mainloop

.second_is_quote:
	mov si, token
	pop di
	call os_string_copy

	jmp mainloop

.do_num_var:
	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_variable

	cmp ax, STRING
	je near .second_is_string

	cmp ax, UNKNOWN
	jne near .error

	mov byte al, [token]			
	cmp al, '&'
	jne near .error

	call get_token				
	cmp ax, STRING_VAR
	jne near .error

	mov di, string_vars
	mov ax, 128
	mul bx
	add di, ax

	mov bx, di

	mov byte al, [.tmp]
	call set_var

	jmp mainloop

.second_is_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more

.second_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax				

	mov ax, 0
	mov byte al, [.tmp]

	call set_var

.check_for_more:
	mov word ax, [prog]			
	mov word [.tmp_loc], ax

	call get_token				
	mov byte al, [token]
	cmp al, '+'
	je .theres_more
	cmp al, '-'
	je .theres_more
	cmp al, '*'
	je .theres_more
	cmp al, '/'
	je .theres_more
	cmp al, '%'
	je .theres_more

	mov word ax, [.tmp_loc]			
	mov word [prog], ax			

	jmp mainloop				

.theres_more:
	mov byte [.delim], al

	call get_token
	cmp ax, VARIABLE
	je .handle_variable

	mov si, token
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var				

	cmp byte [.delim], '+'
	jne .not_plus

	add ax, bx
	jmp .finish

.not_plus:
	cmp byte [.delim], '-'
	jne .not_minus

	sub ax, bx
	jmp .finish

.not_minus:
	cmp byte [.delim], '*'
	jne .not_times

	mul bx
	jmp .finish

.not_times:
	cmp byte [.delim], '/'
	jne .not_divide

	cmp bx, 0
	je .divide_zero

	mov dx, 0
	div bx
	jmp .finish

.not_divide:
	mov dx, 0
	div bx
	mov ax, dx				

.finish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more

.divide_zero:
	mov si, err_divide_by_zero
	jmp error

.handle_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var

	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var

	cmp byte [.delim], '+'
	jne .vnot_plus

	add ax, bx
	jmp .vfinish

.vnot_plus:
	cmp byte [.delim], '-'
	jne .vnot_minus

	sub ax, bx
	jmp .vfinish

.vnot_minus:
	cmp byte [.delim], '*'
	jne .vnot_times

	mul bx
	jmp .vfinish

.vnot_times:
	cmp byte [.delim], '/'
	jne .vnot_divide

	mov dx, 0
	div bx
	jmp .finish

.vnot_divide:
	mov dx, 0
	div bx
	mov ax, dx				

.vfinish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more

.second_is_string:				
	mov di, token

	mov si, ink_keyword
	call os_string_compare
	je .is_ink

	mov si, progstart_keyword
	call os_string_compare
	je .is_progstart

	mov si, ramstart_keyword
	call os_string_compare
	je .is_ramstart

	mov si, timer_keyword
	call os_string_compare
	je .is_timer

	mov si, version_keyword
	call os_string_compare
	je .is_version

	jmp .error

.is_ink:
	mov ax, 0
	mov byte al, [.tmp]

	mov bx, 0
	mov byte bl, [ink_colour]
	call set_var

	jmp mainloop

.is_progstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [load_point]
	call set_var

	jmp mainloop

.is_ramstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [prog_end]
	inc bx
	inc bx
	inc bx
	call set_var

	jmp mainloop

.is_timer:
	mov ah, 0
	int 1Ah
	mov bx, dx

	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop

.is_version:
	call os_get_api_version

	mov bh, 0
	mov bl, al
	mov al, [.tmp]
	call set_var

	jmp mainloop 

.error:
	mov si, err_syntax
	jmp error

	.tmp		db 0
	.tmp_loc	dw 0
	.delim		db 0

do_alert:
	mov bh, [work_page]			
	mov ah, 03h
	int 10h

	call get_token

	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	je .is_string

	mov si, err_syntax
	jmp error

.is_string:
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	jmp .display_message

.is_quote:
	mov ax, token				

.display_message:
	mov bx, 0				
	mov cx, 0
	mov dx, 0				
	call os_dialog_box

	mov bh, [work_page]			
	mov ah, 02h
	int 10h

	jmp mainloop

do_askfile:
	mov bh, [work_page]			
	mov ah, 03h
	int 10h

	call get_token

	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars			
	mov ax, 128
	mul bx
	add ax, si
	mov word [.tmp], ax

	call os_file_selector			

	mov word si, [.tmp]			
	mov di, ax
	call os_string_copy

	mov bh, [work_page]			
	mov ah, 02h
	int 10h

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.data:
	.tmp					dw 0

do_call:
	call get_token
	cmp ax, NUMBER
	je .is_number

	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .execute_call

.is_number:
	mov si, token
	call os_string_to_int

.execute_call:
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov di, 0
	mov si, 0

	call ax

	jmp mainloop

do_cls:
	mov ah, 5
	mov byte al, [work_page]
	int 10

	call os_clear_screen

	mov ah, 5
	mov byte al, [disp_page]
	int 10

	jmp mainloop

do_cursor:
	call get_token

	mov si, token
	mov di, .on_str
	call os_string_compare
	jc .turn_on

	mov si, token
	mov di, .off_str
	call os_string_compare
	jc .turn_off

	mov si, err_syntax
	jmp error

.turn_on:
	call os_show_cursor
	jmp mainloop

.turn_off:
	call os_hide_cursor
	jmp mainloop

	.on_str db "ON", 0
	.off_str db "OFF", 0

do_curschar:
	call get_token

	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax				

	mov ah, 08h
	mov bx, 0
	mov byte bh, [work_page]
	int 10h				

	mov bx, 0			
	mov bl, al

	pop ax				

	call set_var			

	jmp mainloop

do_curscol:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ah, 0
	mov byte al, [token]
	push ax

	mov ah, 8
	mov bx, 0
	mov byte bh, [work_page]
	int 10h
	mov bh, 0
	mov bl, ah			

	pop ax
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_curspos:
	mov byte bh, [work_page]
	mov ah, 3
	int 10h

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ah, 0			
	mov byte al, [token]
	mov bx, 0
	mov bl, dl
	call set_var

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ah, 0			
	mov byte al, [token]
	mov bx, 0
	mov bl, dh
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_delete:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_filename

.is_quote:
	mov si, token

.get_filename:
	mov ax, si
	call os_file_exists
	jc .no_file

	call os_remove_file
	jc .del_fail

	jmp .returngood

.no_file:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 2
	call set_var
	jmp mainloop

.returngood:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var
	jmp mainloop

.del_fail:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_do:
	cmp byte [loop_in], 10
	je .loop_max
	mov word di, do_loop_store
	mov byte al, [loop_in]
	mov ah, 0
	add di, ax
	mov si, di
	lodsw
	mov word ax, [prog]
	sub ax, 3
	stosw
	inc word [loop_in]
	inc word [loop_in]
	jmp mainloop

.loop_max:
	mov si, err_doloop_maximum
	jmp error

do_end:
	mov ah, 5				
	mov al, 0
	int 10h

	mov byte [work_page], 0
	mov byte [disp_page], 0

	mov word sp, [orig_stack]
	ret

do_for:
	call get_token				

	cmp ax, VARIABLE
	jne near .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al			

	call get_token

	mov ax, 0				
	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token				

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token				
	call os_string_to_int
	jmp .continue

.first_is_var:
	mov ax, 0				
	mov al, [token]
	call get_var

.continue:
	mov bx, ax
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var

	call get_token				

	cmp ax, STRING
	jne .error

	mov ax, token
	call os_string_uppercase

	mov si, token
	mov di, .to_string
	call os_string_compare
	jnc .error

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

.second_is_number:
	mov si, token					
	call os_string_to_int
	jmp .continue2

.second_is_var:
	mov ax, 0				
	mov al, [token]
	call get_var

.continue2:
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					
	mov di, for_variables
	add di, ax
	add di, ax
	mov ax, bx
	stosw

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					
	mov di, for_code_points
	add di, ax
	add di, ax
	mov word ax, [prog]
	stosw

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.tmp_var	db 0
	.to_string	db 'TO', 0

do_getkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_check_for_key

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed

.store:	
	mov bx, 0
	mov bl, al

	pop ax

	call set_var

	jmp mainloop

.up_pressed:
	mov ax, 1
	jmp .store

.down_pressed:
	mov ax, 2
	jmp .store

.left_pressed:
	mov ax, 3
	jmp .store

.right_pressed:
	mov ax, 4
	jmp .store

do_gosub:
	call get_token				

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	inc byte [gosub_depth]

	mov ax, 0
	mov byte al, [gosub_depth]		

	cmp al, 9
	jle .within_limit

	mov si, err_nest_limit
	jmp error

.within_limit:
	mov di, gosub_points			
	add di, ax				
	add di, ax
	mov word ax, [prog]
	stosw					

	mov word ax, [load_point]
	mov word [prog], ax			

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop

.line_loop:					
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error

	.tmp_token	times 30 db 0

do_goto:
	call get_token				

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	mov word ax, [load_point]
	mov word [prog], ax			

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop

.line_loop:					
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]

	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error

	.tmp_token 	times 30 db 0

do_if:
	call get_token

	cmp ax, VARIABLE			
	je .num_var

	cmp ax, STRING_VAR
	je near .string_var

	mov si, err_syntax
	jmp error

.num_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov dx, ax				

	call get_token				
	mov byte al, [token]
	cmp al, '='
	je .equals
	cmp al, '>'
	je .greater
	cmp al, '<'
	je .less

	mov si, err_syntax			
	jmp error

.equals:
	call get_token				

	cmp ax, CHAR
	je .equals_char

	mov byte al, [token]
	call is_letter
	jc .equals_var

	mov si, token				
	call os_string_to_int

	cmp ax, dx				
	je near .on_to_then

	jmp .finish_line			

.equals_char:
	mov ax, 0
	mov byte al, [token]

	cmp ax, dx
	je near .on_to_then

	jmp .finish_line

.equals_var:
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx				
	je near .on_to_then				

	jmp .finish_line			

.greater:
	call get_token				
	mov byte al, [token]
	call is_letter
	jc .greater_var

	mov si, token				
	call os_string_to_int

	cmp ax, dx
	jl near .on_to_then

	jmp .finish_line

.greater_var:					
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx				
	jl .on_to_then

	jmp .finish_line

.less:
	call get_token
	mov byte al, [token]
	call is_letter
	jc .less_var

	mov si, token
	call os_string_to_int

	cmp ax, dx
	jg .on_to_then

	jmp .finish_line

.less_var:
	mov ax, 0
	mov byte al, [token]

	call get_var

	cmp ax, dx
	jg .on_to_then

	jmp .finish_line

.string_var:
	mov byte [.tmp_string_var], bl

	call get_token

	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token
	cmp ax, STRING_VAR
	je .second_is_string_var

	cmp ax, QUOTE
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov di, token
	call os_string_compare
	je .on_to_then

	jmp .finish_line

.second_is_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov di, string_vars
	mov bx, 0
	mov byte bl, [.tmp_string_var]
	mov ax, 128
	mul bx
	add di, ax

	call os_string_compare
	jc .on_to_then

	jmp .finish_line

.on_to_then:
	call get_token

	mov si, token			
	mov di, and_keyword
	call os_string_compare
	jc do_if

	mov si, token			
	mov di, then_keyword
	call os_string_compare
	jc .then_present

	mov si, err_syntax
	jmp error

.then_present:				
	jmp mainloop

.finish_line:				
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10
	jne .finish_line

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.tmp_string_var		db 0

do_include:
	call get_token
	cmp ax, QUOTE
	je .is_ok

	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, token
	mov word cx, [prog_end]
	inc cx				
	inc cx
	inc cx
	push cx
	call os_load_file
	jc .load_fail

	pop cx
	add cx, bx
	mov word [prog_end], cx

	jmp mainloop

.load_fail:
	pop cx
	mov si, err_file_notfound
	jmp error

do_ink:
	call get_token				

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov byte [ink_colour], al
	jmp mainloop

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov byte [ink_colour], al
	jmp mainloop

do_input:
	mov al, 0				
	mov di, .tmpstring
	mov cx, 128
	rep stosb

	call get_token

	cmp ax, VARIABLE			
	je .number_var

	cmp ax, STRING_VAR
	je .string_var

	mov si, err_syntax
	jmp error

.number_var:
	mov ax, .tmpstring			
	call os_input_string

	mov ax, .tmpstring
	call os_string_length
	cmp ax, 0
	jne .char_entered

	mov byte [.tmpstring], '0'		
	mov byte [.tmpstring + 1], 0

.char_entered:
	mov si, .tmpstring			
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]			
	call set_var				

	call os_print_newline

	jmp mainloop

.string_var:
	push bx

	mov ax, .tmpstring
	call os_input_string

	mov si, .tmpstring
	mov di, string_vars

	pop bx

	mov ax, 128
	mul bx

	add di, ax
	call os_string_copy

	call os_print_newline

	jmp mainloop

	.tmpstring	times 128 db 0

do_len:
	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov ax, si
	call os_string_length
	mov word [.num1], ax

	call get_token
	cmp ax, VARIABLE
	je .is_ok

	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, 0
	mov byte al, [token]
	mov bl, al
	jmp .finish

.finish:	
	mov bx, [.num1]
	mov byte al, [token]
	call set_var
	mov ax, 0
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.num1 dw 0

do_listbox:
	mov bh, [work_page]			
	mov ah, 03h
	int 10h

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s1], si

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s2], si

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s3], si

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.var], al

	mov word ax, [.s1]
	mov word bx, [.s2]
	mov word cx, [.s3]

	call os_list_dialog
	jc .esc_pressed

	pusha
	mov bh, [work_page]			
	mov ah, 02h
	int 10h
	popa

	mov bx, ax
	mov ax, 0
	mov byte al, [.var]
	call set_var

	jmp mainloop

.esc_pressed:
	mov ax, 0
	mov byte al, [.var]
	mov bx, 0
	call set_var
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.s1 dw 0
	.s2 dw 0
	.s3 dw 0
	.var db 0

do_load:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov ax, si
	call os_file_exists
	jc .file_not_exists

	mov dx, ax			

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.load_part:
	mov cx, ax

	mov ax, dx

	call os_load_file

	mov ax, 0
	mov byte al, 'S'
	call set_var

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .load_part

.file_not_exists:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	call get_token				

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_loop:
	cmp byte [loop_in], 0
	je .no_do

	dec word [loop_in]
	dec word [loop_in]

	mov dx, 0

	call get_token
	mov di, token

	mov si, .endless_word
	call os_string_compare
	jc .loop_back

	mov si, .while_word
	call os_string_compare
	jc .while_set

	mov si, .until_word
	call os_string_compare
	jnc .error

.get_first_var:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov al, [token]
	call get_var
	mov cx, ax

.check_equals:
	call get_token
	cmp ax, UNKNOWN
	jne .error

	mov ax, [token]
	cmp al, '='
	je .sign_ok
	cmp al, '>'
	je .sign_ok
	cmp al, '<'
	je .sign_ok
	jmp .error
	.sign_ok:
	mov byte [.sign], al

.get_second_var:
 	call get_token

	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, CHAR
	jne .error

.second_is_char:
	mov ah, 0
	mov al, [token]
	jmp .check_true

.second_is_var:
	mov al, [token]
	call get_var
	jmp .check_true

.second_is_num:
	mov si, token
	call os_string_to_int

.check_true:
	mov byte bl, [.sign]
	cmp bl, '='
	je .sign_equals

	cmp bl, '>'
	je .sign_greater

	jmp .sign_lesser

.sign_equals:
	cmp ax, cx
	jne .false
	jmp .true

.sign_greater:
	cmp ax, cx
	jge .false
	jmp .true

.sign_lesser:
	cmp ax, cx
	jle .false
	jmp .true
.true:
	cmp dx, 1
	je .loop_back
	jmp mainloop
.false:
	cmp dx, 1
	je mainloop

.loop_back:	
	mov word si, do_loop_store
	mov byte al, [loop_in]
	mov ah, 0
	add si, ax
	lodsw
	mov word [prog], ax
	jmp mainloop

.while_set:
	mov dx, 1
	jmp .get_first_var

.no_do:
	mov si, err_loop
	jmp error

.error:
	mov si, err_syntax
	jmp error

.data:
	.while_word			db "WHILE", 0
	.until_word			db "UNTIL", 0
	.endless_word			db "ENDLESS", 0
	.sign				db 0

do_move:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov dl, al
	jmp .onto_second

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dl, al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	mov dh, al
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dh, al

.finish:
	mov byte bh, [work_page]
	mov ah, 2
	int 10h

	jmp mainloop

do_next:
	call get_token

	cmp ax, VARIABLE			
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	inc ax					

	mov bx, ax

	mov ax, 0
	mov byte al, [token]

	sub al, 65
	mov si, for_variables
	add si, ax
	add si, ax
	lodsw					

	inc ax					
	cmp ax, bx				
	je .loop_finished

	mov ax, 0				
	mov byte al, [token]
	call set_var

	mov ax, 0				
	mov byte al, [token]
	sub al, 65
	mov si, for_code_points
	add si, ax
	add si, ax
	lodsw

	mov word [prog], ax
	jmp mainloop

.loop_finished:
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_number:
	call get_token			

	cmp ax, STRING_VAR
	je .is_string

	cmp ax, VARIABLE
	je .is_variable

	jmp .error

.is_string:

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov [.tmp], si

	call get_token

	mov si, [.tmp]

	cmp ax, VARIABLE
	jne .error

	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]
	call set_var

	jmp mainloop

.is_variable:

	mov ax, 0			
	mov byte al, [token]
	call get_var

	call os_int_to_string		
	mov [.tmp], ax

	call get_token			

	mov si, [.tmp]

	cmp ax, STRING_VAR		
	jne .error

	mov di, string_vars		
	mov ax, 128
	mul bx
	add di, ax

	call os_string_copy		

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.tmp		dw 	0

do_page:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov byte [work_page], al	

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov byte [disp_page], al	

	mov ah, 5
	int 10h

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_pause:
	call get_token

	cmp ax, VARIABLE
	je .is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	jmp mainloop

do_peek:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al

	call get_token

	cmp ax, VARIABLE
	je .dereference

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.store:
	mov si, ax
	mov bx, 0
	mov byte bl, [si]
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var

	jmp mainloop

.dereference:
	mov byte al, [token]
	call get_var
	jmp .store

.error:
	mov si, err_syntax
	jmp error

	.tmp_var	db 0

do_peekint:
	call get_token

	cmp ax, VARIABLE
	jne .error

.get_second:
	mov al, [token]
	mov cx, ax

	call get_token

	cmp ax, VARIABLE
	je .address_is_var

	cmp ax, NUMBER
	jne .error

.address_is_number:
	mov si, token
	call os_string_to_int
	jmp .load_data

.address_is_var:
	mov al, [token]
	call get_var

.load_data:
	mov si, ax
	mov bx, [si]
	mov ax, cx
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_poke:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

	cmp ax, 255
	jg .error

	mov byte [.first_value], al
	jmp .onto_second

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov byte [.first_value], al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.got_value:
	mov di, ax
	mov ax, 0
	mov byte al, [.first_value]
	mov byte [di], al

	jmp mainloop

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .got_value

.error:
	mov si, err_syntax
	jmp error

	.first_value	db 0

do_pokeint:
	call get_token

	cmp ax, VARIABLE
	je .data_is_var

	cmp ax, NUMBER
	jne .error

.data_is_num:
	mov si, token
	call os_string_to_int
	jmp .get_second

.data_is_var:
	mov al, [token]
	call get_var

.get_second:
	mov cx, ax

	call get_token

	cmp ax, VARIABLE
	je .address_is_var

	cmp ax, NUMBER
	jne .error

.address_is_num:
	mov si, token
	call os_string_to_int
	jmp .save_data

.address_is_var:
	mov al, [token]
	call get_var

.save_data:
	mov si, ax
	mov [si], cx

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

do_port:
	call get_token
	mov si, token

	mov di, .out_cmd
	call os_string_compare
	jc .do_out_cmd

	mov di, .in_cmd
	call os_string_compare
	jc .do_in_cmd

	jmp .error

.do_out_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int		
	mov dx, ax

	call get_token
	cmp ax, NUMBER
	je .out_is_num

	cmp ax, VARIABLE
	je .out_is_var

	jmp .error

.out_is_num:
	mov si, token
	call os_string_to_int
	call os_port_byte_out
	jmp mainloop

.out_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_port_byte_out
	jmp mainloop

.do_in_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov dx, ax

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte cl, [token]

	call os_port_byte_in
	mov bx, 0
	mov bl, al

	mov al, cl
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.out_cmd	db "OUT", 0
	.in_cmd		db "IN", 0

do_print:
	call get_token				

	cmp ax, QUOTE				
	je .print_quote

	cmp ax, VARIABLE			
	je .print_var

	cmp ax, STRING_VAR			
	je .print_string_var

	cmp ax, STRING				
	je .print_keyword

	mov si, err_print_type			
	jmp error

.print_var:
	mov ax, 0
	mov byte al, [token]
	call get_var				

	call os_int_to_string			
	mov si, ax
	call os_print_string

	jmp .newline_or_not

.print_quote:					
	mov si, token
.print_quote_loop:
	lodsb
	cmp al, 0
	je .newline_or_not

	mov ah, 09h
	mov byte bl, [ink_colour]
	mov byte bh, [work_page]
	mov cx, 1
	int 10h

	mov ah, 3
	int 10h

	cmp dl, 79
	jge .quote_newline
	inc dl

.move_cur_quote:
	mov byte bh, [work_page]
	mov ah, 02h
	int 10h
	jmp .print_quote_loop

.quote_newline:
	cmp dh, 24
	je .move_cur_quote
	mov dl, 0
	inc dh
	jmp .move_cur_quote

.print_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	jmp .print_quote_loop

.print_keyword:
	mov si, token
	mov di, chr_keyword
	call os_string_compare
	jc .is_chr

	mov di, hex_keyword
	call os_string_compare
	jc .is_hex

	mov si, err_syntax
	jmp error

.is_chr:
	call get_token

	cmp ax, VARIABLE
	je .is_chr_variable

	cmp ax, NUMBER
	je .is_chr_number

.is_chr_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .print_chr

.is_chr_number:
	mov si, token
	call os_string_to_int

.print_chr:
	mov ah, 09h
	mov byte bl, [ink_colour]
	mov byte bh, [work_page]
	mov cx, 1
	int 10h

	mov ah, 3		
	int 10h
	inc dl
	cmp dl, 79
	jg .end_line		
.move_cur:
	mov ah, 2
	int 10h

	jmp .newline_or_not

.is_hex:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_print_2hex

	jmp .newline_or_not

.end_line:
	mov dl, 0
	inc dh
	cmp dh, 25
	jl .move_cur
	mov dh, 24
	mov dl, 79
	jmp .move_cur

.error:
	mov si, err_syntax
	jmp error

.newline_or_not:

	mov word ax, [prog]
	mov word [.tmp_loc], ax

	call get_token
	cmp ax, UNKNOWN
	jne .ignore

	mov ax, 0
	mov al, [token]
	cmp al, ';'
	jne .ignore

	jmp mainloop				

.ignore:
	mov ah, 5
	mov al, [work_page]
	int 10h

	mov bh, [work_page]
	call os_print_newline

	mov ah, 5
	mov al, [disp_page]

	mov word ax, [.tmp_loc]
	mov word [prog], ax

	jmp mainloop

	.tmp_loc	dw 0

do_rand:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num1], ax

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num2], ax

	mov word ax, [.num1]
	mov word bx, [.num2]
	call os_get_random

	mov bx, cx
	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop

	.tmp	db 0
	.num1	dw 0
	.num2	dw 0

.error:
	mov si, err_syntax
	jmp error

do_read:
	call get_token				

	cmp ax, STRING				
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb

	call get_token				
	cmp ax, VARIABLE
	je .second_part_is_var

	mov si, err_syntax
	jmp error

.second_part_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	cmp ax, 0				
	jg .var_bigger_than_zero

	mov si, err_syntax
	jmp error

.var_bigger_than_zero:
	mov word [.to_skip], ax

	call get_token				
	cmp ax, VARIABLE
	je .third_part_is_var

	mov si, err_syntax
	jmp error

.third_part_is_var:				
	mov ax, 0
	mov byte al, [token]
	mov byte [.var_to_use], al

	mov word ax, [prog]			
	mov word [.curr_location], ax

	mov word ax, [load_point]
	mov word [prog], ax			

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc .found_label

.line_loop:					
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]

	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error

.found_label:
	mov word cx, [.to_skip]			

.data_skip_loop:
	push cx
	call get_token
	pop cx
	loop .data_skip_loop

	cmp ax, NUMBER
	je .data_is_num

	mov si, err_syntax
	jmp error

.data_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax
	mov ax, 0
	mov byte al, [.var_to_use]
	call set_var

	mov word ax, [.curr_location]
	mov word [prog], ax

	jmp mainloop

	.curr_location	dw 0

	.to_skip	dw 0
	.var_to_use	db 0
	.tmp_token 	times 30 db 0

do_rem:
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10			
	jne do_rem

	jmp mainloop

do_rename:
	call get_token

	cmp ax, STRING_VAR		
	je .first_is_string

	cmp ax, QUOTE
	je .first_is_quote

	jmp .error

.first_is_string:
	mov si, string_vars		
	mov ax, 128
	mul bx
	add si, ax

	jmp .save_file1

.first_is_quote:
	mov si, token			

.save_file1:
	mov word di, .file1		
	call os_string_copy		

.get_second:
	call get_token

	cmp ax, STRING_VAR
	je .second_is_string

	cmp ax, QUOTE
	je .second_is_quote

	jmp .error

.second_is_string:
	mov si, string_vars		
	mov ax, 128
	mul bx
	add si, ax

	jmp .save_file2

.second_is_quote:
	mov si, token

.save_file2:
	mov word di, .file2
	call os_string_copy

.check_exists:
	mov word ax, .file1		
	call os_file_exists
	jc .file_not_found		

	clc
	mov ax, .file2			
	call os_file_exists
	jnc .file_exists		

.rename:
	mov word ax, .file1		
	mov word bx, .file2
	call os_rename_file

	jc .rename_failed		

	mov ax, 0			
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.file_not_found:
	mov ax, 0			
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.rename_failed:
	mov ax, 0			
	mov byte al, 'R'
	mov bx, 2
	call set_var

	jmp mainloop

.file_exists:
	mov ax, 0
	mov byte al, 'R'		
	mov bx, 3
	call set_var

	jmp mainloop

.data:
	.file1				times 12 db 0
	.file2				times 12 db 0

do_return:
	mov ax, 0
	mov byte al, [gosub_depth]
	cmp al, 0
	jne .is_ok

	mov si, err_return
	jmp error

.is_ok:
	mov si, gosub_points
	add si, ax				
	add si, ax
	lodsw
	mov word [prog], ax
	dec byte [gosub_depth]

	jmp mainloop	

do_save:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov di, .tmp_filename
	call os_string_copy

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.set_data_loc:
	mov word [.data_loc], ax

	call get_token

	cmp ax, VARIABLE
	je .third_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.check_exists:
	mov word [.data_size], ax
	mov word ax, .tmp_filename
	call os_file_exists
	jc .write_file
	jmp .file_exists_fail

.write_file:

	mov word ax, .tmp_filename
	mov word bx, [.data_loc]
	mov word cx, [.data_size]

	call os_write_file
	jc .save_failure

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .set_data_loc

.third_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .check_exists

.file_exists_fail:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 2
	call set_var
	jmp mainloop

.save_failure:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.filename_loc	dw 0
	.data_loc	dw 0
	.data_size	dw 0

	.tmp_filename	times 15 db 0

do_serial:
	call get_token
	mov si, token

	mov di, .on_cmd
	call os_string_compare
	jc .do_on_cmd

	mov di, .send_cmd
	call os_string_compare
	jc .do_send_cmd

	mov di, .rec_cmd
	call os_string_compare
	jc .do_rec_cmd

	jmp .error

.do_on_cmd:
	call get_token
	cmp ax, NUMBER
	je .do_on_cmd_ok
	jmp .error

.do_on_cmd_ok:
	mov si, token
	call os_string_to_int
	cmp ax, 1200
	je .on_cmd_slow_mode
	cmp ax, 9600
	je .on_cmd_fast_mode

	jmp .error

.on_cmd_fast_mode:
	mov ax, 0
	call os_serial_port_enable
	jmp mainloop

.on_cmd_slow_mode:
	mov ax, 1
	call os_serial_port_enable
	jmp mainloop

.do_send_cmd:
	call get_token
	cmp ax, NUMBER
	je .send_number

	cmp ax, VARIABLE
	je .send_variable

	jmp .error

.send_number:
	mov si, token
	call os_string_to_int
	call os_send_via_serial
	jmp mainloop

.send_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	call os_send_via_serial
	jmp mainloop

.do_rec_cmd:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]

	mov cx, 0
	mov cl, al
	call os_get_via_serial

	mov bx, 0
	mov bl, al
	mov al, cl
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

	.on_cmd		db "ON", 0
	.send_cmd	db "SEND", 0
	.rec_cmd	db "REC", 0

do_size:
	call get_token

	cmp ax, STRING_VAR
	je .is_string

	cmp ax, QUOTE
	je .is_quote

	jmp .error

.is_string:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov ax, si
	jmp .get_size

.is_quote:
	mov ax, token

.get_size:
	call os_get_file_size
	jc .file_not_found

	mov ax, 0
	mov al, 'S'
	call set_var

	mov ax, 0
	mov al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.file_not_found:
	mov ax, 0
	mov al, [token]
	mov bx, 0
	call set_var

	mov ax, 0
	mov al, 'R'
	mov bx, 1
 	call set_var

	jmp mainloop

do_sound:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	jmp .done_first

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.done_first:
	call os_speaker_tone

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	call os_speaker_off

	jmp mainloop

do_string:
	call get_token			
	mov si, token

	mov di, .get_cmd
	call os_string_compare
	jc .set_str

	mov di, .set_cmd
	call os_string_compare
	jc .get_str

	jmp .error

	.set_str:
	mov cx, 1
	jmp .check_second
	.get_str:
	mov cx, 2

.check_second:
	call get_token			

	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov word [.string_loc], si

.check_third:
	call get_token			

	cmp ax, NUMBER
	je .third_is_number

	cmp ax, VARIABLE
	je .third_is_variable

	jmp .error

.third_is_number:	
	mov si, token
	call os_string_to_int
	jmp .got_number	

.third_is_variable:
	mov ah, 0
	mov al, [token]
	call get_var
	jmp .got_number

.got_number:
	cmp ax, 128
	jg .outrange
	cmp ax, 0
	je .outrange
	sub ax, 1
	mov dx, ax

.check_forth:
	call get_token			

	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.tmp], al

	cmp cx, 2
	je .set_var

.get_var:
	mov word si, [.string_loc]	
	add si, dx			
	lodsw				
	mov bx, ax			
	mov ah, 0
	mov byte al, [.tmp]
	call set_var
	jmp mainloop

.set_var:
	mov byte al, [.tmp]		
	call get_var			
	mov di, [.string_loc]		
	add di, dx			
	stosb				
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.outrange:
	mov si, err_string_range
	jmp error

.data:
	.get_cmd		db "GET", 0
	.set_cmd		db "SET", 0
	.string_loc		dw 0
	.tmp			db 0

do_waitkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_wait_for_key

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed

.store:
	mov bx, 0
	mov bl, al

	pop ax

	call set_var

	jmp mainloop

.up_pressed:
	mov ax, 1
	jmp .store

.down_pressed:
	mov ax, 2
	jmp .store

.left_pressed:
	mov ax, 3
	jmp .store

.right_pressed:
	mov ax, 4
	jmp .store

get_var:
	mov ah, 0
	sub al, 65
	mov si, variables
	add si, ax
	add si, ax
	lodsw
	ret

set_var:
	mov ah, 0
	sub al, 65				

	mov di, variables			
	add di, ax
	add di, ax
	mov ax, bx
	stosw
	ret

get_token:
	mov word si, [prog]
	lodsb

	cmp al, 10
	je .newline

	cmp al, ' '
	je .newline

	call is_number
	jc get_number_token

	cmp al, '"'
	je get_quote_token

	cmp al, 39			
	je get_char_token

	cmp al, '$'
	je near get_string_var_token

	jmp get_string_token

.newline:
	inc word [prog]
	jmp get_token

get_number_token:
	mov word si, [prog]
	mov di, token

.loop:
	lodsb
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	call is_number
	jc .fine

	mov si, err_char_in_num
	jmp error

.fine:
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			
	stosb

	mov ax, NUMBER			
	ret

get_char_token:
	inc word [prog]			

	mov word si, [prog]
	lodsb

	mov byte [token], al

	lodsb
	cmp al, 39			
	je .is_ok

	mov si, err_quote_term
	jmp error

.is_ok:
	inc word [prog]
	inc word [prog]

	mov ax, CHAR
	ret

get_quote_token:
	inc word [prog]			
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, '"'
	je .done
	cmp al, 10
	je .error
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			
	stosb
	inc word [prog]			

	mov ax, QUOTE			
	ret

.error:
	mov si, err_quote_term
	jmp error

get_string_var_token:
	lodsb
	mov bx, 0			
	mov bl, al
	sub bl, 49

	inc word [prog]
	inc word [prog]

	mov ax, STRING_VAR
	ret

get_string_token:
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	stosb
	inc word [prog]
	jmp .loop
.done:
	mov al, 0			
	stosb

	mov ax, token
	call os_string_uppercase

	mov ax, token
	call os_string_length		
	cmp ax, 1			
	je .is_not_string

	mov si, token			
	add si, ax
	dec si
	lodsb
	cmp al, ':'
	je .is_label

	mov ax, STRING			
	ret

.is_label:
	mov ax, LABEL
	ret

.is_not_string:
	mov byte al, [token]
	call is_letter
	jc .is_var

	mov ax, UNKNOWN
	ret

.is_var:
	mov ax, VARIABLE		
	ret

is_number:
	cmp al, 48
	jl .not_number
	cmp al, 57
	jg .not_number
	stc
	ret
.not_number:
	clc
	ret

is_letter:
	cmp al, 65
	jl .not_letter
	cmp al, 90
	jg .not_letter
	stc
	ret

.not_letter:
	clc
	ret

error:
	mov ah, 5			
	mov al, 0
	int 10h

	mov byte [work_page], 0
	mov byte [disp_page], 0

	call os_print_newline
	call os_print_string		
	call os_print_newline

	mov word sp, [orig_stack]	

	ret				

	err_char_in_num		db "Error: unexpected char in number", 0
	err_cmd_unknown		db "Error: unknown command", 0
	err_divide_by_zero	db "Error: attempt to divide by zero", 0
	err_doloop_maximum	db "Error: DO/LOOP nesting limit exceeded", 0
	err_file_notfound	db "Error: file not found", 0
	err_goto_notlabel	db "Error: GOTO or GOSUB not followed by label", 0
	err_label_notfound	db "Error: label not found", 0
	err_nest_limit		db "Error: FOR or GOSUB nest limit exceeded", 0
	err_next		db "Error: NEXT without FOR", 0
	err_loop		db "Error: LOOP without DO", 0
	err_print_type		db "Error: PRINT not followed by quoted text or variable", 0
	err_quote_term		db "Error: quoted string or char not terminated correctly", 0
	err_return		db "Error: RETURN without GOSUB", 0
	err_string_range	db "Error: string location out of range", 0
	err_syntax		db "Error: syntax error", 0

	orig_stack		dw 0		

	prog			dw 0		
	prog_end		dw 0		

	load_point		dw 0

	token_type		db 0		
	token			times 255 db 0	

	variables		times 26 dw 0	

	for_variables		times 26 dw 0	
	for_code_points		times 26 dw 0	

	do_loop_store		times 10 dw 0	
	loop_in			db 0		

	ink_colour		db 0		
	work_page		db 0		
	disp_page		db 0		

	alert_cmd		db "ALERT", 0
	askfile_cmd		db "ASKFILE", 0
	call_cmd		db "CALL", 0
	cls_cmd			db "CLS", 0
	cursor_cmd		db "CURSOR", 0
	curschar_cmd		db "CURSCHAR", 0
	curscol_cmd		db "CURSCOL", 0
	curspos_cmd		db "CURSPOS", 0
	delete_cmd		db "DELETE", 0
	do_cmd			db "DO", 0
	end_cmd			db "END", 0
	for_cmd 		db "FOR", 0
	gosub_cmd		db "GOSUB", 0
	goto_cmd		db "GOTO", 0
	getkey_cmd		db "GETKEY", 0
	if_cmd 			db "IF", 0
	include_cmd		db "INCLUDE", 0
	ink_cmd			db "INK", 0
	input_cmd 		db "INPUT", 0
	len_cmd			db "LEN", 0
	listbox_cmd		db "LISTBOX", 0
	load_cmd		db "LOAD", 0
	loop_cmd		db "LOOP", 0
	move_cmd 		db "MOVE", 0
	next_cmd 		db "NEXT", 0
	number_cmd		db "NUMBER", 0
	page_cmd		db "PAGE", 0
	pause_cmd 		db "PAUSE", 0
	peek_cmd		db "PEEK", 0
	peekint_cmd		db "PEEKINT", 0
	poke_cmd		db "POKE", 0
	pokeint_cmd		db "POKEINT", 0
	port_cmd		db "PORT", 0
	print_cmd 		db "PRINT", 0
	rand_cmd		db "RAND", 0
	read_cmd		db "READ", 0
	rem_cmd			db "REM", 0
	rename_cmd		db "RENAME", 0
	return_cmd		db "RETURN", 0
	save_cmd		db "SAVE", 0
	serial_cmd		db "SERIAL", 0
	size_cmd		db "SIZE", 0
	sound_cmd 		db "SOUND", 0
	string_cmd		db "STRING", 0
	waitkey_cmd		db "WAITKEY", 0

	and_keyword		db "AND", 0
	then_keyword		db "THEN", 0
	chr_keyword		db "CHR", 0
	hex_keyword		db "HEX", 0

	ink_keyword		db "INK", 0
	progstart_keyword	db "PROGSTART", 0
	ramstart_keyword	db "RAMSTART", 0
	timer_keyword		db "TIMER", 0
	version_keyword		db "VERSION", 0

	gosub_depth		db 0
	gosub_points		times 10 dw 0	

	string_vars		times 1024 db 0	