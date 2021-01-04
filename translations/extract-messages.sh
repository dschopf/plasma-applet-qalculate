#!/usr/bin/env bash

PROJECT="plasma_applet_org.kde.plasma.qalculate"
BASEDIR="../plasmoid"
BUGADDR="https://github.com/dschopf/qalculate/issues"

echo "Extracting messages"

find ${BASEDIR} -name '*.qml' | sort > infiles.list

xgettext --from-code=UTF-8 -C -L JavaScript -kde -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 -ki18ncp:1c,2,3 -ktr2i18n:1 \
	-kI18N_NOOP:1 -kI18N_NOOP2:1c,2 -kaliasLocale -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3 \
	--msgid-bugs-address="${BUGADDR}" \
	--files-from=infiles.list \
	--package-name="${PROJECT}" \
	-o po/${PROJECT}.pot || { echo "error while calling xgettext. aborting."; exit 1; }

echo "Done extracting messages"

echo "Merging translations"

catalogs=`find ./po -name '*.po'`

for cat in $catalogs; do
  echo "$cat"
  msgmerge -o "$cat".new "$cat" po/${PROJECT}.pot
  mv "$cat".new "$cat"
done

echo "Done merging translations"

echo "Cleaning up"
rm infiles.list
echo "Done"
