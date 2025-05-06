#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>  // For timing functions

/*
 * The tests were written by LLM
 * I only write assembly code for now
 * I will probably write some more tests later
 */


#define COLOR_RED    "\x1b[31m"
#define COLOR_GREEN  "\x1b[32m"
#define COLOR_YELLOW "\x1b[33m"
#define COLOR_RESET  "\x1b[0m"

// Hypothetical Matrix struct definition
typedef struct {
    float *data;
    int rows;
    int cols;
} Matrix;

// Assembly-implemented matrix functions
extern "C" Matrix* asm_matrix_create(int rows, int cols);
extern "C" void asm_matrix_free(Matrix* mat);
extern "C" float asm_matrix_get(Matrix* mat, int row, int col);
extern "C" void asm_matrix_set(Matrix* mat, int row, int col, float value);
extern "C" void asm_matrix_add(Matrix* a, Matrix* b, Matrix* result);
extern "C" void asm_matrix_multiply(Matrix* a, Matrix* b, Matrix* result);
extern "C" void asm_matrix_scalar_mul(Matrix* mat, float scalar, Matrix* result);
extern "C" void asm_matrix_strassen(Matrix* a, Matrix* b, Matrix* result);


int float_equal(float a, float b, float tol) {
    return fabs(a - b) < tol;
}

#define REPORT_FAIL(test, msg) \
    do { \
        printf(COLOR_RED "[FAIL] %s: %s\n" COLOR_RESET, test, msg); \
        errors++; \
    } while (0)

#define REPORT_PASS(test) \
    printf(COLOR_GREEN "[PASS] %s\n" COLOR_RESET, test)

// Test: Matrix Creation
int test_matrix_create() {
    int errors = 0;
    const char *test_name = "Matrix Creation";
    Matrix *mat = asm_matrix_create(3, 4);
    if (mat == NULL) {
        REPORT_FAIL(test_name, "Matrix creation returned NULL.");
        return errors;
    }
    // Assuming the matrix is zero-initialized:
    for (int i = 0; i < 3; i++) {
        for (int j = 0; j < 4; j++) {
            if (!float_equal(asm_matrix_get(mat, i, j), 0.0f, 1e-6)) {
                REPORT_FAIL(test_name, "Matrix not initialized to 0.");
                goto cleanup;
            }
        }
    }
cleanup:
    if (errors == 0)
        REPORT_PASS(test_name);
    asm_matrix_free(mat);
    return errors;
}

// Test: Matrix Set & Get
int test_matrix_set_get() {
    int errors = 0;
    const char *test_name = "Matrix Set & Get";
    Matrix *mat = asm_matrix_create(2, 2);
    asm_matrix_set(mat, 0, 0, 1.0f);
    asm_matrix_set(mat, 0, 1, 2.0f);
    asm_matrix_set(mat, 1, 0, 3.0f);
    asm_matrix_set(mat, 1, 1, 4.0f);

    if (!float_equal(asm_matrix_get(mat, 0, 0), 1.0f, 1e-6) ||
        !float_equal(asm_matrix_get(mat, 0, 1), 2.0f, 1e-6) ||
        !float_equal(asm_matrix_get(mat, 1, 0), 3.0f, 1e-6) ||
        !float_equal(asm_matrix_get(mat, 1, 1), 4.0f, 1e-6))
    {
        REPORT_FAIL(test_name, "Incorrect values retrieved.");
    }
    if (errors == 0)
        REPORT_PASS(test_name);
    asm_matrix_free(mat);
    return errors;
}

// Test: Matrix Free
int test_matrix_free() {
    int errors = 0;
    const char *test_name = "Matrix Free";
    Matrix *mat = asm_matrix_create(2, 2);
    asm_matrix_set(mat, 0, 0, 1.0f);
    asm_matrix_set(mat, 0, 1, 2.0f);
    asm_matrix_set(mat, 1, 0, 3.0f);
    asm_matrix_set(mat, 1, 1, 4.0f);
    asm_matrix_free(mat);
    REPORT_PASS(test_name);
    return errors;
}

// Test: Matrix Edge Cases (e.g. out-of-bound access)
int test_matrix_edge_cases() {
    int errors = 0;
    const char *test_name = "Matrix Edge Cases";
    Matrix *mat = asm_matrix_create(3, 3);
    // Expect out-of-bounds access to return a default value (e.g. 0.0f)
    if (!float_equal(asm_matrix_get(mat, 5, 5), 0.0f, 1e-6))
        REPORT_FAIL(test_name, "Out-of-bound access did not return default value.");
    if (errors == 0)
        REPORT_PASS(test_name);
    asm_matrix_free(mat);
    return errors;
}

// Test: Matrix Addition
int test_matrix_addition() {
    int errors = 0;
    const char *test_name = "Matrix Addition";
    Matrix *a = asm_matrix_create(2, 2);
    Matrix *b = asm_matrix_create(2, 2);
    Matrix *result = asm_matrix_create(2, 2);

    // Initialize matrices:
    // a = [ [1, 2],
    //       [3, 4] ]
    asm_matrix_set(a, 0, 0, 1.0f);
    asm_matrix_set(a, 0, 1, 2.0f);
    asm_matrix_set(a, 1, 0, 3.0f);
    asm_matrix_set(a, 1, 1, 4.0f);

    // b = [ [5, 6],
    //       [7, 8] ]
    asm_matrix_set(b, 0, 0, 5.0f);
    asm_matrix_set(b, 0, 1, 6.0f);
    asm_matrix_set(b, 1, 0, 7.0f);
    asm_matrix_set(b, 1, 1, 8.0f);

    // Expected result = [ [6, 8],
    //                     [10, 12] ]
    asm_matrix_add(a, b, result);
    if (!float_equal(asm_matrix_get(result, 0, 0), 6.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 0, 1), 8.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 0), 10.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 1), 12.0f, 1e-6))
    {
        REPORT_FAIL(test_name, "Incorrect matrix addition result.");
    }
    if (errors == 0)
        REPORT_PASS(test_name);
    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
    return errors;
}

// Test: Matrix Multiplication
int test_matrix_multiplication() {
    int errors = 0;
    const char *test_name = "Matrix Multiplication";
    // For multiplication: A (2x3) * B (3x2) = C (2x2)
    Matrix *a = asm_matrix_create(2, 3);
    Matrix *b = asm_matrix_create(3, 2);
    Matrix *result = asm_matrix_create(2, 2);

    // A = [ [1, 2, 3],
    //       [4, 5, 6] ]
    asm_matrix_set(a, 0, 0, 1.0f);
    asm_matrix_set(a, 0, 1, 2.0f);
    asm_matrix_set(a, 0, 2, 3.0f);
    asm_matrix_set(a, 1, 0, 4.0f);
    asm_matrix_set(a, 1, 1, 5.0f);
    asm_matrix_set(a, 1, 2, 6.0f);

    // B = [ [7, 8],
    //       [9, 10],
    //       [11, 12] ]
    asm_matrix_set(b, 0, 0, 7.0f);
    asm_matrix_set(b, 0, 1, 8.0f);
    asm_matrix_set(b, 1, 0, 9.0f);
    asm_matrix_set(b, 1, 1, 10.0f);
    asm_matrix_set(b, 2, 0, 11.0f);
    asm_matrix_set(b, 2, 1, 12.0f);

    // Expected result:
    // [ 1*7 + 2*9 + 3*11,  1*8 + 2*10 + 3*12 ] = [ 58, 64 ]
    // [ 4*7 + 5*9 + 6*11,  4*8 + 5*10 + 6*12 ] = [139,154]
    asm_matrix_multiply(a, b, result);
    if (!float_equal(asm_matrix_get(result, 0, 0), 58.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 0, 1), 64.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 0), 139.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 1), 154.0f, 1e-6))
    {
        REPORT_FAIL(test_name, "Incorrect matrix multiplication result.");
    }
    if (errors == 0)
        REPORT_PASS(test_name);
    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
    return errors;
}

// Test: Matrix Scalar Multiplication
int test_matrix_scalar_multiplication() {
    int errors = 0;
    const char *test_name = "Matrix Scalar Multiplication";
    Matrix *mat = asm_matrix_create(2, 3);
    Matrix *result = asm_matrix_create(2, 3);

    // mat = [ [1, 2, 3],
    //         [4, 5, 6] ]
    asm_matrix_set(mat, 0, 0, 1.0f);
    asm_matrix_set(mat, 0, 1, 2.0f);
    asm_matrix_set(mat, 0, 2, 3.0f);
    asm_matrix_set(mat, 1, 0, 4.0f);
    asm_matrix_set(mat, 1, 1, 5.0f);
    asm_matrix_set(mat, 1, 2, 6.0f);

    float scalar = 2.0f;
    // Expected result = [ [2, 4, 6],
    //                     [8, 10,12] ]
    asm_matrix_scalar_mul(mat, scalar, result);
    if (!float_equal(asm_matrix_get(result, 0, 0), 2.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 0, 1), 4.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 0, 2), 6.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 0), 8.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 1), 10.0f, 1e-6) ||
        !float_equal(asm_matrix_get(result, 1, 2), 12.0f, 1e-6))
    {
        REPORT_FAIL(test_name, "Incorrect scalar multiplication result.");
    }
    if (errors == 0)
        REPORT_PASS(test_name);
    asm_matrix_free(mat);
    asm_matrix_free(result);
    return errors;
}

// Test: Matrix Multiplication for 16x16 Matrices
int test_matrix_multiplication_16x16() {
    int errors = 0;
    const char *test_name = "Matrix Multiplication (16x16)";
    int size = 16;

    // Create matrices: A and B are 16x16; result will be 16x16.
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrix A with sequential values:
    // A[i][j] = i * size + j + 1, for i,j = 0...15.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(a, i, j, (float)(i * size + j + 1));
        }
    }

    // Fill matrix B with sequential values using the same pattern.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(b, i, j, (float)(i * size + j + 1));
        }
    }

    // Compute expected result using a simple C implementation:
    // expected[i][j] = sum_{k=0}^{15} A[i][k] * B[k][j]
    float expected[16][16];
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float sum = 0.0f;
            for (int k = 0; k < size; k++) {
                // A[i][k] = i*size + k + 1, B[k][j] = k*size + j + 1.
                float a_val = (float)(i * size + k + 1);
                float b_val = (float)(k * size + j + 1);
                sum += a_val * b_val;
            }
            expected[i][j] = sum;
        }
    }

    // Use the assembly multiplication function.
    asm_matrix_multiply(a, b, result);

    // Check each element against the expected result.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float res_val = asm_matrix_get(result, i, j);
            if (!float_equal(res_val, expected[i][j], 1e-3)) {
                char msg[256];
                snprintf(msg, sizeof(msg), "Incorrect value at (%d, %d): expected %.3f, got %.3f",
                         i, j, expected[i][j], res_val);
                REPORT_FAIL(test_name, msg);
                errors++;
            }
        }
    }

    if (errors == 0)
        REPORT_PASS(test_name);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
    return errors;
}

// Test: Matrix Multiplication for 32x32 Matrices
int test_matrix_multiplication_32x32() {
    int errors = 0;
    const char *test_name = "Matrix Multiplication (32x32)";
    int size = 32;

    // Create matrices: A and B are 32x32; result will be 32x32.
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrix A with sequential values:
    // A[i][j] = i * size + j + 1, for i,j = 0...31.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(a, i, j, (float)(i * size + j + 1));
        }
    }

    // Fill matrix B with sequential values using the same pattern.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(b, i, j, (float)(i * size + j + 1));
        }
    }

    // Compute expected result using a simple C implementation:
    // expected[i][j] = sum_{k=0}^{31} A[i][k] * B[k][j]
    float expected[32][32];
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float sum = 0.0f;
            for (int k = 0; k < size; k++) {
                // A[i][k] = i*size + k + 1, B[k][j] = k*size + j + 1.
                float a_val = (float)(i * size + k + 1);
                float b_val = (float)(k * size + j + 1);
                sum += a_val * b_val;
            }
            expected[i][j] = sum;
        }
    }

    // Multiply A and B using the assembly function.
    asm_matrix_multiply(a, b, result);

    // Validate each element against the expected result.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float res_val = asm_matrix_get(result, i, j);
            if (!float_equal(res_val, expected[i][j], 1e-3)) {
                char msg[256];
                snprintf(msg, sizeof(msg), "Incorrect value at (%d, %d): expected %.3f, got %.3f",
                         i, j, expected[i][j], res_val);
                REPORT_FAIL(test_name, msg);
                errors++;
            }
        }
    }

    if (errors == 0)
        REPORT_PASS(test_name);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
    return errors;
}



// Speed test for matrix addition.
void speed_test_matrix_addition(int size, int iterations) {
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrices with sequential values.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float val = (float)(i * size + j + 1);
            asm_matrix_set(a, i, j, val);
            asm_matrix_set(b, i, j, val);
        }
    }

    clock_t start = clock();
    for (int iter = 0; iter < iterations; iter++) {
        asm_matrix_add(a, b, result);
    }
    clock_t end = clock();

    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf(COLOR_YELLOW "Speed Test: Matrix Addition %dx%d, %d iterations, total time: %.6f seconds, average time per addition: %.6f seconds.\n" COLOR_RESET,
           size, size, iterations, time_spent, time_spent / iterations);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
}

// Speed test for matrix scalar multiplication.
void speed_test_matrix_scalar_multiplication(int size, int iterations, float scalar) {
    Matrix *mat = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrix with sequential values.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(mat, i, j, (float)(i * size + j + 1));
        }
    }

    clock_t start = clock();
    for (int iter = 0; iter < iterations; iter++) {
        asm_matrix_scalar_mul(mat, scalar, result);
    }
    clock_t end = clock();

    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf(COLOR_YELLOW "Speed Test: Matrix Scalar Multiplication %dx%d, %d iterations, scalar=%.2f, total time: %.6f seconds, average time per multiplication: %.6f seconds.\n" COLOR_RESET,
           size, size, iterations, scalar, time_spent, time_spent / iterations);

    asm_matrix_free(mat);
    asm_matrix_free(result);
}
void speed_test_matrix_multiplication_4096() {
    int size = 4096;
    int iterations = 1;  // Use only one iteration due to the heavy computation.
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrices with sequential values.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float val = (float)(i * size + j + 1);
            asm_matrix_set(a, i, j, val);
            asm_matrix_set(b, i, j, val);
        }
    }

    clock_t start = clock();
    for (int iter = 0; iter < iterations; iter++) {
        asm_matrix_multiply(a, b, result);
    }
    clock_t end = clock();

    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf(COLOR_YELLOW "Speed Test: Matrix Multiplication %dx%d, %d iteration, total time: %.6f seconds, average time: %.6f seconds.\n" COLOR_RESET,
           size, size, iterations, time_spent, time_spent / iterations);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
}

// Test: Matrix Strassen Multiplication (Base Case: 1x1)
// This test multiplies two 1x1 matrices using Strassen's algorithm.
int test_matrix_strassen_1x1() {
    int errors = 0;
    const char *test_name = "Matrix Strassen (1x1)";
    Matrix *a = asm_matrix_create(1, 1);
    Matrix *b = asm_matrix_create(1, 1);
    Matrix *result = asm_matrix_create(1, 1);

    // Set a[0][0] = 2.0 and b[0][0] = 3.0; expected result = 6.0.
    asm_matrix_set(a, 0, 0, 2.0f);
    asm_matrix_set(b, 0, 0, 3.0f);

    // Call the assembly-implemented Strassen multiplication.
    asm_matrix_strassen(a, b, result);

    // Check the result.
    if (!float_equal(asm_matrix_get(result, 0, 0), 6.0f, 1e-6)) {
        REPORT_FAIL(test_name, "Incorrect multiplication result for 1x1 matrix.");
        errors++;
    } else {
        REPORT_PASS(test_name);
    }

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
    return errors;
}

// Test: Matrix Strassen Multiplication (16x16)
// Fills matrices A and B with sequential values, computes the expected result using naive multiplication,
// and compares the output of asm_matrix_strassen to the expected values.
int test_matrix_strassen_16x16() {
    int errors = 0;
    const char *test_name = "Matrix Strassen (16x16)";
    int size = 16;
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);
    float expected[16][16];

    // Fill matrix A with sequential values: A[i][j] = i * size + j + 1.
    int val = 1;
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(a, i, j, (float)val);
            val++;
        }
    }

    // Fill matrix B with sequential values: B[i][j] = i * size + j + 1.
    val = 1;
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            asm_matrix_set(b, i, j, (float)val);
            val++;
        }
    }

    // Compute expected result using a naive multiplication.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float sum = 0.0f;
            for (int k = 0; k < size; k++) {
                sum += asm_matrix_get(a, i, k) * asm_matrix_get(b, k, j);
            }
            expected[i][j] = sum;
        }
    }

    // Call the assembly-implemented Strassen multiplication.
    asm_matrix_strassen(a, b, result);

    // Validate the result element-by-element.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float res_val = asm_matrix_get(result, i, j);
            if (!float_equal(res_val, expected[i][j], 1e-3)) {
                char msg[256];
                snprintf(msg, sizeof(msg), "Incorrect value at (%d, %d): expected %.3f, got %.3f",
                         i, j, expected[i][j], res_val);
                REPORT_FAIL(test_name, msg);
                errors++;
            }
        }
    }
    if (errors == 0)
        REPORT_PASS(test_name);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
    return errors;
}


void speed_test_matrix_strassen(int size, int iterations) {
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrices with sequential values.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float val = (float)(i * size + j + 1);
            asm_matrix_set(a, i, j, val);
            asm_matrix_set(b, i, j, val);
        }
    }

    clock_t start = clock();
    for (int iter = 0; iter < iterations; iter++) {
        asm_matrix_strassen(a, b, result);
    }
    clock_t end = clock();

    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf(COLOR_YELLOW "Speed Test: Matrix Strassen Multiplication %dx%d, %d iterations, total time: %.6f seconds, average time per multiplication: %.6f seconds.\n" COLOR_RESET,
           size, size, iterations, time_spent, time_spent / iterations);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
}

// Dedicated speed test for 4096x4096 matrices using Strassen multiplication.
void speed_test_matrix_strassen_4096() {
    int size = 4096;
    int iterations = 1;  // One iteration due to heavy computation.
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrices with sequential values.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float val = (float)(i * size + j + 1);
            asm_matrix_set(a, i, j, val);
            asm_matrix_set(b, i, j, val);
        }
    }

    clock_t start = clock();
    for (int iter = 0; iter < iterations; iter++) {
        asm_matrix_strassen(a, b, result);
    }
    clock_t end = clock();

    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf(COLOR_YELLOW "Speed Test: Matrix Strassen Multiplication %dx%d, %d iteration, total time: %.6f seconds, average time: %.6f seconds.\n" COLOR_RESET,
           size, size, iterations, time_spent, time_spent / iterations);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
}


// Speed test for matrix multiplication.
void speed_test_matrix_multiplication(int size, int iterations) {
    Matrix *a = asm_matrix_create(size, size);
    Matrix *b = asm_matrix_create(size, size);
    Matrix *result = asm_matrix_create(size, size);

    // Fill matrices with sequential values.
    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            float val = (float)(i * size + j + 1);
            asm_matrix_set(a, i, j, val);
            asm_matrix_set(b, i, j, val);
        }
    }

    clock_t start = clock();
    for (int iter = 0; iter < iterations; iter++) {
        asm_matrix_multiply(a, b, result);
    }
    clock_t end = clock();

    double time_spent = (double)(end - start) / CLOCKS_PER_SEC;
    printf(COLOR_YELLOW "Speed Test: Matrix Multiplication %dx%d, %d iterations, total time: %.6f seconds, average time per multiplication: %.6f seconds.\n" COLOR_RESET,
           size, size, iterations, time_spent, time_spent / iterations);

    asm_matrix_free(a);
    asm_matrix_free(b);
    asm_matrix_free(result);
}

int main() {
    int total_errors = 0;
    printf(COLOR_YELLOW "Starting matrix tests...\n" COLOR_RESET);

    total_errors += test_matrix_create();
    total_errors += test_matrix_free();
    total_errors += test_matrix_set_get();
    total_errors += test_matrix_edge_cases();
    total_errors += test_matrix_addition();
    total_errors += test_matrix_scalar_multiplication();
    total_errors += test_matrix_strassen_1x1();
    total_errors += test_matrix_strassen_16x16();
    total_errors += test_matrix_multiplication_16x16();
    total_errors += test_matrix_multiplication();
    total_errors += test_matrix_multiplication_32x32();

    if (total_errors == 0)
        printf(COLOR_GREEN "\nAll matrix tests completed successfully.\n" COLOR_RESET);
    else
        printf(COLOR_RED "\nTotal errors encountered: %d\n" COLOR_RESET, total_errors);

    printf(COLOR_YELLOW "\nStarting speed tests...\n" COLOR_RESET);
    speed_test_matrix_multiplication(128, 100);
    speed_test_matrix_addition(128, 1000);
    speed_test_matrix_scalar_multiplication(128, 1000, 2.0f);
  //  speed_test_matrix_multiplication_4096();

    // Additional speed tests for naive multiplication
    printf(COLOR_YELLOW "\nStarting additional speed tests for naive multiplication (64x64, 128x128, 256x256)...\n" COLOR_RESET);
    speed_test_matrix_multiplication(64, 1000);
    speed_test_matrix_multiplication(128, 500);
    speed_test_matrix_multiplication(256, 100);
    speed_test_matrix_multiplication(512, 100);



    // Additional speed tests for Strassen multiplication
    printf(COLOR_YELLOW "\nStarting additional speed tests for Strassen multiplication (64x64, 128x128, 256x256)...\n" COLOR_RESET);
    speed_test_matrix_strassen(64, 1000);
    speed_test_matrix_strassen(128, 500);
    speed_test_matrix_strassen(256, 100);
    speed_test_matrix_strassen(512, 100);



    // Speed test for Strassen multiplication 4096x4096
 //   printf(COLOR_YELLOW "\nStarting speed test for Strassen multiplication (4096x4096)...\n" COLOR_RESET);
 //   speed_test_matrix_strassen_4096();

    return total_errors;
}