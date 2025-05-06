; Matrices stored as submatrices

section .text
extern _aligned_malloc, realloc, _aligned_free, memset


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
;   The calculation of offset in this implementation is harder than ususally.
;   Let's suppose the submatix to be 2x2, lets call it's side length S=2
;   The offset is row*row_size/R
;   normally offset is
;   offset = row_index*col_num + col_index
;   here it'll be
;   matrix_index = row_index/S*col_num/S + col_index/S
;   number of submatricies = ROW_NUM/S
;   submatrix index=   ROW_NUM/S
;
;
;   0 1 4 5
;   2 3 6 7
;   8 9 C D
;   A B E F
 asm_matrix_set:
     cmp rdx, [rcx + 8]
     jae error_exit
     cmp r8, [rcx + 16]
     jae error_exit
     mov rax, [rcx]
     imul rdx, [rcx + 16]
     add rdx, r8
     movss [rax + rdx*4], xmm3
     ret
