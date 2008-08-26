/* GNU Mailutils -- a suite of utilities for electronic mail
   Copyright (C) 1999, 2000, 2001, 2005, 2007,
   2008 Free Software Foundation, Inc.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 3 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General
   Public License along with this library; if not, write to the
   Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301 USA */

#ifndef _ARGCV_H
#define _ARGCV_H 1

#include <stdio.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ARGCV_RETURN_DELIMS 0x01

enum argcv_quoting_style {
    argcv_quoting_octal,
    argcv_quoting_hex
};

extern enum argcv_quoting_style argcv_quoting_style;
    
extern int argcv_get    (const char *command, const char *delim,
			 const char *cmnt,
			 int *argc, char ***argv);
extern int argcv_get_n (const char *command, int len,
			const char *delim, const char *cmnt,
			int *argc, char ***argv);
extern int argcv_get_np (const char *command, int len,
			 const char *delim, const char *cmnt,
			 int flags,
			 int *pargc, char ***pargv, char **endp);
  
extern int argcv_string (int argc, char **argv, char **string);
extern void argcv_free   (int argc, char **argv);
extern void argv_free (char **argv);

extern int argcv_unquote_char (int c);
extern int argcv_quote_char   (int c);
extern size_t argcv_quoted_length (const char *str, int *quote);
extern void argcv_unquote_copy (char *dst, const char *src, size_t n);
extern void argcv_quote_copy (char *dst, const char *src);
extern void argcv_remove (int *pargc, char ***pargv,
			       int (*sel) (const char *, void *), void *);
  
#ifdef __cplusplus
}
#endif

#endif /* _ARGCV_H */
