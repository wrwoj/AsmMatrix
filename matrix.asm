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
; TODO: add usage of SIMD operations, optimise for L1 Cache and eliminate the usage of nonvolatile registers
;------------------------------------------------------------------------------
asm_matrix_multiply:
    ; Save nonvolatile registers used: RBX, RSI, RDI, R12, R13, R14.
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    push r14

    ; Check that A’s columns equals B’s rows.
    mov rax, [rcx+16]   ; rax = A_cols
    mov r10, [rdx+8]    ; r10 = B_rows
    cmp rax, r10
    jne error_exit      ; dimensions do not match for multiplication

    ; Load pointers to the data arrays.
    mov rsi, [rcx]      ; rsi = pointer to A_data
    mov rdi, [rdx]      ; rdi = pointer to B_data
    mov rbx, [r8]       ; rbx = pointer to result data

    ; Load matrix dimensions:
    mov r9,  [rcx+8]    ; r9 = A_rows (number of rows in A)
    mov r10, [rcx+16]   ; r10 = A_cols (and B_rows)
    mov r11, [rdx+16]   ; r11 = B_cols (number of columns in B)

    ; Outer loop over rows of A (index i)
    xor r12, r12        ; r12 = i = 0
outer_loop:
    cmp r12, r9
    jge mul_done        ; if i >= A_rows, we are done

    xor r13, r13        ; r13 = j = 0
inner_loop_j:
    cmp r13, r11
    jge next_i          ; if j >= B_cols, advance to next row

    ; Initialize sum for result[i][j] to 0.0 (in xmm0)
    vxorps xmm0, xmm0, xmm0

    ; Inner loop over common dimension (index k)
    xor r14, r14        ; r14 = k = 0
inner_loop_k:
    cmp r14, r10
    jge finish_inner_j  ; if k >= A_cols, finish inner loop

    ; Calculate address for A[i][k]:
    ; Offset = (i * A_cols + k) * 4
    mov rax, r12
    imul rax, r10       ; rax = i * A_cols
    add rax, r14        ; rax = i * A_cols + k
    mov rcx, rax
    shl rcx, 2          ; multiply index by 4 (size of float)
    movss xmm1, dword [rsi + rcx]   ; xmm1 = A[i][k]

    ; Calculate address for B[k][j]:
    ; Offset = (k * B_cols + j) * 4
    mov rax, r14
    imul rax, r11       ; rax = k * B_cols
    add rax, r13        ; rax = k * B_cols + j
    mov rcx, rax
    shl rcx, 2          ; multiply index by 4
    movss xmm2, dword [rdi + rcx]   ; xmm2 = B[k][j]

    ; Multiply the two elements and accumulate into sum:
    mulss xmm1, xmm2    ; xmm1 = A[i][k] * B[k][j]
    addss xmm0, xmm1    ; sum += xmm1

    inc r14
    jmp inner_loop_k

finish_inner_j:
    ; Store the computed sum in result[i][j]:
    ; Offset = (i * B_cols + j) * 4
    mov rax, r12
    imul rax, r11       ; rax = i * B_cols
    add rax, r13        ; rax = i * B_cols + j
    mov rcx, rax
    shl rcx, 2          ; compute byte offset
    movss dword [rbx + rcx], xmm0

    inc r13
    jmp inner_loop_j

next_i:
    inc r12
    jmp outer_loop

mul_done:
    ; Restore nonvolatile registers and return.
    pop r14
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret