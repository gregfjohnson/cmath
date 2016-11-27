/* complex_test.c, Copyright (C) 2016, Greg Johnson
 * Released under the terms of the GNU GPL v2.0.
 */

/* generate test tables from C99 complex library for
 * use in complex_test.lua.
 * 
 * gcc -std=c99 -Wall -g -o complex_test complex_test.c -lm
 * ./complex_test
 *
 * output contains 100 lines each for testing complex functions:
 *  testInverseTrig
 *  testTrig
 *  testLog
 *  testSqrt
 *  testExp
 *  testAngle
 *
 * for details of the columns, consult the respective functions below.
 */

#define _GNU_SOURCE
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <stdbool.h>
#include <complex.h>

#define ROWS 3
#define COLS 8
complex testVec[ROWS*COLS];

static void cprintf(complex *array, int rows, int cols, bool outputPolar);

void testAngle() {
    double omega = 2. * M_PIl / 100;
    for (int i = 0; i < 100; ++i) {
        printf("%.16lf %.16lf %.16lf\n", cos(omega * i), sin(omega * i), omega*i);
    }
}

void testExp() {
    complex omega8 = 2 * I * M_PIl / 100;
    complex realPart = -5;
    for (int i = 0; i < 100; ++i) {
        complex data[2] = {realPart + i * omega8, cexp(realPart + i * omega8)};
        cprintf(data, 1,2, false);
        realPart += .1;
    }
}

void testLog() {
    complex omega8 = 2 * I * M_PIl / 100;
    complex realPart = -5;
    for (int i = 0; i < 100; ++i) {
        complex data[3] = {realPart + i * omega8,
                           clog(realPart + i * omega8),
                           clog10(realPart + i * omega8),
                           };
        cprintf(data, 1,3, false);
        realPart += .1;
    }
}

void testTrig() {
    complex omega8 = 2 * I * M_PIl / 100;
    complex realPart = -5;
    for (int i = 0; i < 100; ++i) {
        complex data[4] = {realPart + i * omega8,
                           csin(realPart + i * omega8),
                           ccos(realPart + i * omega8),
                           ctan(realPart + i * omega8),
                           };
        cprintf(data, 1,4, false);
        realPart += .1;
    }
}

complex normalize(complex c, double low_end) {
    double r = creal(c);
    while (r < low_end) r = 2 * low_end - r;
    while (r >= low_end + M_PIl) r = 2*(low_end+M_PIl) - r;
    return r + I * cimag(c);
    return c;
}

void testInverseTrig() {
    complex omega8 = 2 * I * M_PIl / 100;
    complex realPart = -5;
    for (int i = 0; i < 100; ++i) {
        complex data[4] = {realPart + i * omega8,
                           normalize(casin(realPart + i * omega8), -M_PIl/2),
                                    (cacos(realPart + i * omega8)),
                           normalize(catan(realPart + i * omega8), -M_PIl/2),
                           };
        cprintf(data, 1,4, false);
        realPart += .1;
    }
}

void testSqrt() {
    complex omega8 = 2 * I * M_PIl / 100;
    complex realPart = -5;
    for (int i = 0; i < 100; ++i) {
        complex data[2] = {realPart + i * omega8, csqrt(realPart + i * omega8)};
        cprintf(data, 1,2, false);
        realPart += .1;
    }
}

int main(int argc, char **argv) {
    testInverseTrig();
    testTrig();
    testLog();
    testSqrt();
    testExp();
    testAngle();
}

static double cangle(complex n) {
    return atan2(cimag(n), creal(n)) * 180. / M_PIl;
}

static void cprintf(complex *array, int rows, int cols, bool outputPolar) {
    char buf[64];
    char **realFormats;
    char **imagFormats;
    int *maxRealLen;
    int *maxImagLen;
    double data;

    realFormats = (char **) malloc(cols * sizeof(char*));
    imagFormats = (char **) malloc(cols * sizeof(char*));
    maxRealLen  = (int *)   calloc(cols, sizeof(int));
    maxImagLen  = (int *)   calloc(cols, sizeof(int));

    for (int row = 0; row < rows; ++row) {
        for (int col = 0; col < cols; ++col) {
            int len;

            data = outputPolar ? cabs(array[cols*row + col]) : creal(array[cols*row + col]);
            sprintf(buf, "%.12lf%n", data, &len);

            if (maxRealLen[col] < len) maxRealLen[col] = len;

            data = outputPolar ? cangle(array[cols*row + col]) : cimag(array[cols*row + col]);
            sprintf(buf, "%.12lf%n", data, &len);

            if (maxImagLen[col] < len) maxImagLen[col] = len;
        }
    }

    for (int col = 0; col < cols; ++col) {
        realFormats[col] = (char *) malloc(64);
        imagFormats[col] = (char *) malloc(64);
        sprintf(realFormats[col], "%c%d.12lf", '%', maxRealLen[col]);
        sprintf(imagFormats[col], " %c%d.12lf", '%', maxImagLen[col]);
    }

    for (int row = 0; row < rows; ++row) {
        for (int col = 0; col < cols; ++col) {

            data = outputPolar ? cabs(array[cols*row + col]) : creal(array[cols*row + col]);
            printf(realFormats[col], data);

            data = outputPolar ? cangle(array[cols*row + col]) : cimag(array[cols*row + col]);
            printf(imagFormats[col], data);

            if (col < cols - 1) printf("  ");
        }
        printf("\n");
    }

    for (int col = 0; col < cols; ++col) {
        free(realFormats[col]);
        free(imagFormats[col]);
    }
    free(realFormats);
    free(imagFormats);
    free(maxRealLen);
    free(maxImagLen);
}
