#include <stdio.h>
#include <stdlib.h>
#include <math.h>

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



int main() {
    int total_errors = 0;
    printf(COLOR_YELLOW "Starting matrix tests...\n" COLOR_RESET);

    total_errors += test_matrix_create();
    total_errors += test_matrix_free();
    total_errors += test_matrix_set_get();


     total_errors += test_matrix_edge_cases();
     total_errors += test_matrix_addition();
     total_errors += test_matrix_scalar_multiplication();

    total_errors += test_matrix_multiplication();

    if (total_errors == 0)
        printf(COLOR_GREEN "\nAll matrix tests completed successfully.\n" COLOR_RESET);
    else
        printf(COLOR_RED "\nTotal errors encountered: %d\n" COLOR_RESET, total_errors);

    return total_errors;
}

