;*********************************
;*       lk_strings (v0.1)       *
;*        made by Link1nk        *
;*                               *
;*                               *
;* nasm -f elf64 lk_strings.asm  *
;* ld lk_strings.o -o lk_strings *
;*********************************

BITS 64

%include "lib.inc"

section .data
    arg_show_strings   db "--show-strings", 0
    arg_no_show_offset db "--no-show-offset", 0
    arg_end_byte       db "--end", 0 
    arg_end            db 0
    arg_file           db "-f", 0
    arg_lines          db "-l", 0
    arg_chars          db "-c", 0   

    success_check      db "[+] ", 0
    fail_check         db "[-] ", 0 

    error_msg          db "Erro: ", 0
    error_open_file    db "Não foi possivel abrir o arquivo", 0
    error_memory_alloc db "Memoria insuficiente", 0
    error_missing_args db "Precisa de mais argumentos", 0
    error_chars_min    db "Numero maximo de caracteres -> 255", 0

    fail_to_find       db "Não foi possivel encontrar nenhuma string", 0


section .bss
    argv_atual         resq 1
    
    OPT_show_strings   resb 1
    OPT_arg_chars      resb 1 
    OPT_arg_lines      resq 1
    OPT_no_show_offset resb 1
    OPT_end_byte       resb 1

    file_path          resq 1 
    file_descriptor    resq 1
    file_size          resq 1
    file_addr          resq 1

;Segmneto de dados nao inicializados para as funções
segment .bss 
    temp_buffer   resb 4096

    c_loop        resq 1
    i_loop        resq 1
    printed_lines resq 1
  
    any_output    resb 1


section .text
    global _start

parse_args:
    mov rcx, [argc]
    dec rcx
    mov edx, 1
    .loop:
    push rcx
    push rdx
    mov rdi, rdx
    call argv_index
    mov [argv_atual], rax

    mov rdi, [argv_atual]
    mov rsi, arg_file
    call string_equals
    cmp rax, 1
    je .file_path
    
    mov rdi, [argv_atual]
    mov rsi, arg_show_strings
    call string_equals
    cmp rax, 1
    je .show_strings

    mov rdi, [argv_atual]
    mov rsi, arg_chars
    call string_equals
    cmp rax, 1
    je .chars_min
    
    mov rdi, [argv_atual]
    mov rsi, arg_lines
    call string_equals
    cmp rax, 1
    je .lines_to_print
    
    mov rdi, [argv_atual]
    mov rsi, arg_no_show_offset
    call string_equals
    cmp rax, 1
    je .no_show_offset
    
    mov rdi, [argv_atual]
    mov rsi, arg_end_byte
    call string_equals
    cmp rax, 1
    je .end_byte
    ;-------------------------
    ;-------------------------
    ;-------------------------
    pop rdx
    pop rcx
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop
    .end:
    ret
    ;-------------------------
    ;-------------------------
    ;-------------------------
    .file_path:
    pop rdx
    pop rcx
    mov rdi, rdx
    inc rdi
    push rdx
    call argv_index
    pop rdx
    mov [file_path], rax
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop

    .show_strings:
    pop rdx
    pop rcx
    mov byte[OPT_show_strings], 1
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop

    .chars_min:
    pop rdx
    pop rcx
    mov rdi, rdx
    inc rdi
    push rdx
    call argv_index
    mov rdi, rax
    call parse_uint
    cmp rax, 0xff
    ja .error_chars
    mov byte[OPT_arg_chars], al
    pop rdx
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop
    .error_chars:
    mov rdi, error_chars_min
    jmp error

    .lines_to_print:
    pop rdx
    pop rcx
    mov rdi, rdx
    inc rdi
    push rdx
    call argv_index
    mov rdi, rax
    call parse_uint
    mov [OPT_arg_lines], rax
    pop rdx
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop

    .no_show_offset:
    pop rdx
    pop rcx
    mov byte[OPT_no_show_offset], 1
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop

    .end_byte:
    pop rdx
    pop rcx
    mov rdi, rdx
    inc rdi
    push rdx
    call argv_index
    mov rdi, rax
    call string_hex
    mov byte[OPT_end_byte], al
    mov byte[arg_end], 1
    pop rdx
    cmp rdx, rcx
    je .end
    inc rdx
    jmp .loop

;---------------------------------
option_chars:
    cmp byte[OPT_arg_chars], 0
    je .recive_chars_min
    ret
    .recive_chars_min:
    mov byte[OPT_arg_chars], 3
    ret
option_lines:
    cmp qword[OPT_arg_lines], 0
    je .recive_file_size
    ret
    .recive_file_size:
    mov [OPT_arg_lines], rax
    ret
;----------------------------------

_start:
    ;Salva o argc e argv
    call get_argc_argv
    
    ;Certifica que foi passado o minimo de argumentos nescessarios
    cmp qword[argc], 3
    mov rdi, error_missing_args
    jbe error

    ;Salva as opções de argumentos OPT. Exemplo: -f file.exe -l 10 -c 5
    call parse_args

    ;Abre o arquivo especificado por -f
    ;e exibe msg de erro caso não consiga abrir
    mov rdi, [file_path]
    mov rsi, O_RDWR
    call open_file
    cmp rax, -2
    mov rdi, error_open_file
    je error
    
    ;Salva o File Descriptor do arquivo aberto
    mov [file_descriptor], rax

    ;Obtem o tamanho do arquivo e o salva em file_size
    mov rdi, [file_path]
    call get_file_size
    mov [file_size], rax
    
    ;Seta o numero default para os argumentos -l e -c 
    call option_lines
    call option_chars
    
    ;Mapeia em memoria o arquivo com base em sua identificação(file descriptor)
    ;Salva o endereço de memoria em que o arquivo foi mapeado
    ;Exibe mensagem de erro caso não consiga mapear
    mov rdi, [file_descriptor]
    mov rsi, [file_size]
    call memory_alloc
    cmp rax, -1
    mov rdi, error_memory_alloc
    je error 
    mov [file_addr], rax
   
    ;Verifica se o usuario quer usar a função --show-strings
    movzx rdi, byte[OPT_show_strings]
    call show_strings
 
    
    ;-------TESTAR VARIAVEIS---------------------
    ;Seta uma cor para o terminal
    ;mov rdi, TERMINAL_COLOR_RED
    ;call set_terminal_color

    ;Teste de OPT (opções)
    ;movzx rdi, byte[OPT_arg_chars]
    ;call print_int

    ;Reseta as cores do terminal
    ;mov rdi, TERMINAL_COLOR_RESET
    ;call set_terminal_color
    ;--------------------------------------------


    ;Libera a memoria alocada com base em seu endereço e seu tamanho
    mov rdi, [file_addr]
    mov rsi, [file_size]
    call free_memory

    ;Fecha o arquivo identificado pelo seu File Descriptor
    mov rdi, [file_descriptor]
    call file_close

    ;Encerra o programa com codigo de erro 0
    mov rdi, 0
    jmp exit

end_show_strings:
    ret
show_strings:
    cmp rdi, 0
    je end_show_strings

    jmp .loop

    .mostrar_offset:
    mov rdi, COLOR_GREEN
    call set_terminal_color

    mov rax, [i_loop]
    sub rax, [c_loop]
    mov rdi, rax
    call print_hex
    
    mov rdi, 0x20
    call print_char
    mov rdi, 0x20
    call print_char
   
    mov rdi, TERMINAL_COLOR_RESET
    call set_terminal_color
    jmp .continuacao
    ;--------------------------------
    .else:
    add qword[i_loop], 1
    .elseLoop:
    mov rax, [c_loop]
    test rax, rax
    jz .loop
    mov rax, temp_buffer
    mov rcx, [c_loop]
    add rax, rcx
    mov byte[rax], 0
    sub qword[c_loop], 1
    mov rax, [c_loop]
    test rax, rax
    jnz .elseLoop
    jmp .loop
    ;---------------------------------
    .nextElseIf:
    movzx rax, byte[OPT_arg_chars]
    cmp qword[c_loop], rax
    jb .else
    movzx rax, byte[arg_end]
    cmp rax, 1
    je .nextCMP
    .lastCMP:
    movzx rax, byte[arg_end]
    cmp rax, 0
    jnz .else
    ;------------------------
    .codeInsideElseIf:
    movzx rax, byte[OPT_no_show_offset]
    test rax, rax
    je .mostrar_offset
    .continuacao:
    mov rdi, temp_buffer
    call print_string
    call print_newline
    add qword[printed_lines], 1
    mov byte[any_output], 1
    mov rax, [OPT_arg_lines]
    cmp rax, [printed_lines]
    je .end
    .continuacaoLoop:
    mov rax, [c_loop]
    test rax, rax
    jz .loop
    mov rax, temp_buffer
    mov rcx, [c_loop]
    add rax, rcx
    mov byte[rax], 0
    sub qword[c_loop], 1
    mov rax, [c_loop]
    test rax, rax
    jnz .continuacaoLoop
    add qword[i_loop], 1
    jmp .loop
    ;------------------------
    .nextCMP:
    mov rcx, [i_loop]
    mov rax, [file_addr]
    add rax, rcx
    mov cl, [OPT_end_byte]
    cmp byte[rax], cl
    jne .lastCMP
    jmp .codeInsideElseIf
    ;---------------------------------
    .loop:
    mov rax, [file_size]
    cmp qword[i_loop], rax
    je .end
    mov rcx, [i_loop]
    mov rax, [file_addr]
    add rax, rcx
    cmp byte[rax], 0x20
    jb .nextElseIf
    cmp byte[rax], 0x7e
    ja .nextElseIf    
    mov rcx, [c_loop]
    mov rax, temp_buffer
    add rax, rcx
    mov rdx, [i_loop]
    mov rcx, [file_addr]
    add rcx, rdx
    mov cl, byte[rcx] 
    mov byte[rax], cl
    add qword[c_loop], 1
    add qword[i_loop], 1
    jmp .loop
    ;------------------------------

    .fail_to_find_any_string:
    mov rdi, TERMINAL_COLOR_RED
    call set_terminal_color
    mov rdi, fail_check
    call print_string
    mov rdi, TERMINAL_COLOR_RESET
    call set_terminal_color

    mov rdi, fail_to_find
    call print_string
    call print_newline
    jmp .retornar

    .end:
    mov rax, [any_output]
    test rax, rax
    jz .fail_to_find_any_string
    .retornar:
    ;------Zerar variaveis------
    mov rdi, temp_buffer
    mov rsi, 4096
    call clear_buffer
    mov byte[any_output], 0
    mov qword[printed_lines], 0
    mov qword[i_loop], 0
    mov qword[c_loop], 0
    ;----------------------------
    ret





