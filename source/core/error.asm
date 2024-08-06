os_get_api_version:
	mov al, OS_API_VER
	ret

os_pause:
	pusha
	cmp ax, 0
	je .time_up			

	mov cx, 0
	mov [.counter_var], cx		

	mov bx, ax
	mov ax, 0
	mov al, 2			
	mul bx				
	mov [.orig_req_delay], ax	

	mov ah, 0
	int 1Ah				

	mov [.prev_tick_count], dx	

.checkloop:
	mov ah,0
	int 1Ah				

	cmp [.prev_tick_count], dx	

	jne .up_date			
	jmp .checkloop			

.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	
	jge .time_up			

	mov [.prev_tick_count], dx	

	jmp .checkloop			

	.orig_req_delay		dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0

os_fatal_error:
	mov bx, ax			

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	pusha
	mov ah, 09h			
	mov bh, 0
	mov cx, 240
	mov bl, 01001111b
	mov al, ' '
	int 10h
	popa

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	mov si, .msg_inform		
	call os_print_string

	mov si, bx			
	call os_print_string

	jmp $				

	.msg_inform		db '>>> FATAL OPERATING SYSTEM ERROR', 13, 10, 0
