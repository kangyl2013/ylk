
#define DEBUG1 1 
#ifdef DEBUG1
#define trace(format,...) NSLog(format,##__VA_ARGS__)
#else
#define trace(format,...)
#endif
