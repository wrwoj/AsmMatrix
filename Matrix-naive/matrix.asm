; Most naive implementation, matrices stored row/column wise
; Row-major storage
; Multiplication using traditional means.
; (This version is useful to compare baseline performance with the Strassen version.)

section .text

global asm_matrix_create, asm_matrix_free, asm_matrix_add, asm_matrix_mul, asm_matrix_scalar_mul
global asm_matrix_get, asm_matrix_set, asm_matrix_size, asm_matrix_capacity, asm_matrix_transpose
global asm_matrix_multiply
extern _aligned_malloc, realloc, _aligned_free, memset
global asm_matrix_strassen

; to prevent crashes
error_exit:
    xor rax, rax
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_create(int rows, int cols)
;------------------------------------------------------------------------------
asm_matrix_create:
    push rdi                      ; preserve nonvolatile
    push rsi
    mov rdi, rdx                  ; cols
    mov rsi, rcx                  ; rows
    sub rsp, 32                   ; allocate shadow space
    mov rcx, 24                   ; struct size (3 qwords)
    mov rdx, 32                   ; alignment
    call _aligned_malloc
    test rax, rax
    je error_exit
    mov [rax+8], rsi              ; store rows
    mov [rax+16], rdi             ; store cols
    mov rdi, rax                ; preserve pointer
    mov rcx, rsi                ; rows
    imul rcx, [rdi+16]          ; rows * cols
    shl rcx, 2                  ; *4 bytes per float
    mov rsi, rcx
    mov rdx, 32                 ; alignment
    call _aligned_malloc
    test rax, rax
    je error_exit
    mov [rdi], rax              ; store data pointer
    mov rcx, [rdi]
    mov rdx, 0
    mov r8, rsi                ; total size in bytes
    call memset
    mov rax, rdi              ; return pointer
    add rsp, 32
    pop rsi
    pop rdi
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_free(Matrix* mat)
;------------------------------------------------------------------------------
asm_matrix_free:
    push rdi
    test rcx, rcx
    je error_exit
    sub rsp, 32
    mov rdi, rcx
    mov rcx, [rdi]
    call _aligned_free
    mov rcx, rdi
    call _aligned_free
    add rsp, 32
    pop rdi
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_set(Matrix* mat, int row, int col, float value);
;------------------------------------------------------------------------------
asm_matrix_set:
    cmp rdx, [rcx + 8]
    jae error_exit
    cmp r8, [rcx + 16]
    jae error_exit
    mov rax, [rcx] ;addres of data
    imul rdx, [rcx + 16] ;
    add rdx, r8 ;
    movss [rax + rdx*4], xmm3
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_get(Matrix* mat, int row, int col);
;------------------------------------------------------------------------------
asm_matrix_get:
    cmp rdx, [rcx + 8]
    jae error_exit
    cmp r8, [rcx + 16]
    jae error_exit
    mov rax, [rcx]
    imul rdx, [rcx + 16]
    add rdx, r8
    movss xmm0, [rax + rdx*4]
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_add(Matrix* a, Matrix* b, Matrix* result);
;------------------------------------------------------------------------------
asm_matrix_add:
    push r12
    mov r8, [r8]            ; load result's data pointer
    mov r12, [rcx+8]        ; rows of matrix a
    cmp r12, [rdx+8]
    jne error_exit
    imul r12, [rcx+16]      ; total elements
    mov rax, [rcx+16]
    cmp rax, [rdx+16]
    jne error_exit
    mov rcx, [rcx]         ; a's data pointer
    mov rdx, [rdx]         ; b's data pointer
add_loop8:
    cmp r12, 0
    jle add_done
    cmp r12, 8
    jl add_scalar
    sub r12, 8
    vmovups ymm0, [rcx + r12*4]
    vmovups ymm1, [rdx + r12*4]
    vaddps ymm0, ymm0, ymm1
    vmovups [r8 + r12*4], ymm0
    jmp add_loop8
add_scalar:
    vzeroupper
add_loop1:
    cmp r12, 0
    jle add_done
    dec r12
    movss xmm0, [rcx + r12*4]
    addss xmm0, [rdx + r12*4]
    movss [r8 + r12*4], xmm0
    jmp add_loop1
add_done:
    pop r12
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_scalar_mul(Matrix* mat, float scalar, Matrix* result);
;------------------------------------------------------------------------------
asm_matrix_scalar_mul:
    mov r12, [rcx+8]
    imul r12, [rcx+16]
    mov rcx, [rcx]
    mov r8, [r8]
scalar_loop8:
    cmp r12, 0
    jle scalar_done
    cmp r12, 8
    jl scalar_loop1
    sub r12, 8
    vmovups ymm0, [rcx + r12*4]
    vbroadcastss ymm1, xmm1
    vmulps ymm0, ymm1, ymm0
    vmovups [r8 + r12*4], ymm0
    jmp scalar_loop8
scalar_loop1:
    cmp r12, 0
    jle scalar_done
    dec r12
    movss xmm0, [rcx + r12*4]
    mulps xmm0, xmm1
    movss [r8 + r12*4], xmm0
    jmp scalar_loop1
scalar_done:
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_multiply(Matrix* a, Matrix* b, Matrix* result);
;------------------------------------------------------------------------------
asm_matrix_multiply:
    push rbp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15
    mov rax, [rcx+16]       ; A_cols
    mov r10, [rdx+8]        ; B_rows
    cmp rax, r10
    jne matrix_error_exit
    mov rsi, [rcx]          ; A->data
    mov rdi, [rdx]          ; B->data
    mov rbx, [r8]           ; result->data
    mov r9, [rcx+8]         ; A_rows
    mov r10, [rcx+16]       ; A_cols
    mov r11, [rdx+16]       ; B_cols
    mov r15, r11
    shl r15, 2              ; r15 = B_cols * 4
    mov rbp, r10
    shl rbp, 2              ; rbp = A_cols * 4
    xor r12, r12            ; i = 0
outer_loop:
    cmp r12, r9
    jge done_outer_loop
    mov rax, r12
    imul rax, r15         ; offset for current result row
    mov rdx, rbx
    add rdx, rax          ; pointer to current result row
    xor r13, r13          ; column offset = 0
inner_loop:
    cmp r13, r15
    jge next_row
    mov rax, r15
    sub rax, r13
    cmp rax, 32
    jl scalar_remainder
    vxorps ymm0, ymm0, ymm0
    xor r14, r14          ; k = 0
vector_loop_k:
    cmp r14, r10
    jge vector_store_block
    vmovss xmm1, [rsi + r14*4]
    vbroadcastss ymm2, xmm1
    ; Compute address for B[k][j...j+7]:
    mov rax, r14
    imul rax, r15         ; rax = k * B_row_stride (in bytes)
    add rax, r13          ; add current column offset
    add rax, rdi          ; add B->data pointer
    vmovaps ymm3, [rax]
    vfmadd231ps ymm0, ymm2, ymm3
    inc r14
    jmp vector_loop_k
vector_store_block:
    vmovaps [rdx + r13], ymm0
    add r13, 32
    jmp inner_loop
scalar_remainder:
    mov rax, r15
    sub rax, r13
    shr rax, 2            ; number of remaining floats
    mov rcx, rax
    xor r8, r8            ; j = 0
scalar_loop_j:
    cmp r8, rcx
    jge next_row
    mov rax, r8
    imul rax, 4
    add rax, r13          ; rax = byte offset in result row
    vxorps xmm0, xmm0, xmm0
    xor r14, r14          ; k = 0
scalar_loop_k:
    cmp r14, r10
    jge scalar_store
    vmovss xmm1, [rsi + r14*4]
    push rcx              ; save rcx
    mov rcx, r14
    imul rcx, r15
    add rcx, rax
    add rcx, rdi
    vmovss xmm2, [rcx]
    pop rcx               ; restore rcx
    vfmadd231ss xmm0, xmm1, xmm2
    inc r14
    jmp scalar_loop_k
scalar_store:
    vmovss [rdx + rax], xmm0
    inc r8
    jmp scalar_loop_j
next_row:
    add rsi, rbp
    inc r12
    jmp outer_loop
done_outer_loop:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret
matrix_error_exit:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret


;------------------------------------------------------------------------------
; Function: asm_matrix_sub(Matrix* a, Matrix* b, Matrix* result);
;------------------------------------------------------------------------------
global asm_matrix_sub
asm_matrix_sub:
    push r12
    mov r8, [r8]
    mov r12, [rcx+8]
    cmp r12, [rdx+8]
    jne error_exit
    imul r12, [rcx+16]
    mov rax, [rcx+16]
    cmp rax, [rdx+16]
    jne error_exit
    mov rcx, [rcx]
    mov rdx, [rdx]
sub_loop8:
    cmp r12, 0
    jle sub_done
    cmp r12, 8
    jl sub_scalar
    sub r12, 8
    vmovups ymm0, [rcx + r12*4]
    vmovups ymm1, [rdx + r12*4]
    vsubps ymm0, ymm0, ymm1
    vmovups [r8 + r12*4], ymm0
    jmp sub_loop8
sub_scalar:
    vzeroupper
sub_loop1:
    cmp r12, 0
    jle sub_done
    dec r12
    movss xmm0, [rcx + r12*4]
    subss xmm0, [rdx + r12*4]
    movss [r8 + r12*4], xmm0
    jmp sub_loop1
sub_done:
    pop r12
    ret


