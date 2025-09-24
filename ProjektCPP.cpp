
#include "stdafx.h"
#include "header_AppMain.ai.h"

#ifndef WIN32
void strncpy_s(char* destination, int destination_size, const char* source, int numberOfCharacters)
{
    int i =0;
    while( (i < (destination_size - 1)) && (i < numberOfCharacters) && (source[i] != '\0') )
    {
        destination[i] = source[i];
        i++;
    } 
    if( i < destination_size)
    {
       destination[i] = '\0';
    }
    destination[destination_size - 1] = '\0';
}

#endif

