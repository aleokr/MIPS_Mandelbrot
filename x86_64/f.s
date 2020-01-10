section .text
global mandelbrot
    ; rdi - pixels
    ; rsi - width
    ; rdx - height
    ; xmm0 - x
    ; xmm1 - y
    ; xmm2 - delta
mandelbrot:    
    push rbp
    push r12
	push r13
	push r14
    mov rbp, rsp
    mov rax, rsi ;rax - width
    mov r13, 4
    cvtsi2sd xmm9, r13 ;xmm9 - 4.0 - modul
    movsd xmm8, xmm0   ; zapamietujemy x 
start:
    mov r9, 200 ;counter
    movsd xmm3, xmm0 ; xmm3 - x
    movsd xmm4, xmm1 ; xmm4 - y 

calculate:
    movsd xmm5, xmm3
    mulsd xmm5, xmm5 ; x^2
    
    movsd xmm6, xmm4
    mulsd xmm6, xmm6 ; y^2
 
    movsd xmm7, xmm5
    addsd xmm7, xmm6 ; x^2+y^2 
    
    ucomisd xmm7, xmm9 ; x^2+y^2 <4
    jnb colour
nextValue:
    movsd xmm7, xmm5
    subsd xmm7, xmm6
    addsd xmm7, xmm0 ;nowe  x = x^2 - y^2 + x0
    
    movsd xmm5, xmm3
    mulsd xmm5, xmm4
    addsd xmm5, xmm5
    addsd xmm5, xmm1
    movsd xmm4, xmm5 ; nowe y = 2xy + y0

    movsd xmm3, xmm7
    
    
conditional:
    sub r9, 1
    cmp r9, 0
    jne calculate

colour:	
    mov r13, 0
    mov [rdi], r13 ;czerwony

	add rdi, 1
    mov [rdi], r13 ;zielony

	add rdi, 1
	mov [rdi], r9 ;niebieski

    add rdi, 1
    mov byte[rdi], 255

    add rdi, 1

next:
   
    addsd xmm0, xmm2  ; x = x + delta
    dec rax
    jnz start

nextLine:
    
    movsd xmm0, xmm8 ; x = min x
    addsd xmm1, xmm2 ; y = y+delta 
    mov rax, rsi
    dec rdx
    jnz start

end:
    pop r14
	pop r13
	pop r12
	pop rbp
    ret


