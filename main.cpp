#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QDir>
#include <QDebug>
#include <QSqlError>

#include "configurationModel.h"
#include "templateManager.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // --- DB file (working dir) ---
    QString dbFile = QDir::current().filePath("configurations.db");
    qDebug() << "Using DB file:" << dbFile;

    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
    db.setDatabaseName(dbFile);
    if (!db.open()) {
        qFatal("Impossible d'ouvrir la base SQLite");
    }

    // --- Création de la table si elle n'existe pas ---
    QSqlQuery query(db);
    bool ok = query.exec(R"(
        CREATE TABLE IF NOT EXISTS configurations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            version INTEGER,
            name TEXT,
            data TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    )");
    if (!ok) {
        qWarning() << "Failed to create table:" << query.lastError().text();
    }
//only for test code
    QSqlQuery q(db);
    if (q.exec("SELECT DISTINCT type FROM configurations")) {
        qDebug() << "Distinct types in DB:";
        while (q.next()) {
            qDebug() << "  -" << q.value(0).toString();
        }
    } else {
        qWarning() << "Failed to query distinct types:" << q.lastError().text();
    }
//
    // --- Modèle exposé à QML ---
    ConfigurationModel model(nullptr, db);

    // --- Template manager : charge JSON templates depuis le QRC ---
    TemplateManager tmplMgr; // plus besoin de chemin, le QRC est intégré

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("configModel", &model);
    engine.rootContext()->setContextProperty("templateManager", &tmplMgr);

    // --- QML ---
    engine.load(QUrl(QStringLiteral("qrc:/qt/qml/configurationManager/Main.qml")));

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
