global main

segment .data
    SYS_WRITE  equ 0x04
    SYS_READ   equ 0x03
    SYS_EXIT   equ 0x01
    SYS_CALL   equ 0x80
    FD_IN      equ 0x00
    FD_OUT     equ 0x01
    LF         equ 0x0A
    NULL       equ 0x00

section .data
    layout1          db "+---------------+", LF, NULL
    tamLayout1       equ $-layout1

    layout2          db "|  CALCULADORA  |", LF, NULL
    tamLayout2       equ $-layout2

    layout3          db "+---------------+", LF, LF, NULL
    tamLayout3       equ $-layout3

    digite           db "Calcular: ", NULL
    tamDigite        equ $-digite

    mostraRes        db "Resultado: ", NULL
    tamMostraRes     equ $-mostraRes

    negativo         db "-", NULL
    tamNegativo      equ $-negativo

    erroDivZero      db "***Erro: divisao por zero***", LF, NULL
    tamErroDivZero   equ $-erroDivZero

    tamOperacao      equ 100
    tamResultado     equ 100
    tamResultado_str equ 100

section .bss
    operacao         resb 100
    resultado        resb 100
    resultado_str    resb 100

section .text
main:
    mov eax, SYS_WRITE
    mov ebx, FD_OUT
    mov ecx, layout1
    mov edx, tamLayout1
    int SYS_CALL

    mov eax, SYS_WRITE
    mov ebx, FD_OUT
    mov ecx, layout2
    mov edx, tamLayout2
    int SYS_CALL

    mov eax, SYS_WRITE
    mov ebx, FD_OUT
    mov ecx, layout3
    mov edx, tamLayout3
    int SYS_CALL

    jmp loopCalls

loopCalls:
    call digiteOperacao

    xor eax, eax
    xor ebx, ebx
    xor ecx, ecx
    xor edx, edx
    lea esi, [operacao]    ;  ESI = ponteiro -> operacao

    call analizeop
    call hexString
    call mostraResultado
    call zerarVariaveis
    jmp loopCalls

digiteOperacao:
    mov eax, SYS_WRITE
    mov ebx, FD_OUT
    mov ecx, digite
    mov edx, tamDigite
    int SYS_CALL

    mov eax, SYS_READ
    mov ebx, FD_IN
    mov ecx, operacao
    mov edx, tamOperacao
    int SYS_CALL

    ret

analizeop:
    mov cl, byte[esi]      ; CL = operacao[0+esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espaco
    cmp cl, 0x2B  ;compara CL com +
    je checkPrioridadeSoma
    cmp cl, 0x2D  ;compara CL com -
    je checkPrioridadeSub
    cmp cl, 0x2A  ;compara CL com *
    je execMul
    cmp cl, 0x2F  ;compara CL com /
    je execDiv
    cmp cl, 0xA   ;compara CL com \n
    je exit
    cmp cl, 0x73  ;compara CL com "s"
    je exit

    inc esi
    call stringInt
    jmp analizeop

stringInt:
    sub  cl, 0x30
    imul ebx, 10
    add  ebx, ecx
    ret

espaco:
    inc esi
    jmp analizeop

;-------------------------------MUL/DIV SOMA------------------------------------------------
espaco_soma:
    jmp checkPrioridadeSomaLoop
checkPrioridadeSoma:
    push ebx
    xor ebx, ebx
checkPrioridadeSomaLoop:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espaco_soma
    cmp cl, 0x2B  ;compara CL com +
    je execSoma
    cmp cl, 0x2D  ;compara CL com -
    je execSoma
    cmp cl, 0x2A  ;compara CL com *
    je multiplicar_soma
    cmp cl, 0x2F  ;compara CL com /
    je dividir_soma
    cmp cl, 0xA   ;compara CL com \n
    je somaFim

    call stringInt
    jmp checkPrioridadeSomaLoop

espacoMultiplicarSoma:
    jmp proxDigitMulSoma
multiplicar_soma:
    push ebx
    xor ebx, ebx
    jmp proxDigitMulSoma

proxDigitMulSoma:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espacoMultiplicarSoma
    cmp cl, 0x2B  ;compara CL com +
    je multiplicarSoma
    cmp cl, 0x2D  ;compara CL com -
    je multiplicarSoma
    cmp cl, 0x2A  ;compara CL com *
    je multiplicarSoma
    cmp cl, 0x2F  ;compara CL com /
    je multiplicarSoma
    cmp cl, 0x0A  ;compara CL com \n
    je somaMulFim

    call stringInt
    jmp proxDigitMulSoma

multiplicarSoma:
    pop eax
    imul eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp check_soma
somaFim:
    pop eax
    add eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    ret
somaMulFim:
    pop eax
    imul eax, ebx
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    pop eax
    add eax, ebx
    mov [resultado], eax
    ret

check_soma:
    mov cl, byte[esi]

    cmp cl, 0x2a
    je multiplicar_soma
    cmp cl, 0x2f
    je dividir_soma
    jne somar

somar:
    pop eax
    add eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp analizeop

execSoma:
    pop eax
    add eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp analizeop

espacoDividirSoma:
    jmp proxDigitDivSoma

dividir_soma:
    push ebx
    xor ebx, ebx
    jmp proxDigitDivSoma

proxDigitDivSoma:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espacoDividirSoma
    cmp cl, 0x2B  ;compara CL com +
    je dividirSoma
    cmp cl, 0x2D  ;compara CL com -
    je dividirSoma
    cmp cl, 0x2A  ;compara CL com *
    je dividirSoma
    cmp cl, 0x2F  ;compara CL com /
    je dividirSoma
    cmp cl, 0x0A  ;compara CL com \n
    je somaDivFim

    call stringInt
    jmp proxDigitDivSoma

dividirSoma:
    pop eax
    cmp eax, 0x00
    je divZero
    cmp ebx, 0x00
    je divZero
    cdq
    idiv ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp check_soma
divFim:
    pop eax
    add eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    ret
somaDivFim:
    pop eax
    cmp eax, 0x00
    je divZero
    cmp ebx, 0x00
    je divZero
    cdq
    idiv ebx
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    pop eax
    add eax, ebx
    mov [resultado], eax
    ret

;---------------------------------FIM MUL/DIV SOMA------------------------------------------
;-----------------------------------------------------------------------------------------------
;-------------------------MUL/DIV SUB-----------------------------------------------------------
espaco_sub:
    jmp checkPrioridadeSubLoop

checkPrioridadeSub:
    push ebx
    xor ebx, ebx
checkPrioridadeSubLoop:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espaco_sub
    cmp cl, 0x2B  ;compara CL com +
    je execSub
    cmp cl, 0x2D  ;compara CL com -
    je execSub
    cmp cl, 0x2A  ;compara CL com *
    je multiplicar_sub
    cmp cl, 0x2F  ;compara CL com /
    je dividir_sub
    cmp cl, 0xA   ;compara CL com \n
    je subFim

    call stringInt
    jmp checkPrioridadeSubLoop

espacoMultiplicarSub:
    jmp proxDigitMulSub

multiplicar_sub:
    push ebx
    xor ebx, ebx
    jmp proxDigitMulSub

proxDigitMulSub:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espacoMultiplicarSub
    cmp cl, 0x2B  ;compara CL com +
    je multiplicarSub
    cmp cl, 0x2D  ;compara CL com -
    je multiplicarSub
    cmp cl, 0x2A  ;compara CL com *
    je multiplicarSub
    cmp cl, 0x2F  ;compara CL com /
    je multiplicarSub
    cmp cl, 0x0A  ;compara CL com \n
    je subMulFim

    call stringInt
    jmp proxDigitMulSub

multiplicarSub:
    pop eax
    imul eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp check_sub

subFim:
    pop eax
    sub eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    ret

subMulFim:
    pop eax
    imul eax, ebx
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    pop eax
    sub eax, ebx
    mov [resultado], eax
    ret

check_sub:
    mov cl, byte[esi]

    cmp cl, 0x2a
    je multiplicar_sub
    cmp cl, 0x2f
    je dividir_sub
    jne subtrair

subtrair:
    pop eax
    sub eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp analizeop

execSub:
    pop eax
    sub eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp analizeop

espacoDividirSub:
    jmp proxDigitDivSub

dividir_sub:
    push ebx
    xor ebx, ebx
    jmp proxDigitDivSub

proxDigitDivSub:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je espacoDividirSub
    cmp cl, 0x2B  ;compara CL com +
    je dividirSub
    cmp cl, 0x2D  ;compara CL com -
    je dividirSub
    cmp cl, 0x2A  ;compara CL com *
    je dividirSub
    cmp cl, 0x2F  ;compara CL com /
    je dividirSub
    cmp cl, 0x0A  ;compara CL com \n
    je subDivFim

    call stringInt
    jmp proxDigitDivSub

dividirSub:
    pop eax
    cdq
    cmp eax, 0x00
    je divZero
    cmp ebx, 0x00
    je divZero
    idiv ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp check_sub

subDivFim:
    pop eax
    cdq
    cmp eax, 0x00
    je divZero
    cmp ebx, 0x00
    je divZero
    idiv ebx
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    pop eax
    sub eax, ebx
    mov [resultado], eax
    ret

;-------------FIM MUL/DIV SUB---------------------------------------------------------------------


;----------INICIO MULTIPLICAR------------------------------------------------------------------
execMulEspaco:
    jmp nextDigitMul

execMul:
    push ebx
    xor ebx, ebx
    jmp nextDigitMul

nextDigitMul:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je execMulEspaco
    cmp cl, 0x2B  ;compara CL com +
    je multiplicar
    cmp cl, 0x2D  ;compara CL com -
    je multiplicar
    cmp cl, 0x2A  ;compara CL com *
    je multiplicar
    cmp cl, 0x2F  ;compara CL com /
    je multiplicar
    cmp cl, 0xA   ;compara CL com \n
    je multiplicarFim

    call stringInt
    jmp nextDigitMul

multiplicar:
    pop eax
    imul eax, ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp analizeop

multiplicarFim:
    pop eax
    imul eax, ebx
    mov [resultado], eax
    ret
;------------------------FIM MULTIPLICAR--------------------------------------------------------
;----------------------------------------------------------------------------------------------
;---------------INICIO DIVIDIR--------------------------------------------------------------


execDivEspaco:
    jmp nextDigitDiv

execDiv:
    push ebx
    xor ebx, ebx
    jmp nextDigitDiv

nextDigitDiv:
    inc esi
    mov cl, byte[esi]

    cmp cl, 0x20  ;compara CL com "espaço"
    je execDivEspaco
    cmp cl, 0x2B  ;compara CL com +
    je dividir
    cmp cl, 0x2D  ;compara CL com -
    je dividir
    cmp cl, 0x2A  ;compara CL com *
    je dividir
    cmp cl, 0x2F  ;compara CL com /
    je dividir
    cmp cl, 0xA   ;compara CL com \n
    je dividirFim

    call stringInt
    jmp nextDigitDiv

dividir:
    pop eax
    cdq
    cmp eax, 0x00
    je divZero
    cmp ebx, 0x00
    je divZero
    idiv ebx
    mov [resultado], eax
    xor ebx, ebx
    add ebx, eax
    xor eax, eax
    jmp analizeop

dividirFim:
    pop eax
    cmp eax, 0x00
    je divZero
    cmp ebx, 0x00
    je divZero
    cdq
    idiv ebx
    mov [resultado], eax
    ret


;------------FIM DIVIDIR---------------------------------------------------------------------

hexString:
    call checkSinal

    lea esi, [resultado_str]
    mov eax, [resultado]
    add esi, 0x09
    mov byte[esi], 0x0A
    inc esi
    mov byte[esi], 0x0A
    dec esi
    xor ebx, ebx
    mov ebx, 0x0A
.loop:
    xor edx, edx
    div ebx
    add dl, 0x30
    dec esi
    mov [esi], dl
    test eax, eax
    jnz hexString.loop
    ret

mostraResultado:
    mov eax, SYS_WRITE
    mov ebx, FD_OUT
    mov ecx, resultado_str
    mov edx, 100
    int SYS_CALL

    ret

zerarVariaveis:
	call zerarResultado_str
	call zerarOperacao
	call zerarResultado
	ret
;-------------------------------------
zerarOperacao:
	lea esi, [operacao]
	jmp zerarOperacaoLoop
zerarOperacaoLoop:
	mov cl, byte[esi]
	cmp cl, 0x00
	jne adicionarZeroOperacao
	ret
adicionarZeroOperacao:
	mov byte[esi], 0x00
	inc esi
	jmp zerarOperacaoLoop
;--------------------------------------
zerarResultado:
        lea esi, [resultado]
        jmp zerarResultadoLoop
zerarResultadoLoop:
        mov cl, byte[esi]
        cmp cl, 0x00
        jne adicionarZeroResultado
        ret
adicionarZeroResultado:
        mov byte[esi], 0x00
        inc esi
        jmp zerarResultadoLoop
;-----------------------------------------
zerarResultado_str:
        lea esi, [resultado_str + 8]
        jmp zerarResultado_strLoop
zerarResultado_strLoop:
        mov cl, byte[esi]
        cmp cl, 0x00
        jne adicionarZeroResultado_str
        ret
adicionarZeroResultado_str:
        mov byte[esi], 0x00
        dec esi
        jmp zerarResultado_strLoop

;-------------------------------------------

checkSinal:
	mov eax, [resultado]
	cmp eax, 0x7FFFFFFF
	ja sinalNegativo
	jmp sinalPositivo
sinalNegativo:
	neg eax
	mov [resultado], eax

	xor eax, eax
	xor ebx, ebx
	xor ecx, ecx
	xor edx, edx

	mov eax, SYS_WRITE
	mov ebx, FD_OUT
	mov ecx, mostraRes
	mov edx, tamMostraRes
	int SYS_CALL

	mov eax, SYS_WRITE
	mov ebx, FD_OUT
	mov ecx, negativo
	mov edx, tamNegativo
	int SYS_CALL

	ret

sinalPositivo:
	mov eax, SYS_WRITE
        mov ebx, FD_OUT
        mov ecx, mostraRes
        mov edx, tamMostraRes
        int SYS_CALL

	ret

divZero:
	mov eax, SYS_WRITE
        mov ebx, FD_OUT
        mov ecx, erroDivZero
        mov edx, tamErroDivZero
        int SYS_CALL

	jmp exit
exit:
    mov eax, SYS_EXIT
    mov ebx, 0
    int SYS_CALL
