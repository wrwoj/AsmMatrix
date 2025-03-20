; Most naive implementation, matricies stores row/column wise
; Row-major storage
; Multiplication using traditional means
; This won't be very good, however it'll usefull to establish
; baseline of time and memory usage to compare with the double
; storage version.


section .text

global asm_matrix_create, asm_matrix_free, asm_matrix_add, asm_matrix_mul, asm_matrix_scalar_mul
global asm_matrix_get, asm_matrix_set, asm_matrix_size, asm_matrix_capacity, asm_matrix_transpose
global asm_matrix_multiply
extern _aligned_malloc, realloc, _aligned_free, memset

; to prevent crashes
error_exit:
    xor rax, rax
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_create(int rows, int cols)
; Arguments:
;   - RCX: number of rows
;   - RDX: number of columns
; Returns:
;   - RAX: pointer to the struct
;------------------------------------------------------------------------------
asm_matrix_create:
    push rdi                      ; non volatile register
    push rsi
    mov rdi, rdx                  ; we need to preserve the number of rows and columns
    mov rsi, rcx                  ; in a non-volatile registers, since calls can mutilate them
                                  ; also we need to uce rcx and rdx for passing parameters
    sub rsp, 32                   ; allocate shadow space
    mov rcx, 24                   ; 3 qwords for the struct
    mov rdx, 16                   ; alignment
    call _aligned_malloc
    test rax, rax
    je error_exit
    mov [rax+8], rsi             ; put number of rows into struct
    mov [rax+16], rdi             ; put number of columns into struct
    mov rdi, rax                  ; preserve pointer
    mov rcx, rsi                  ; number of rows into the rcx
    imul rcx, [rdi+16]            ; calculate number of elements
    shl rcx, 2                    ; calculate the collective size of all elements
    mov rsi, rcx
    mov rdx, 16                   ; alignment
    call _aligned_malloc
    test rax, rax
    je error_exit
    mov [rdi], rax               ; store array pointer
    mov rcx, [rdi]    ; rdi contains pointer
    mov rdx, 0
    mov r8, rsi ; rsi contains size
    call memset



    mov rax, rdi                 ; return pointer
    add rsp, 32
    pop rsi
    pop rdi
    ret

;------------------------------------------------------------------------------
; Function: asm_matrix_free(Matrix* mat)
; Arguments:
;   - RCX: pointer to struct
; Returns:
;   - Nothing
;------------------------------------------------------------------------------
asm_matrix_free:
    push rdi            ; needed for preservation of pointers between function calls
    test rcx, rcx       ; test if pointer passed was null
    je error_exit       ; prevent crashes
    sub rsp, 32         ; allocate shadowspace

    mov rdi, rcx        ; move pointer to non volatile register
    mov rcx, [rdi]      ; move pointer to data to rcx, to be passed as an argument
    call _aligned_free
    mov rcx, rdi        ; move pointer to struct to rcx, to be passed as an argument
    call _aligned_free

    add rsp, 32
    pop rdi
    ret
;------------------------------------------------------------------------------
; Function: asm_matrix_set(Matrix* mat, int row, int col, float value);
; Arguments:
;   - RCX : pointer to struct
;   - RDX : row index
;   - R8  : col index
;   - XMM3: float value
; Returns:
;   - Nothing
;------------------------------------------------------------------------------
asm_matrix_set:
    cmp rdx, [rcx + 8]           ;
    jae error_exit
    cmp r8, [rcx + 16]           ;
    jae error_exit

    mov rax, [rcx]
    ; [rax]  +row number * column size + column number
    imul rdx, [rcx + 16]
    add rdx, r8
    movss [rax + rdx * 4] , xmm3
    ret
;------------------------------------------------------------------------------
; Function: asm_matrix_get(Matrix* mat, int row, int col);
; Arguments:
;   - RCX : pointer to struct
;   - RDX : row index
;   - R8  : col index
; Returns:
;   - XMM0: float value
;------------------------------------------------------------------------------
asm_matrix_get:
    cmp rdx, [rcx + 8]           ;
    jae error_exit
    cmp r8, [rcx + 16]           ;
    mov rax, [rcx]
    imul rdx, [rcx + 16]
    add rdx, r8
    movss xmm0, [rax + rdx *4]
    jae error_exit
    ret






;------------------------------------------------------------------------------
; Function: asm_matrix_add(Matrix* a, Matrix* b, Matrix* result);
; Arguments:
;   - RCX : pointer to struct a
;   - RDX : pointer to struct b
;   - R8  : pointer to struct result
; Returns:
;   - Nothing
;------------------------------------------------------------------------------
asm_matrix_add:
    mov r8, [r8]
    mov r12, [rcx  +8] ; load the number of rows of matrix a into r12
    cmp r12, [rdx  +8] ; compare the numbers of rows of maricies a and b
    jne error_exit     ; if not equal addition impossible

    imul r12, [rcx+16] ; calculate number of elements
    mov rax, [rcx +16] ; load the number of columns of matrix a into rax
    cmp rax, [rdx +16] ; compare the numbers of columns of maricies a and b
    jne error_exit     ; if not equal addition impossible
    mov rcx, [rcx]
    mov rdx, [rdx]
add_loop8:
    cmp     r12, 0
    jle     add_done
    ; Check if at least 8 floats remain; if not, go to scalar loop
    ; mov     r10, r12
    ; sub     r10, rax
    cmp     r12, 8
    jl      add_loop1
    sub     r12, 8
    ; Process 8 floats at once:
    vmovaps  ymm0, [rcx + r12*4]   ; load 8 floats from src a
    vmovaps  ymm1, [rdx + r12*4]   ; load 8 floats from src b
    vaddps   ymm0, ymm1            ;
    vmovaps  [r8 + r12*4], ymm0    ; store 8 floats to dst

    jmp    add_loop8

add_loop1:
    cmp     r12, 0
    jle     add_done
    ; Process any remaining elements one by one:
    dec     r12
    movss   xmm0, [rcx  + r12*4]
    movss   xmm1, [rdx + r12*4]
    addss   xmm0, xmm1
    movss   [r8 + r12*4], xmm0
    jmp     add_loop1
add_done:
    ret




;------------------------------------------------------------------------------
; Function: asm_matrix_scalar_mul(Matrix* mat, float scalar, Matrix* result);
; Arguments:
;   - RCX : pointer to struct a
;   - RDX : pointer to struct result
;   - XMM1: float value
; Returns:
;   - Nothing
;------------------------------------------------------------------------------
asm_matrix_scalar_mul:
    mov r12, [rcx  +8] ; load the number of rows of matrix a into r12
    imul r12, [rcx+16] ; calculate number of elements
    mov rcx, [rcx]
    mov r8, [r8]

    scalar_loop8:
    cmp     r12, 0
    jle     scalar_done
    cmp     r12, 8
    jl      scalar_loop1
    sub     r12, 8
    ; Process 8 floats at once:
    vmovaps  ymm0, [rcx + r12*4]   ; load 8 floats from src a
    vbroadcastss ymm1, xmm1
    vmulps  ymm0, ymm1, ymm0   ; load 8 floats from src b
    vmovaps  [r8 + r12*4], ymm0   ; store 8 floats to dst

    jmp    scalar_loop8
    scalar_loop1:
    cmp     r12, 0
    jle     scalar_done
    dec     r12
    movss   xmm0, [rcx  + r12*4]
    mulps   xmm0, xmm1
    movss   [r8 + r12*4], xmm0
    jmp     scalar_loop1
    scalar_done:
    ret




;------------------------------------------------------------------------------
; Function: asm_matrix_multiply(Matrix* a, Matrix* b, Matrix* result);
; Arguments:
;   - RCX : pointer to struct a
;   - RDX : pointer to struct b
;   - R8  : pointer to result struct
; Returns:
;   - Nothing
;------------------------------------------------------------------------------
; Done: added usage of SIMD instructions
; TODO: Contemplate eliminating the usage of nonvolatile registers
; TODO :Cache Optimisation
;------------------------------------------------------------------------------

asm_matrix_multiply:
    ; Prologue – save callee-saved registers (and rbp for our own use)
    push rbp
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14
    push r15

    ; --- Setup ---
    ; rcx: pointer to matrix A structure.
    ; rdx: pointer to matrix B structure.
    ; r8 : pointer to result matrix structure.

    ; Check dimensions: A_cols ([rcx+16]) must equal B_rows ([rdx+8])
    mov rax, [rcx+16]       ; rax = A_cols
    mov r10, [rdx+8]        ; r10 = B_rows
    cmp rax, r10
    jne matrix_error_exit   ; dimensions mismatch

    ; Load pointers to data arrays.
    mov rsi, [rcx]          ; rsi = pointer to A's data
    mov rdi, [rdx]          ; rdi = pointer to B's data
    mov rbx, [r8]           ; rbx = pointer to result data

    ; Load matrix dimensions.
    mov r9, [rcx+8]         ; r9 = A_rows
    mov r10, [rcx+16]       ; r10 = A_cols (also B_rows)
    mov r11, [rdx+16]       ; r11 = B_cols

    ; Compute B row stride in bytes = B_cols * 4.
    mov r15, r11
    shl r15, 2              ; r15 = B_cols * 4

    ; Compute A row stride in bytes = A_cols * 4 and store it in rbp.
    mov rbp, r10
    shl rbp, 2              ; rbp = A_cols * 4

    ; Outer loop: iterate over each row of A.
    xor r12, r12            ; r12 = row index i = 0
outer_loop:
    cmp r12, r9
    jge done_outer_loop

    ; Compute pointer to current result row:
    ; result_row_ptr = result_base (rbx) + i * (B_cols * 4)
    mov rax, r12
    imul rax, r15         ; rax = i * B_row_stride
    mov rdx, rbx          ; rdx = result base pointer
    add rdx, rax          ; now rdx points to row i of the result

    ; Inner loop: iterate over columns in the current result row.
    ; We'll process blocks of 8 floats (32 bytes) if possible.
    xor r13, r13          ; r13 = column offset (in bytes) = 0
inner_loop:
    cmp r13, r15
    jge next_row          ; if we've processed B_cols*4 bytes, move to next row

    ; Check if at least 8 floats remain (8*4 = 32 bytes)
    mov rax, r15
    sub rax, r13
    cmp rax, 32
    jl scalar_remainder   ; if fewer than 32 bytes, do scalar loop

    ; ----- Vectorized block: Process 8 floats at once -----
    vxorps ymm0, ymm0, ymm0      ; zero accumulator in ymm0

    ; Loop over the common dimension k = 0 to A_cols - 1.
    xor r14, r14          ; r14 = k = 0
vector_loop_k:
    cmp r14, r10
    jge vector_store_block

    ; Load A[i][k] from current row of A.
    vmovss xmm1, dword [rsi + r14*4]
    vbroadcastss ymm2, xmm1    ; broadcast A[i][k] to all lanes

    ; Compute address for B[k][j...j+7]:
    ; rax = B_base + k*(B_cols*4) + current column offset (r13)
    mov rax, r14
    imul rax, r15         ; rax = k * B_row_stride
    add rax, r13          ; add current block's column offset
    add rax, rdi          ; add B's data base pointer
    vmovups ymm3, [rax]   ; load 8 floats from B[k][j...j+7]

    ; FMA: accumulate A[i][k] * B[k][j...j+7] into ymm0.
    vfmadd231ps ymm0, ymm2, ymm3

    inc r14
    jmp vector_loop_k

vector_store_block:
    ; Store the computed 8-float block into the result row.
    vmovups [rdx + r13], ymm0
    add r13, 32           ; advance column offset by 32 bytes (8 floats)
    jmp inner_loop

    ; ----- Scalar remainder: process leftover columns -----
scalar_remainder:
    ; Determine how many floats remain: (B_row_stride - r13) / 4.
    mov rax, r15
    sub rax, r13
    shr rax, 2          ; rax = number of remaining floats
    mov rcx, rax        ; rcx = count of scalar columns to process

    ; Use r8 as the scalar column index j.
    xor r8, r8         ; r8 = j = 0
scalar_loop_j:
    cmp r8, rcx
    jge next_row

    ; Compute scalar offset for current element: offset = r13 + j*4.
    mov rax, r8
    imul rax, 4
    add rax, r13      ; rax now holds the byte offset in the result row

    ; Initialize accumulator (in xmm0) to 0.
    vxorps xmm0, xmm0, xmm0

    ; Loop over common dimension k for this scalar element.
    xor r14, r14     ; r14 = k = 0
scalar_loop_k:
    cmp r14, r10
    jge scalar_store

    ; Load A[i][k]
    vmovss xmm1, dword [rsi + r14*4]

    ; Compute address for B[k][j]:
    ; Use rcx as a scratch register (preserve its current value).
    push rcx            ; save rcx (which holds the scalar loop count)
    mov rcx, r14        ; use rcx for k
    imul rcx, r15       ; rcx = k * B_row_stride
    add rcx, rax        ; add the scalar offset for column j
    add rcx, rdi        ; add base pointer for B's data
    vmovss xmm2, dword [rcx]
    pop rcx             ; restore scalar loop count
    vfmadd231ss xmm0, xmm1, xmm2

    inc r14
    jmp scalar_loop_k
scalar_store:
    ; Store the computed scalar result into the result row.
    vmovss dword [rdx + rax], xmm0
    inc r8
    jmp scalar_loop_j

next_row:
    ; Finished processing the current row.
    ; Advance A pointer to the next row by A_row_stride (stored in rbp).
    add rsi, rbp

    inc r12          ; next row
    jmp outer_loop

done_outer_loop:
    ; Epilogue – restore registers and return.
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
    ; Simple error handler: dimensions mismatch.
    pop r15
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    pop rbp
    ret
