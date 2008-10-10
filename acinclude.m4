dnl These defuns are borrowed from GNU/inetutils.  -*- Autoconf -*-
dnl Copyright (C) 1996, 1997, 1998, 2002, 2004, 2005, 2007 Free Software Foundation, Inc.
dnl Mostly written by Miles Bader <miles@gnu.ai.mit.edu>

dnl Rush is free software; you can redistribute it and/or modify
dnl it under the terms of the GNU General Public License as published by
dnl the Free Software Foundation; either version 3, or (at your option)
dnl any later version.
dnl
dnl Rush is distributed in the hope that it will be useful,
dnl but WITHOUT ANY WARRANTY; without even the implied warranty of
dnl MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
dnl GNU General Public License for more details.
dnl
dnl You should have received a copy of the GNU General Public License
dnl along with Rush.  If not, see <http://www.gnu.org/licenses/>.

dnl IU_CHECK_MEMBER(AGGREGATE.MEMBER,
dnl                [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND],
dnl                [INCLUDES])
dnl AGGREGATE.MEMBER is for instance `struct passwd.pw_gecos'.
dnl The member itself can be of an aggregate type
dnl Shell variables are not a valid argument.
AC_DEFUN([IU_CHECK_MEMBER],
[AS_LITERAL_IF([$1], [],
               [AC_FATAL([$0: requires literal arguments])])dnl
m4_bmatch([$1], [\.], ,
         [m4_fatal([$0: Did not see any dot in `$1'])])dnl
AS_VAR_PUSHDEF([ac_Member], [ac_cv_member_$1])dnl
dnl Extract the aggregate name, and the member name
AC_CACHE_CHECK([for $1], ac_Member,
[AC_COMPILE_IFELSE([AC_LANG_PROGRAM([AC_INCLUDES_DEFAULT([$4])],
[dnl AGGREGATE ac_aggr;
static m4_bpatsubst([$1], [\..*]) ac_aggr;
dnl ac_aggr.MEMBER;
if (sizeof(ac_aggr.m4_bpatsubst([$1], [^[^.]*\.])))
return 0;])],
                [AS_VAR_SET(ac_Member, yes)],
                [AS_VAR_SET(ac_Member, no)])])
AS_IF([test AS_VAR_GET(ac_Member) = yes], [$2], [$3])dnl
AS_VAR_POPDEF([ac_Member])dnl
])dnl IU_CHECK_MEMBER


dnl IU_CHECK_MEMBERS([AGGREGATE.MEMBER, ...],
dnl                  [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND]
dnl                  [INCLUDES])
AC_DEFUN([IU_CHECK_MEMBERS],
[m4_foreach([AC_Member], [$1],
  [IU_CHECK_MEMBER(AC_Member,
         [AC_DEFINE_UNQUOTED(AS_TR_CPP(HAVE_[]AC_Member), 1,
                            [Define to 1 if `]m4_bpatsubst(AC_Member,
                                                     [^[^.]*\.])[' is
                             member of `]m4_bpatsubst(AC_Member, [\..*])['.])
$2],
                 [$3],
                 [$4])])])

dnl IU_CONFIG_PATHS -- Configure system paths for use by programs
dnl   $1 - PATHS    -- The file to read containing the paths
dnl   $2 - MAKEDEFS -- The file to generate containing make `PATHDEF_' vars
dnl   $3 - HDRDEFS  -- The file to generate containing c header stuff
dnl
dnl From the paths listed in the file PATHS, generate a file of make input
dnl (MAKEDEFS) containing a make variable for each PATH_FOO, called
dnl PATHDEF_FOO, which is set to a cpp option to define that path, unless it
dnl is to be defined using a system define, in which case the
dnl corresponding make variable is empty.  A file called HDRDEFS will also be
dnl generated containing cpp statements.  For each PATH_FOO which is found
dnl to be available as a system define, a statement will be generated which
dnl defines it to be that system define, unless it is already defined (which
dnl will be case if overridden by make).
dnl
AC_DEFUN([IU_CONFIG_PATHS], [
  dnl We need to know if we're cross compiling.
  AC_REQUIRE([AC_PROG_CC])

  AC_CHECK_HEADER(paths.h, AC_DEFINE(HAVE_PATHS_H, 1,
        [Define if you have the <paths.h> header file]) iu_paths_h="<paths.h>")

  dnl A slightly bogus use of AC_ARG_WITH; we never actually use
  dnl $with_PATHVAR, we just want to get this entry put into the help list.
  dnl We actually look for `with_' variables corresponding to each path
  dnl configured.
  AC_ARG_WITH([PATHVAR],
              AC_HELP_STRING([--with-PATHVAR=PATH],
                             [Set the value of PATHVAR to PATH
                          PATHVAR is the name of a \`PATH_FOO' variable,
                          downcased, with \`_' changed to \`-']))

  # For case-conversion with sed
  IU_UCASE=ABCDEFGHIJKLMNOPQRSTUVWXYZ
  iu_lcase=abcdefghijklmnopqrstuvwxyz

  tmpdir="$TMPDIR"
  test x"$tmpdir" = x && tmpdir="/tmp"
  iu_cache_file="$tmpdir/,iu-path-cache.$$"
  iu_tmp_file="$tmpdir/,iu-tmp.$$"
  ac_clean_files="$ac_clean_files $iu_cache_file $iu_tmp_file"
  while read iu_path iu_search; do
    test "$iu_path" = "#" -o -z "$iu_path" && continue

    iu_pathvar="`echo $iu_path  | sed y/${IU_UCASE}/${iu_lcase}/`"
    AC_MSG_CHECKING(for value of $iu_path)

    iu_val='' iu_hdr='' iu_sym=''
    iu_cached='' iu_defaulted=''
    iu_cross_conflict=''
    if test "`eval echo '$'{with_$iu_pathvar+set}`" = set; then
      # User-supplied value
      eval iu_val=\"'$'with_$iu_pathvar\"
    elif test "`eval echo '$'{inetutils_cv_$iu_pathvar+set}`" = set; then
      # Cached value
      eval iu_val=\"'$'inetutils_cv_$iu_pathvar\"
      # invert escaped $(...) notation used in autoconf cache
      eval iu_val=\"\`echo \'"$iu_val"\' \| sed \''s/@(/$\(/g'\'\`\"
      iu_cached="(cached) "
    elif test "`eval echo '$'{inetutils_cv_hdr_$iu_pathvar+set}`" = set; then
      # Cached non-value
      eval iu_hdr=\"'$'inetutils_cv_hdr_$iu_pathvar\"
      eval iu_sym=\"'$'inetutils_cv_hdr_sym_$iu_pathvar\"
      iu_cached="(cached) "
    else
      # search for a reasonable value

      iu_test_type=r		# `exists'
      iu_default='' iu_prev_cross_test=''
      for iu_try in $iu_paths_h $iu_search; do
	iu_cross_test=''
	case "$iu_try" in
	  "<"*">"*)
	    # <HEADER.h> and <HEADER.h>:SYMBOL -- look for SYMBOL in <HEADER.h>
	    # SYMBOL defaults to _$iu_path (e.g., _PATH_FOO)
	    changequote(,)	dnl Avoid problems with [ ] in regexps
	    eval iu_hdr=\'`echo "$iu_try" |sed 's/:.*$//'`\'
	    eval iu_sym=\'`echo "$iu_try" |sed -n 's/^<[^>]*>:\(.*\)$/\1/p'`\'
	    changequote([,])
	    test "$iu_sym" || iu_sym="_$iu_path"
	    AC_EGREP_CPP(HAVE_$iu_sym,
[#include ]$iu_hdr[
#ifdef $iu_sym
HAVE_$iu_sym
#endif],
	      :, iu_hdr='' iu_sym='')
	    ;;

	  search:*)
	    # Do a path search.  The syntax here is: search:NAME[:PATH]...

	    # Path searches always generate potential conflicts
	    test "$cross_compiling" = yes && { iu_cross_conflict=yes; continue; }

	    changequote(,)	dnl Avoid problems with [ ] in regexps
	    iu_name="`echo $iu_try | sed 's/^search:\([^:]*\).*$/\1/'`"
	    iu_spath="`echo $iu_try | sed 's/^search:\([^:]*\)//'`"
	    changequote([,])

	    test "$iu_spath" || iu_spath="$PATH"

	    for iu_dir in `echo "$iu_spath" | sed 'y/:/ /'`; do
	      test -z "$iu_dir" && iu_dir=.
	      if test -$iu_test_type "$iu_dir/$iu_name"; then
		iu_val="$iu_dir/$iu_name"
		break
	      fi
	    done
	    ;;

	  no) iu_default=no;;
	  x|d|f|c|b) iu_test_type=$iu_try;;

	  *)
	    # Just try the given name, with make-var substitution.  Besides 
	    # yielding a value if found, this also sets the default.

	    case "$iu_try" in "\""*"\"")
	      # strip off quotes
	      iu_try="`echo $iu_try | sed -e 's/^.//' -e 's/.$//'`"
	    esac

	    test -z "$iu_default" && iu_default="$iu_try"
	    test "$cross_compiling" = yes && { iu_cross_test=yes; continue; }

	    # See if the value begins with a $(FOO)/${FOO} make variable
	    # corresponding to a shell variable, and if so set try_exp to the
	    # value thereof.  Recurse.
	    iu_try_exp="$iu_try"
	    changequote(,)
	    iu_try_var="`echo "$iu_try_exp" |sed -n 's;^\$[({]\([-_a-zA-Z]*\)[)}].*;\1;p'`"
	    while eval test \"$iu_try_var\" && eval test '${'$iu_try_var'+set}'; do
	      # yes, and there's a corresponding shell variable, which substitute
	      if eval test \"'$'"$iu_try_var"\" = NONE; then
		# Not filled in by configure yet
		case "$iu_try_var" in
		  prefix | exec_prefix)
		    iu_try_exp="$ac_default_prefix`echo "$iu_try_exp" |sed 's;^\$[({][-_a-zA-Z]*[)}];;'`";;
		esac
		iu_try_var=''	# Stop expansion here
	      else
		# Use the actual value of the shell variable
		eval iu_try_exp=\"`echo "$iu_try_exp" |sed 's;^\$[({]\([-_a-zA-Z]*\)[)}];\$\1;'`\"
		iu_try_var="`echo "$iu_try_exp" |sed -n 's;^\$[({]\([-_a-zA-Z]*\)[)}].*;\1;p'`"
	      fi
	    done
	    changequote([,])

	    test -$iu_test_type "$iu_try_exp" && iu_val="$iu_try"
	    ;;

	esac

	test "$iu_val" -o "$iu_hdr" && break
	test "$iu_cross_test" -a "$iu_prev_cross_test" && iu_cross_conflict=yes
	iu_prev_cross_test=$iu_cross_test
      done

      if test -z "$iu_val" -a -z "$iu_hdr"; then
	if test -z "$iu_default"; then
	  iu_val=no
	else
	  iu_val="$iu_default"
	  iu_defaulted="(default) "
	fi
      fi
    fi

    if test "$iu_val"; then
      AC_MSG_RESULT(${iu_cached}${iu_defaulted}$iu_val)
      test "$iu_cross_conflict" -a "$iu_defaulted" \
	&& AC_MSG_WARN(may be incorrect because of cross-compilation)
      # Put the value in the autoconf cache.  We replace $( with @( to avoid
      # variable evaluation problems when autoconf reads the cache later.
      echo inetutils_cv_$iu_pathvar=\'"`echo "$iu_val" | sed 's/\$(/@(/g'`"\'
    elif test "$iu_hdr"; then
      AC_MSG_RESULT(${iu_cached}from $iu_sym in $iu_hdr)
      echo inetutils_cv_hdr_$iu_pathvar=\'"$iu_hdr"\'
      echo inetutils_cv_hdr_sym_$iu_pathvar=\'"$iu_sym"\'
    fi
  done <[$1] >$iu_cache_file

  # Read the cache values constructed by the previous loop, 
  . $iu_cache_file

  # Construct the pathdefs file -- a file of make variable definitions, of
  # the form PATHDEF_FOO, that contain cc -D switches to define the cpp macro
  # PATH_FOO.
  grep -v '^inetutils_cv_hdr_' < $iu_cache_file | \
  while read iu_cache_set; do
    iu_var="`echo $iu_cache_set | sed 's/=.*$//'`"
    eval iu_val=\"'$'"$iu_var"\"
    # invert escaped $(...) notation used in autoconf cache
    eval iu_val=\"\`echo \'"$iu_val"\' \| sed \''s/@(/$\(/g'\'\`\"
    if test "$iu_val" != no; then
      iu_path="`echo $iu_var | sed -e 's/^inetutils_cv_//' -e y/${iu_lcase}/${IU_UCASE}/`"
      iu_pathdef="`echo $iu_path | sed 's/^PATH_/PATHDEF_/'`"
      echo $iu_pathdef = -D$iu_path='\"'"$iu_val"'\"'
      AC_DEFINE_UNQUOTED($iu_path, "$iu_val")
    fi
  done >$[$2]
  AC_SUBST_FILE([$2])

  # Generate a file of #ifdefs that defaults PATH_FOO macros to _PATH_FOO (or
  # some other symbol) (excluding any who's value is set to `no').
  grep '^inetutils_cv_hdr_sym_' < $iu_cache_file | \
  while read iu_cache_set; do
    iu_sym_var="`echo "$iu_cache_set" | sed 's/=.*$//'`"
    eval iu_sym=\"'$'"$iu_sym_var"\"
    iu_path="`echo $iu_sym_var | sed -e 's/^inetutils_cv_hdr_sym_//' -e y/${iu_lcase}/${IU_UCASE}/`"
    cat <<EOF
#ifndef $iu_path
#define $iu_path $iu_sym
#endif
EOF
  done >$[$3]
  AC_SUBST_FILE([$3])])
		 