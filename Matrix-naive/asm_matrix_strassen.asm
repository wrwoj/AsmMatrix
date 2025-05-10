; =========================
; asm_matrix_strassen - Strassen matrix multiplication
; Windows x86_64 ABI: RCX=A, RDX=B, R8=result (Matrix* pointers)
; Optimized: single shadow reservation, no per-call rsp adjustments
; =========================

global asm_matrix_strassen
extern asm_matrix_create      ; Matrix* asm_matrix_create(int rows, int cols)
extern asm_matrix_add         ; void asm_matrix_add(Matrix* A, Matrix* B, Matrix* C)
extern asm_matrix_sub         ; void asm_matrix_sub(Matrix* A, Matrix* B, Matrix* C)
extern asm_matrix_multiply    ; void asm_matrix_multiply(Matrix* A, Matrix* B, Matrix* C)
extern asm_matrix_free        ; void asm_matrix_free(Matrix* M)

section .text
asm_matrix_strassen:
    ; Prologue
    push    rbp
    mov     rbp, rsp
    sub     rsp, 208             ; locals (176) + 32-byte shadow space

    ; Save non-volatile registers
    mov     [rbp-8], rbx
    mov     [rbp-16], rsi
    mov     [rbp-24], rdi
    mov     [rbp-32], r12
    mov     [rbp-40], r13
    mov     [rbp-48], r14
    mov     [rbp-56], r15

    ; Load inputs
    mov     rsi, rcx            ; A
    mov     rdi, rdx            ; B
    mov     rbx, r8             ; C

    ; Matrix struct offsets
%define MAT_ROWS    0
%define MAT_COLS    4
%define MAT_DATA    8

    ; Get dimensions
    mov     eax, [rsi + MAT_ROWS]    ; m = A.rows
    mov     edx, [rsi + MAT_COLS]    ; k = A.cols
    mov     ecx, [rdi + MAT_COLS]    ; n = B.cols

    ; Fallback to naive if small or non-square
    cmp     eax, 64
    jle     .do_naive
    cmp     edx, 64
    jle     .do_naive
    cmp     ecx, 64
    jle     .do_naive
    cmp     eax, edx
    jne     .do_naive
    cmp     eax, ecx
    jne     .do_naive
    test    eax, 1
    jnz     .do_naive

    ; Compute half-size n2 = N/2
    mov     r10d, eax
    shr     r10d, 1
    mov     ecx, r10d
    mov     edx, r10d

    ; Allocate quadrant matrices for A
    call    asm_matrix_create  ; x11
    mov     [rbp-64], rax
    call    asm_matrix_create  ; x12
    mov     [rbp-72], rax
    call    asm_matrix_create  ; x21
    mov     [rbp-80], rax
    call    asm_matrix_create  ; x22
    mov     [rbp-88], rax

    ; Allocate quadrant matrices for B
    call    asm_matrix_create  ; y11
    mov     [rbp-96], rax
    call    asm_matrix_create  ; y12
    mov     [rbp-104], rax
    call    asm_matrix_create  ; y21
    mov     [rbp-112], rax
    call    asm_matrix_create  ; y22
    mov     [rbp-120], rax

    ; Get data pointers
    mov     r8, [rsi + MAT_DATA]
    mov     r9, [rdi + MAT_DATA]

    ; Copy top-left and top-right quadrants of A/B
    mov     edx, 0
.top_i_loop:
    cmp     edx, r10d
    jge     .top_done
    mov     edi, edx
    imul    edi, eax              ; edi = i*N
    mov     ebx, edx
    imul    ebx, r10d             ; ebx = i*n2
    mov     ecx, 0
.top_j_loop:
    cmp     ecx, r10d
    jge     .top_j_done
    mov     r11d, edi
    add     r11d, ecx            ; idx = i*N + j
    mov     r12d, r11d
    add     r12d, r10d           ; idx2 = i*N + j + n2
    mov     r13d, ebx
    add     r13d, ecx            ; off = i*n2 + j
    movsxd  r11, r11d
    shl     r11, 3               ; byte offset
    movsxd  r12, r12d
    shl     r12, 3
    movsxd  r13, r13d
    shl     r13, 3
    mov     [rbp-128], r11
    mov     [rbp-136], r12
    mov     [rbp-144], r13
    ; A->x11,x12
    mov     r14, [rbp-64]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r8 + r11]
    mov     [r15 + r13], rax
    mov     r14, [rbp-72]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r8 + r12]
    mov     [r15 + r13], rax
    ; B->y11,y12
    mov     r14, [rbp-96]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r9 + r11]
    mov     [r15 + r13], rax
    mov     r14, [rbp-104]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r9 + r12]
    mov     [r15 + r13], rax
    inc     ecx
    jmp     .top_j_loop
.top_j_done:
    inc     edx
    jmp     .top_i_loop
.top_done:

    ; Copy bottom-left and bottom-right quadrants
    mov     edx, 0
.bot_i_loop:
    cmp     edx, r10d
    jge     .bot_done
    mov     edi, edx
    add     edi, r10d             ; row = i2 + n2
    imul    edi, eax              ; row*N
    mov     ebx, edx
    imul    ebx, r10d             ; i2*n2
    mov     ecx, 0
.bot_j_loop:
    cmp     ecx, r10d
    jge     .bot_j_done
    mov     r11d, edi
    add     r11d, ecx            ; idx = (i2+n2)*N + j
    mov     r12d, r11d
    add     r12d, r10d           ; idx2 = (i2+n2)*N + j + n2
    mov     r13d, ebx
    add     r13d, ecx            ; off = i2*n2 + j
    movsxd  r11, r11d
    shl     r11, 3
    movsxd  r12, r12d
    shl     r12, 3
    movsxd  r13, r13d
    shl     r13, 3
    mov     [rbp-128], r11
    mov     [rbp-136], r12
    mov     [rbp-144], r13
    ; A->x21,x22
    mov     r14, [rbp-80]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r8 + r11]
    mov     [r15 + r13], rax
    mov     r14, [rbp-88]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r8 + r12]
    mov     [r15 + r13], rax
    ; B->y21,y22
    mov     r14, [rbp-112]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r9 + r11]
    mov     [r15 + r13], rax
    mov     r14, [rbp-120]
    mov     r15, [r14 + MAT_DATA]
    mov     rax, [r9 + r12]
    mov     [r15 + r13], rax
    inc     ecx
    jmp     .bot_j_loop
.bot_j_done:
    inc     edx
    jmp     .bot_i_loop
.bot_done:

    ; Strassen products P1..P7
    ; P1 = (x11 + x22) * (y11 + y22)
    mov     rcx, [rbp-64]
    mov     rdx, [rbp-88]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S1
    mov     rcx, [rbp-64]
    mov     rdx, [rbp-88]
    mov     r8, [rbp-128]
    call    asm_matrix_add
    mov     rcx, [rbp-96]
    mov     rdx, [rbp-120]
    call    asm_matrix_create
    mov     [rbp-136], rax      ; S2
    mov     rcx, [rbp-96]
    mov     rdx, [rbp-120]
    mov     r8, [rbp-136]
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    call    asm_matrix_create
    mov     [rbp-144], rax      ; P1
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    mov     r8, [rbp-144]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free
    mov     rcx, [rbp-136]
    call    asm_matrix_free

    ; P2 = (x21 + x22) * y11
    mov     rcx, [rbp-80]
    mov     rdx, [rbp-88]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S3
    mov     rcx, [rbp-80]
    mov     rdx, [rbp-88]
    mov     r8, [rbp-128]
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-96]
    call    asm_matrix_create
    mov     [rbp-152], rax      ; P2
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-96]
    mov     r8, [rbp-152]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free

    ; P3 = x11 * (y12 - y22)
    mov     rcx, [rbp-104]
    mov     rdx, [rbp-120]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S4
    mov     rcx, [rbp-104]
    mov     rdx, [rbp-120]
    mov     r8, [rbp-128]
    call    asm_matrix_sub
    mov     rcx, [rbp-64]
    mov     rdx, [rbp-128]
    call    asm_matrix_create
    mov     [rbp-160], rax      ; P3
    mov     rcx, [rbp-64]
    mov     rdx, [rbp-128]
    mov     r8, [rbp-160]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free

    ; P4 = x22 * (y21 - y11)
    mov     rcx, [rbp-112]
    mov     rdx, [rbp-96]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S5
    mov     rcx, [rbp-112]
    mov     rdx, [rbp-96]
    mov     r8, [rbp-128]
    call    asm_matrix_sub
    mov     rcx, [rbp-88]
    mov     rdx, [rbp-128]
    call    asm_matrix_create
    mov     [rbp-168], rax      ; P4
    mov     rcx, [rbp-88]
    mov     rdx, [rbp-128]
    mov     r8, [rbp-168]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free

    ; P5 = (x11 + x12) * y22
    mov     rcx, [rbp-64]
    mov     rdx, [rbp-72]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S6
    mov     rcx, [rbp-64]
    mov     rdx, [rbp-72]
    mov     r8, [rbp-128]
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-120]
    call    asm_matrix_create
    mov     [rbp-176], rax      ; P5
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-120]
    mov     r8, [rbp-176]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free

    ; P6 = (x21 - x11) * (y11 + y12)
    mov     rcx, [rbp-80]
    mov     rdx, [rbp-64]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S7
    mov     rcx, [rbp-80]
    mov     rdx, [rbp-64]
    mov     r8, [rbp-128]
    call    asm_matrix_sub
    mov     rcx, [rbp-96]
    mov     rdx, [rbp-104]
    call    asm_matrix_create
    mov     [rbp-136], rax      ; S8
    mov     rcx, [rbp-96]
    mov     rdx, [rbp-104]
    mov     r8, [rbp-136]
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    call    asm_matrix_create
    mov     [rbp-184], rax      ; P6
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    mov     r8, [rbp-184]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free
    mov     rcx, [rbp-136]
    call    asm_matrix_free

    ; P7 = (x12 - x22) * (y21 + y22)
    mov     rcx, [rbp-72]
    mov     rdx, [rbp-88]
    call    asm_matrix_create
    mov     [rbp-128], rax      ; S9
    mov     rcx, [rbp-72]
    mov     rdx, [rbp-88]
    mov     r8, [rbp-128]
    call    asm_matrix_sub
    mov     rcx, [rbp-112]
    mov     rdx, [rbp-120]
    call    asm_matrix_create
    mov     [rbp-136], rax      ; S10
    mov     rcx, [rbp-112]
    mov     rdx, [rbp-120]
    mov     r8, [rbp-136]
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    call    asm_matrix_create
    mov     [rbp-192], rax      ; P7
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    mov     r8, [rbp-192]
    call    asm_matrix_strassen
    mov     rcx, [rbp-128]
    call    asm_matrix_free
    mov     rcx, [rbp-136]
    call    asm_matrix_free

    ; Combine results
    call    asm_matrix_create    ; Temp1
    mov     [rbp-128], rax
    call    asm_matrix_create    ; Temp2
    mov     [rbp-136], rax
    mov     rcx, [rbp-144]
    mov     rdx, [rbp-168]
    mov     r8, [rbp-128]
    call    asm_matrix_add
    mov     rcx, [rbp-192]
    mov     rdx, [rbp-176]
    mov     r8, [rbp-136]
    call    asm_matrix_sub
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    mov     r8, rbx
    call    asm_matrix_add
    mov     rcx, [rbp-160]
    mov     rdx, [rbp-176]
    mov     r8, rbx
    call    asm_matrix_add
    mov     rcx, [rbp-152]
    mov     rdx, [rbp-168]
    mov     r8, rbx
    call    asm_matrix_add
    mov     rcx, [rbp-144]
    mov     rdx, [rbp-152]
    mov     r8, [rbp-128]
    call    asm_matrix_sub
    mov     rcx, [rbp-160]
    mov     rdx, [rbp-184]
    mov     r8, [rbp-136]
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    mov     rdx, [rbp-136]
    mov     r8, rbx
    call    asm_matrix_add
    mov     rcx, [rbp-128]
    call    asm_matrix_free
    mov     rcx, [rbp-136]
    call    asm_matrix_free
    mov     rcx, [rbp-144]
    call    asm_matrix_free
    mov     rcx, [rbp-152]
    call    asm_matrix_free
    mov     rcx, [rbp-160]
    call    asm_matrix_free
    mov     rcx, [rbp-168]
    call    asm_matrix_free
    mov     rcx, [rbp-176]
    call    asm_matrix_free
    mov     rcx, [rbp-184]
    call    asm_matrix_free
    mov     rcx, [rbp-192]
    call    asm_matrix_free
    mov     rcx, [rbp-64]
    call    asm_matrix_free
    mov     rcx, [rbp-72]
    call    asm_matrix_free
    mov     rcx, [rbp-80]
    call    asm_matrix_free
    mov     rcx, [rbp-88]
    call    asm_matrix_free
    mov     rcx, [rbp-96]
    call    asm_matrix_free
    mov     rcx, [rbp-104]
    call    asm_matrix_free
    mov     rcx, [rbp-112]
    call    asm_matrix_free
    mov     rcx, [rbp-120]
    call    asm_matrix_free

    jmp     .done

.do_naive:
    mov     rcx, rsi
    mov     rdx, rdi
    mov     r8, rbx
    call    asm_matrix_multiply

.done:
    mov     rbx, [rbp-8]
    mov     rsi, [rbp-16]
    mov     rdi, [rbp-24]
    mov     r12, [rbp-32]
    mov     r13, [rbp-40]
    mov     r14, [rbp-48]
    mov     r15, [rbp-56]
    mov     rsp, rbp
    pop     rbp
    ret
