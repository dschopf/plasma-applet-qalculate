# Translations

## Add a new language translation

1. Copy the file `po/template.pot` to `po/$LANG.po`,
where $LANG is the [POSIX locale code](https://github.com/umpirsky/locale-list/blob/master/data/en_US/locales.txt)
of the new language, e.g. "es" (or locale, e.g. "es_MX").

2. In the copied file:
   - Change the value of the Language: field accordingly
   - Be sure to write your name :-) (as FIRST TRANSLATOR in the copyright paragraph at the top of
     the file and also as Last-Translator: and Language-Team: in the metadata directly beneath it).
   - Translate the provided msgids in the respective msgstr line underneath

3. Create a pull request with your patch or simply open a new issue on Github and attach the new translation.

Thank you for your translations!

## Links

* https://develop.kde.org/docs/plasma/widget/translations-i18n/
* https://l10n.kde.org/stats/gui/trunk-kf5/team/fr/plasma-desktop/
* https://techbase.kde.org/Development/Tutorials/Localization/i18n_Build_Systems
* https://api.kde.org/frameworks/ki18n/html/prg_guide.html
