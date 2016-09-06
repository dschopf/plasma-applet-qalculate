#include "plasmoidplugin.h"
#include "qwrapper.h"

#include <QtQml>
#include <QDebug>

void PlasmoidPlugin::registerTypes(const char *uri)
{
    Q_ASSERT(uri == QLatin1String("org.kde.private.qalculate"));

    qmlRegisterType<QWrapper>(uri, 1, 0, "QWrapper");
}
