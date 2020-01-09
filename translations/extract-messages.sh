#!/usr/bin/env bash

podir=${podir:-$PWD/po}
enpodir=${enpodir:-$PWD/enpo}
files=$(find . -name Messages.sh)
dirs=$(for i in $files; do dirname "$i"; done | sort -u)
tmpname="$PWD/messages.log"
l10nscripts=$(dirname "$0")
EXTRACTRC=${EXTRACTRC:-extractrc}
EXTRACTATTR=${EXTRACTATTR:-extractattr}
EXTRACT_GRANTLEE_TEMPLATE_STRINGS=${EXTRACT_GRANTLEE_TEMPLATE_STRINGS:-grantlee_strings_extractor.py}
EXTRACT_TR_STRINGS=${EXTRACT_TR_STRINGS:-$(readlink -f "$l10nscripts"/extract-tr-strings)}
MSGCAT=${MSGCAT:-msgcat}
PACKAGE=${PACKAGE:-PACKAGE}
PREPARETIPS=${PREPARETIPS:-preparetips}
REPACKPOT=${REPACKPOT:-$(readlink -f "$l10nscripts"/repack-pot.pl)}
export EXTRACTRC EXTRACTATTR MSGCAT PREPARETIPS REPACKPOT EXTRACT_GRANTLEE_TEMPLATE_STRINGS EXTRACT_TR_STRINGS
if [ "x$IGNORE" = "x" ]; then
	IGNORE="/tests/"
else
	IGNORE="$IGNORE
/tests/"
fi

function kde_xgettext {
    $XGETTEXT_PROGRAM --copyright-holder="This file is copyright:" \
    --package-name="$PACKAGE" \
    --msgid-bugs-address=https://bugs.kde.org \
    --from-code=UTF-8 \
    -C --kde \
    -ci18n \
    -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 \
    -ki18nd:2 -ki18ndc:2c,3 -ki18ndp:2,3 -ki18ndcp:2c,3,4 \
    -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 \
    -kki18nd:2 -kki18ndc:2c,3 -kki18ndp:2,3 -kki18ndcp:2c,3,4 \
    -kxi18n:1 -kxi18nc:1c,2 -kxi18np:1,2 -kxi18ncp:1c,2,3 \
    -kxi18nd:2 -kxi18ndc:2c,3 -kxi18ndp:2,3 -kxi18ndcp:2c,3,4 \
    -kkxi18n:1 -kkxi18nc:1c,2 -kkxi18np:1,2 -kkxi18ncp:1c,2,3 \
    -kkxi18nd:2 -kkxi18ndc:2c,3 -kkxi18ndp:2,3 -kkxi18ndcp:2c,3,4 \
    -kI18N_NOOP:1 -kI18NC_NOOP:1c,2 \
    -kI18N_NOOP2:1c,2 -kI18N_NOOP2_NOSTRIP:1c,2 \
    -ktr2i18n:1 -ktr2xi18n:1 \
     "$@"
}

export -f kde_xgettext

for subdir in $dirs; do
  # skip Messages.sh files of KDevelop's app templates
  grep '{APPNAMELC}[^ ]*.pot' "$subdir"/Messages.sh 1>/dev/null && continue

  test -z "$VERBOSE" || echo "Making messages in $subdir"
  (cd "$subdir" || return 1
   if find . -name \*.c\* -o -name \*.h\* | grep -Fv "$IGNORE" | xargs grep -Fsq KAboutData ; then
	echo 'i18nc("NAME OF TRANSLATORS","Your names");' >> rc.cpp
	echo 'i18nc("EMAIL OF TRANSLATORS","Your emails");' >> rc.cpp
   fi

   XGETTEXT_FLAGS_WWW="\
--copyright-holder=This_file_is_part_of_KDE \
--msgid-bugs-address=https://bugs.kde.org \
--from-code=UTF-8 \
-L PHP \
-ki18n -ki18n_var -ki18n_noop \
"
   export XGETTEXT_FLAGS_WWW

   if test -f Messages.sh; then
       # Note: Messages.sh is supposed to get the translators' placeholder by rc.cpp
	   typeset -x XGETTEXT_PROGRAM="${XGETTEXT:-xgettext}"
       enpodir=$enpodir podir=$podir srcdir=. $XGETTEXT_PROGRAM XGETTEXT_WWW="${XGETTEXT:-xgettext} $XGETTEXT_FLAGS_WWW" XGETTEXT="kde_xgettext" PACKAGE="$PACKAGE" bash Messages.sh
   fi
   exit_code=$?
   if test "$exit_code" -ne 0; then
       echo "Bash exit code: $exit_code"
   fi
   if [ "x$KEEPRCCPP" = "x" ]; then
       rm -f rc.cpp
   fi
   ) >& "$tmpname"
   test -s "$tmpname" && { echo "$subdir" ; cat "$tmpname"; }
done

# Repack extracted templates.
find -L "$podir" -iname '*.pot' -exec "$REPACKPOT" {} \;

rm -f "$tmpname"

