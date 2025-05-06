# Matrix ASM — High‑Performance Matrix Library in x86‑64 Assembly
A tiny learning project that implements core matrix operations (creation, arithmetic, and multiplication—including an optimized Strassen algorithm) **entirely in handwritten x86‑64 assembly** with a C test‑harness.

---

## ✨ Key Features

| Operation | Symbol | Implemented in ASM | Notes |
|-----------|--------|--------------------|-------|
| Create / Free | `asm_matrix_create`, `asm_matrix_free` | ✔ | Heap‑allocated, contiguous `float` buffer. |
| Element Access | `asm_matrix_get`, `asm_matrix_set` | ✔ | Bounds‑checked (out‑of‑range ⇒ returns 0). |
| Addition / Subtraction | `asm_matrix_add`, `asm_matrix_sub` | ✔ | Row‑major with pointer arithmetic. |
| Scalar Multiply | `asm_matrix_scalar_mul` | ✔ | In‑place & out‑of‑place versions (see header). |
| Naïve × | `asm_matrix_multiply` | ✔ | m × k by k × n (any dims). |
| Strassen × | `asm_matrix_strassen` | ✔ | Falls back to naïve for N ≤ 64. |

---

## 📂 Directory Layout
    .
    ├── asm/
    │   ├── matrix_strassen.asm   # full Strassen routine (this file)
    │   └── ...                   # other *.asm kernels
    ├── include/
    │   └── matrix.h              # Matrix struct & prototypes
    ├── src/
    │   └── tests.c               # exhaustive correctness & speed tests
    └── README.md                 # ← you are here

---




---

## 🧪Running the Test‑Suite
The test driver (`tests.c`) exercises:

* **Correctness** for create/free, element access, add, scalar ×, naïve ×, Strassen ×
* **Edge cases** (out‑of‑bounds reads)
* **Size‑stress** (16×16, 32×32)
* **Benchmarks** (addition, scalar ×, naïve×, Strassen×)

Example output:

    $ ./matrix_tests
    Starting matrix tests...
    [PASS] Matrix Creation
    [PASS] Matrix Free
    ...
    All matrix tests completed successfully.

    Starting speed tests...
    Speed Test: Matrix Addition 128x128 …

Uncomment the 4096 × 4096 blocks in `tests.c` for a torture run (may take minutes and several GB of RAM).

---

## ⚙️ Customization
* **Threshold tuning**: In `asm_matrix_strassen` the cut‑over from Strassen to naïve occurs at `N ≤ 64`. Change that constant to suit your CPU/cache.
* **Alignment**: The allocator currently returns `float`‑aligned buffers. For AVX‑512 you may want 64‑byte alignment.

---

## 💡 Roadmap & Ideas
* AVX2 / AVX‑512 vectorization for the naïve kernel
* Parallel Strassen (OpenMP or Win32 threads)
* Optional blocked naïve multiply as an alternative to Strassen

---



