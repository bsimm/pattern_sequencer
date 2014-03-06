#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdarg.h>

#define DEBUG_INITIALIZED 1
#define DEBUG_ENABLE_OUTPUT 2
#define DEBUG_DISABLE_OUTPUT 0

#define DEBUG_DEFAULT DEBUG_DISABLE_OUTPUT
// #define DEBUG_DEFAULT DEBUG_ENABLE_OUTPUT
static int debug_options;

static void debug_init_options(void)
{
    const char *option_string;
    
    if(!(option_string=getenv("PATTERN_SEQUENCER_DEBUG")))
    {
        debug_options=DEBUG_INITIALIZED|DEBUG_DEFAULT;
        return;
    }
    
    debug_options=DEBUG_INITIALIZED|DEBUG_ENABLE_OUTPUT;
}

int dbgprintf(const char *format, ...)
{
    va_list ap;
    int r;
    
    if(!debug_options) debug_init_options();
    if(!(debug_options & DEBUG_ENABLE_OUTPUT)) return 1;
    
    va_start(ap,format);
    r=vprintf(format,ap);
    va_end(ap);
    return r;
}