
#pragma once
#import "gpufilter.h"

/* Convenience macro for writing shaders in C code files. */
#define SHADER_NSSTRING(x) @ #x

#ifdef TARGET_OS_MAC
#define GL_DO_NOT_WARN_IF_MULTI_GL_VERSION_HEADERS_INCLUDED
// --- OS X shader goes here
#define FRAGMENT_SHADER_FILE(x) @ #x " OS X"
#elif defined(TARGET_OS_IPHONE)
// --- iOS shader goes here
#define FRAGMENT_SHADER_FILE(x) @ #x " iOS"
#else
#error This file is only meant for OS X or iOS.
#endif
