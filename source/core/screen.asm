os_print_string:
	pusha

	mov ah, 0Eh			

.repeat:
	lodsb				
	cmp al, 0
	je .done			

	int 10h				
	jmp .repeat			

.done:
	popa
	ret

os_clear_screen:
	pusha

	mov dx, 0			
	call os_move_cursor

	mov ah, 6			
	mov al, 0			
	mov bh, 7			
	mov cx, 0			
	mov dh, 24			
	mov dl, 79
	int 10h

	popa
	ret

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				

	popa
	ret

os_get_cursor_pos:
	pusha

	mov bh, 0
	mov ah, 3
	int 10h				

	mov [.tmp], dx
	popa
	mov dx, [.tmp]
	ret

	.tmp dw 0

os_print_horiz_line:
	pusha

	mov cx, ax			
	mov al, 196			

	cmp cx, 1			
	jne .ready
	mov al, 205			

.ready:
	mov cx, 0			
	mov ah, 0Eh			

.restart:
	int 10h
	inc cx
	cmp cx, 80			
	je .done
	jmp .restart

.done:
	popa
	ret

os_show_cursor:
	pusha

	mov ch, 6
	mov cl, 7
	mov ah, 1
	mov al, 3
	int 10h

	popa
	ret

os_hide_cursor:
	pusha

	mov ch, 32
	mov ah, 1
	mov al, 3			
	int 10h

	popa
	ret

os_draw_block:
	pusha

.more:
	call os_move_cursor		

	mov ah, 09h			
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh				

	mov ax, 0
	mov al, dh			
	cmp ax, di			
	jne .more			

	popa
	ret

os_file_selector:
	pusha

	mov word [.filename], 0		

	mov ax, .buffer			
	call os_get_file_list

	mov ax, .buffer			
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog

	jc .esc_pressed

	dec ax				

	mov cx, ax
	mov bx, 0

	mov si, .buffer			
.loop1:
	cmp bx, cx
	je .got_our_filename
	lodsb
	cmp al, ','
	je .comma_found
	jmp .loop1

.comma_found:
	inc bx
	jmp .loop1

.got_our_filename:			
	mov di, .filename
.loop2:
	lodsb
	cmp al, ','
	je .finished_copying
	cmp al, 0
	je .finished_copying
	stosb
	jmp .loop2

.finished_copying:
	mov byte [di], 0		

	popa

	mov ax, .filename

	clc
	ret

.esc_pressed:				
	popa
	stc
	ret

	.buffer		times 1024 db 0

	.help_msg1	db 'Please select a file using the cursor', 0
	.help_msg2	db 'keys from the list below...', 0

	.filename	times 13 db 0

os_list_dialog:
	pusha

	push ax				

	push cx				
	push bx

	call os_hide_cursor

	mov cl, 0			
	mov si, ax
.count_loop:
	lodsb
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl

	mov bl, 01001111b		
	mov dl, 20			
	mov dh, 2			
	mov si, 40			
	mov di, 23			
	call os_draw_block		

	mov dl, 21			
	mov dh, 3
	call os_move_cursor

	pop si				
	call os_print_string

	inc dh				
	call os_move_cursor

	pop si
	call os_print_string

	pop si				
	mov word [.list_string], si

	mov byte [.skip_num], 0		

	mov dl, 25			
	mov dh, 7

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		
	mov dl, 21
	mov dh, 6
	mov si, 38
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	call os_wait_for_key		
	cmp ah, 48h			
	je .go_up
	cmp ah, 50h			
	je .go_down
	cmp al, 13			
	je .option_selected
	cmp al, 27			
	je .esc_pressed
	jmp .more_select		

.go_up:
	cmp dh, 7			
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				
	jmp .more_select

.go_down:				
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select

.hit_top:
	mov byte cl, [.skip_num]	
	cmp cl, 0
	je .another_key			

	dec byte [.skip_num]		
	jmp .more_select

.hit_bottom:				
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		
	jmp .more_select

.option_selected:
	call os_show_cursor

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				
	add byte al, [.skip_num]	

	mov word [.tmp], ax		

	popa

	mov word ax, [.tmp]
	clc				
	ret

.esc_pressed:
	call os_show_cursor
	popa
	stc				
	ret

.draw_list:
	pusha

	mov dl, 23			
	mov dh, 7
	call os_move_cursor

	mov cx, 0			
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop

.skip_loop_finished:
	mov bx, 0			

.more:
	lodsb				

	cmp al, 0			
	je .done_list

	cmp al, ','			
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 23			
	inc dh				
	call os_move_cursor

	inc bx				
	cmp bx, 14			
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret

.draw_black_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			
	mov bh, 0
	mov cx, 36
	mov bl, 00001111b		
	mov al, ' '
	int 10h

	popa
	ret

.draw_white_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			
	mov bh, 0
	mov cx, 36
	mov bl, 11110000b		
	mov al, ' '
	int 10h

	popa
	ret

	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0

os_draw_background:
	pusha

	push ax				
	push bx
	push cx

	mov dl, 0
	mov dh, 0
	call os_move_cursor

	mov ah, 09h			
	mov bh, 0
	mov cx, 80
	mov bl, 01110000b
	mov al, ' '
	int 10h

	mov dh, 1
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			
	mov cx, 1840
	pop bx				
	mov bh, 0
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			
	mov bh, 0
	mov cx, 80
	mov bl, 01110000b
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 1
	call os_move_cursor
	pop bx				
	mov si, bx
	call os_print_string

	mov dh, 0
	mov dl, 1
	call os_move_cursor
	pop ax				
	mov si, ax
	call os_print_string

	mov dh, 1			
	mov dl, 0
	call os_move_cursor

	popa
	ret

os_print_newline:
	pusha

	mov ah, 0Eh			

	mov al, 13
	int 10h
	mov al, 10
	int 10h

	popa
	ret

os_dump_registers:
	pusha

	call os_print_newline

	push di
	push si
	push dx
	push cx
	push bx

	mov si, .ax_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .bx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .cx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .dx_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .si_string
	call os_print_string
	call os_print_4hex

	pop ax
	mov si, .di_string
	call os_print_string
	call os_print_4hex

	call os_print_newline

	popa
	ret

	.ax_string		db 'AX:', 0
	.bx_string		db ' BX:', 0
	.cx_string		db ' CX:', 0
	.dx_string		db ' DX:', 0
	.si_string		db ' SI:', 0
	.di_string		db ' DI:', 0

os_input_dialog:
	pusha

	push ax				
	push bx				

	mov dh, 10			
	mov dl, 12

.redbox:				
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, 01001111b		
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox

.boxdone:
	mov dl, 14
	mov dh, 11
	call os_move_cursor

	pop bx				
	mov si, bx
	call os_print_string

	mov dl, 14
	mov dh, 13
	call os_move_cursor

	pop ax				
	call os_input_string

	popa
	ret

os_dialog_box:
	pusha

	mov [.tmp], dx

	call os_hide_cursor

	mov dh, 9			
	mov dl, 19

.redbox:				
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 42
	mov bl, 01001111b		
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox

.boxdone:
	cmp ax, 0			
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call os_move_cursor

	mov si, ax			
	call os_print_string

.no_first_string:
	cmp bx, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call os_move_cursor

	mov si, bx			
	call os_print_string

.no_second_string:
	cmp cx, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call os_move_cursor

	mov si, cx			
	call os_print_string

.no_third_string:
	mov dx, [.tmp]
	cmp dx, 0
	je .one_button
	cmp dx, 1
	je .two_button

.one_button:
	mov bl, 11110000b		
	mov dh, 14
	mov dl, 35
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 38			
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	jmp .one_button_wait

.two_button:
	mov bl, 11110000b		
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov dl, 44			
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0			
	jmp .two_button_wait

.one_button_wait:
	call os_wait_for_key
	cmp al, 13			
	jne .one_button_wait

	call os_show_cursor

	popa
	ret

.two_button_wait:
	call os_wait_for_key

	cmp ah, 75			
	jne .noleft

	mov bl, 11110000b		
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 01001111b		
	mov dh, 14
	mov dl, 42
	mov si, 9
	mov di, 15
	call os_draw_block

	mov dl, 44			
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 0			
	jmp .two_button_wait

.noleft:
	cmp ah, 77			
	jne .noright

	mov bl, 01001111b		
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	mov bl, 11110000b		
	mov dh, 14
	mov dl, 43
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 44			
	mov dh, 14
	call os_move_cursor
	mov si, .cancel_button_string
	call os_print_string

	mov cx, 1			
	jmp .two_button_wait

.noright:
	cmp al, 13			
	jne .two_button_wait

	call os_show_cursor

	mov [.tmp], cx			
	popa
	mov ax, [.tmp]

	ret

	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0
	.ok_button_noselect	db '   OK   ', 0
	.cancel_button_noselect	db '   Cancel   ', 0

	.tmp dw 0

os_print_space:
	pusha

	mov ah, 0Eh			
	mov al, 20h			
	int 10h

	popa
	ret

os_dump_string:
	pusha

	mov bx, si			

.line:
	mov di, si			
	mov cx, 0			

.more_hex:
	lodsb
	cmp al, 0
	je .chr_print

	call os_print_2hex
	call os_print_space		
	inc cx

	cmp cx, 8
	jne .q_next_line

	call os_print_space		
	jmp .more_hex

.q_next_line:
	cmp cx, 16
	jne .more_hex

.chr_print:
	call os_print_space
	mov ah, 0Eh			
	mov al, '|'			
	int 10h
	call os_print_space

	mov si, di			
	mov cx, 0

.more_chr:
	lodsb
	cmp al, 0
	je .done

	cmp al, ' '
	jae .tst_high

	jmp short .not_printable

.tst_high:
	cmp al, '~'
	jbe .output

.not_printable:
	mov al, '.'

.output:
	mov ah, 0Eh
	int 10h

	inc cx
	cmp cx, 16
	jl .more_chr

	call os_print_newline		
	jmp .line

.done:
	call os_print_newline		

	popa
	ret

os_print_digit:
	pusha

	cmp ax, 9			
	jle .digit_format

	add ax, 'A'-'9'-1		

.digit_format:
	add ax, '0'			

	mov ah, 0Eh			
	int 10h

	popa
	ret

os_print_1hex:
	pusha

	and ax, 0Fh			
	call os_print_digit

	popa
	ret

os_print_2hex:
	pusha

	push ax				
	shr ax, 4
	call os_print_1hex

	pop ax				
	call os_print_1hex

	popa
	ret

os_print_4hex:
	pusha

	push ax				
	mov al, ah
	call os_print_2hex

	pop ax				
	call os_print_2hex

	popa
	ret

os_input_string:
	pusha

	mov di, ax			
	mov cx, 0			

.more:					
	call os_wait_for_key

	cmp al, 13			
	je .done

	cmp al, 8			
	je .backspace			

	cmp al, ' '			
	jb .more			

	cmp al, '~'
	ja .more

	jmp .nobackspace

.backspace:
	cmp cx, 0			
	je .more			

	call os_get_cursor_pos		
	cmp dl, 0
	je .backspace_linestart

	pusha
	mov ah, 0Eh			
	mov al, 8
	int 10h				
	mov al, 32
	int 10h
	mov al, 8
	int 10h
	popa

	dec di				

	dec cx				

	jmp .more

.backspace_linestart:
	dec dh				
	mov dl, 79
	call os_move_cursor

	mov al, ' '			
	mov ah, 0Eh
	int 10h

	mov dl, 79			
	call os_move_cursor

	dec di				
	dec cx				

	jmp .more

.nobackspace:
	pusha
	mov ah, 0Eh			
	int 10h
	popa

	stosb				
	inc cx				
	cmp cx, 254			
	jae near .done

	jmp near .more			

.done:
	mov ax, 0
	stosb

	popa
	ret