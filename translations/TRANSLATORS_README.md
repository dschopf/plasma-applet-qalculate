# Add a new language translation

1. Copy the file `po/plasma_applet_org.kde.plasma.qalculate_en.po` to `po/plasma_applet_org.kde.plasma.qalculate_$LANG.po`,
where $LANG is the [POSIX locale code](https://github.com/umpirsky/locale-list/blob/master/data/en_US/locales.txt)
of the new language, e.g. "es" (or locale, e.g. "es_MX").

2. In the copied file:
   - Change the value of the Language: field accordingly
   - Be sure to write your name :-) (as FIRST TRANSLATOR in the copyright paragraph at the top of
     the file and also as Last-Translator: and Language-Team: in the metadata directly beneath it).
   - Translate the provided msgids in the respective msgstr line underneath

3. Create a pull request with your patch or simply open a new issue on Github and attach the new translation.

Thank you for your translations!
