#pragma once

#ifdef WIN32_X86
#include "windows.h"
#else
   void strncpy_s(char* destination, int destination_size, const char* source, int numberOfCharacters);
#endif

#include <iostream>
#include <chrono>
#include <iomanip>
#include <thread>

using namespace std;
