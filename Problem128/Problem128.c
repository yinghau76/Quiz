/*
 ============================================================================
 Name        : Problem128.c
 Author      : Patrick Tsai
 Version     :
 Copyright   : Your copyright notice
 Description : Hello World in C, Ansi-style
 ============================================================================
 */

#include <stdio.h>
#include <stdlib.h>

#define GENERATOR 34943

unsigned int compute_crc(char* msg)
{
    char* p = msg;
    unsigned int v = 0;
    
    for ( ; *p != 0; p++)
    {
        v = ((v << 8) + *p) % GENERATOR;        
    }
    
    v = (v << 16) % GENERATOR;
    return v == 0 ? 0 : GENERATOR - v;
}

int main(void)
{
    char msg[1024];
    int crc;
    
    for (;;)
    {
        gets(msg);
        if (msg[0] == '#') {
            break;
        }
        crc = compute_crc(msg);
        printf("%02X %02X\n", crc >> 8, crc & 0xff);
    }
    
    return EXIT_SUCCESS;
}
