os_command_line:
	call os_clear_screen

	mov si, startup_text1
	call os_print_string
	mov si, space_char
	call os_print_string
	mov si, startup_text2
	call os_print_string
	mov si, limit1
	call os_print_string
	mov si, limit2
	call os_print_string
	mov si, limit3
	call os_print_string
	mov si, startup_text3
	call os_print_string
	mov si, space_char
	call os_print_string
	mov si, startup_text4
	call os_print_string

get_cmd:				
	mov di, input			
	mov al, 0
	mov cx, 256
	rep stosb

	mov di, command			
	mov cx, 32
	rep stosb

	mov si, prompt			
	call os_print_string

	mov ax, input			
	call os_input_string

	call os_print_newline

	mov ax, input			
	call os_string_chomp

	mov si, input			
	cmp byte [si], 0
	je get_cmd

	mov si, input			
	mov al, ' '
	call os_string_tokenize

	mov word [param_list], di	

	mov si, input			
	mov di, command
	call os_string_copy

	mov ax, input
	call os_string_uppercase

	mov si, input

	mov di, info_string		
	call os_string_compare
	jc near print_info

	mov di, help_string		
	call os_string_compare
	jc near print_help

	mov di, cls_string		
	call os_string_compare
	jc near clear_screen

	mov di, dir_string		
	call os_string_compare
	jc near list_directory

	mov di, ver_string		
	call os_string_compare
	jc near print_ver

	mov di, time_string		
	call os_string_compare
	jc near print_time

	mov di, date_string		
	call os_string_compare
	jc near print_date

	mov di, cat_string		
	call os_string_compare
	jc near cat_file

	mov di, del_string		
	call os_string_compare
	jc near del_file

	mov di, copy_string		
	call os_string_compare
	jc near copy_file

	mov di, ren_string		
	call os_string_compare
	jc near ren_file

	mov di, size_string		
	call os_string_compare
	jc near size_file

	mov ax, command
	call os_string_uppercase
	call os_string_length

	mov si, command
	add si, ax

	sub si, 4

	mov di, bin_extension		
	call os_string_compare
	jc bin_file

	mov di, bas_extension		
	call os_string_compare
	jc bas_file

	jmp no_extension

bin_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

execute_bin:
	mov si, command
	mov di, kern_file_string
	mov cx, 6
	call os_string_strincmp
	jc no_kernel_allowed

	mov ax, 0			
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov word si, [param_list]
	mov di, 0

	call 32768			

	jmp get_cmd			

bas_file:
	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc total_fail

	mov ax, 32768
	mov word si, [param_list]
	call os_run_basic

	jmp get_cmd

no_extension:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'I'
	mov byte [si+3], 'N'
	mov byte [si+4], 0

	mov ax, command
	mov bx, 0
	mov cx, 32768
	call os_load_file
	jc try_bas_ext

	jmp execute_bin

try_bas_ext:
	mov ax, command
	call os_string_length

	mov si, command
	add si, ax
	sub si, 4

	mov byte [si], '.'
	mov byte [si+1], 'B'
	mov byte [si+2], 'A'
	mov byte [si+3], 'S'
	mov byte [si+4], 0

	jmp bas_file

total_fail:
	mov si, invalid_msg
	call os_print_string

	jmp get_cmd

no_kernel_allowed:
	mov si, kern_warn_msg
	call os_print_string

	jmp get_cmd

print_help:
	mov si, help_text
	call os_print_string
	jmp get_cmd

print_info:
	mov si, info_text
	call os_print_string
	jmp get_cmd

clear_screen:
	call os_clear_screen
	jmp get_cmd

print_time:
	mov bx, tmp_string
	call os_get_time_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd

print_date:
	mov bx, tmp_string
	call os_get_date_string
	mov si, bx
	call os_print_string
	call os_print_newline
	jmp get_cmd

print_ver:
	mov si, version_msg
	call os_print_string
	jmp get_cmd

kern_warning:
	mov si, kern_warn_msg
	call os_print_string
	jmp get_cmd

list_directory:
	mov cx,	0			

	mov ax, dirlist			
	call os_get_file_list

	mov si, dirlist
	mov ah, 0Eh			

.repeat:
	lodsb				
	cmp al, 0			
	je .done

	cmp al, ','			
	jne .nonewline
	pusha
	call os_print_newline		
	popa
	jmp .repeat

.nonewline:
	int 10h
	jmp .repeat

.done:
	call os_print_newline
	jmp get_cmd

cat_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_file_exists		
	jc .not_found

	mov cx, 32768			
	call os_load_file

	mov word [file_size], bx

	cmp bx, 0			
	je get_cmd

	mov si, 32768
	mov ah, 0Eh			
.loop:
	lodsb				

	cmp al, 0Ah			
	jne .not_newline

	call os_get_cursor_pos
	mov dl, 0
	call os_move_cursor

.not_newline:
	int 10h				
	dec bx				
	cmp bx, 0			
	jne .loop

	jmp get_cmd

.not_found:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

del_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_remove_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd

	.success_msg	db 'Deleted file: ', 0
	.failure_msg	db 'Could not delete file - does not exist or write protected', 13, 10, 0

size_file:
	mov word si, [param_list]
	call os_string_parse
	cmp ax, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	call os_get_file_size
	jc .failure

	mov si, .size_msg
	call os_print_string

	mov ax, bx
	call os_int_to_string
	mov si, ax
	call os_print_string
	call os_print_newline
	jmp get_cmd

.failure:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

	.size_msg	db 'Size (in bytes) is: ', 0

copy_file:
	mov word si, [param_list]
	call os_string_parse
	mov word [.tmp], bx

	cmp bx, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov dx, ax			
	mov ax, bx
	call os_file_exists
	jnc .already_exists

	mov ax, dx
	mov cx, 32768
	call os_load_file
	jc .load_fail

	mov cx, bx
	mov bx, 32768
	mov word ax, [.tmp]
	call os_write_file
	jc .write_fail

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.load_fail:
	mov si, notfound_msg
	call os_print_string
	jmp get_cmd

.write_fail:
	mov si, writefail_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd

	.tmp		dw 0
	.success_msg	db 'File copied successfully', 13, 10, 0

ren_file:
	mov word si, [param_list]
	call os_string_parse

	cmp bx, 0			
	jne .filename_provided

	mov si, nofilename_msg		
	call os_print_string
	jmp get_cmd

.filename_provided:
	mov cx, ax			
	mov ax, bx			
	call os_file_exists		
	jnc .already_exists

	mov ax, cx			
	call os_rename_file
	jc .failure

	mov si, .success_msg
	call os_print_string
	jmp get_cmd

.already_exists:
	mov si, exists_msg
	call os_print_string
	jmp get_cmd

.failure:
	mov si, .failure_msg
	call os_print_string
	jmp get_cmd

	.success_msg	db 'Moved file successfully', 13, 10, 0
	.failure_msg	db 'Operation failed - file not found or invalid filename', 13, 10, 0

	input			times 256 db 0
	command			times 32 db 0

	dirlist			times 1024 db 0
	tmp_string		times 15 db 0

	file_size		dw 0
	param_list		dw 0

	bin_extension		db '.BIN', 0
	bas_extension		db '.BAS', 0

	prompt			db 'console:/ # ', 0

	startup_text1		db 'Welcome to AetherixOS!', 13, 10, 0
	space_char		db ' ', 13, 10, 0
	startup_text2		db 'Note: AetherixOS is quite limited, some limitations include:', 13, 10, 0
	limit1		        db '- No directory support', 13, 10, 0
	limit2		        db '- Can only utilise 1.38MB of disk space', 13, 10, 0
	limit3		        db '- Single user', 13, 10, 0
	startup_text3		db 'Most bugs are unresolved meaning that the OS is unstable.', 13, 10, 0
	startup_text4		db 'For help, type "help" to see a list of commands.', 13, 10, 0
	help_text		db 'Commands: LS, CP, MV, RM, CAT, DU, CLEAR, HELP, TIME, DATE, VER, INFO', 13, 10, 0
	info_text		db 'AetherixOS, made by Charlie Geelan', 13, 10, 0
	invalid_msg		db 'No such command or program', 13, 10, 0
	nofilename_msg		db 'No filename or not enough filenames', 13, 10, 0
	notfound_msg		db 'File not found', 13, 10, 0
	writefail_msg		db 'Could not write file. Write protected or invalid filename?', 13, 10, 0
	exists_msg		db 'Target file already exists!', 13, 10, 0

	version_msg		db 'AetherixOS ', OS_VER, 13, 10, 0

	help_string		db 'HELP', 0
	cls_string		db 'CLEAR', 0
	dir_string		db 'LS', 0
	time_string		db 'TIME', 0
	date_string		db 'DATE', 0
	ver_string		db 'VER', 0
	cat_string		db 'CAT', 0
	del_string		db 'RM', 0
	ren_string		db 'MV', 0
	copy_string		db 'CP', 0
	size_string		db 'DU', 0
	info_string		db 'INFO', 0

	kern_file_string	db 'KERNEL', 0
	kern_warn_msg		db 'Cannot execute kernel!', 13, 10, 0