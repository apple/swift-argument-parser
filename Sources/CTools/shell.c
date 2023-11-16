//
//  shell.c
//  
//
//  Created by Tomek Popis on 09/11/2023.
//

#include "shell.h"

#include <pwd.h>
#include <unistd.h>

char* shellPath(void) { return getpwuid(geteuid())->pw_shell; }
