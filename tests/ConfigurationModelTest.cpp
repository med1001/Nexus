#include <QtTest>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QAbstractItemModel>
#include "configurationModel.h"

class ConfigurationModelTest : public QObject {
    Q_OBJECT

private slots:
    void initTestCase();
    void cleanupTestCase();

    void dataRoles_returnExpectedValues();
    void addConfigurationFromJson_insertsRow();
    void updateConfigurationFromJson_invalidRowFails();

private:
    QString m_connName = "test_conn_model";
};

void ConfigurationModelTest::initTestCase() {
    QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE", m_connName);
    db.setDatabaseName(":memory:");
    QVERIFY(db.open());

    QSqlQuery q(db);
    QVERIFY(q.exec(R"(
        CREATE TABLE configurations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT,
            version INTEGER,
            name TEXT,
            data TEXT,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    )"));
}

void ConfigurationModelTest::cleanupTestCase() {
    // Ensure no object still uses the connection
    QSqlDatabase::removeDatabase(m_connName);
}

void ConfigurationModelTest::dataRoles_returnExpectedValues() {
    QSqlDatabase db = QSqlDatabase::database(m_connName);
    ConfigurationModel model(nullptr, db);

    // add a row
    QString json = R"({"param":42})";
    QVERIFY(model.addConfigurationFromJson("simple", 1, "T1", json));
    QCOMPARE(model.rowCount(), 1);

    QModelIndex anyIndex = model.index(0, 0);

    // Use base class pointer so access to data(...) is through QAbstractItemModel (public)
    QAbstractItemModel *baseModel = static_cast<QAbstractItemModel*>(&model);

    // role Qt::UserRole + 4 -> "name"
    QVariant vName = baseModel->data(anyIndex, Qt::UserRole + 4);
    QCOMPARE(vName.toString(), QString("T1"));

    // role Qt::UserRole + 2 -> "type"
    QVariant vType = baseModel->data(anyIndex, Qt::UserRole + 2);
    QCOMPARE(vType.toString(), QString("simple"));

    // role Qt::UserRole + 5 -> "data"
    QVariant vData = baseModel->data(anyIndex, Qt::UserRole + 5);
    QVERIFY(vData.toString().contains("\"param\""));
}

void ConfigurationModelTest::addConfigurationFromJson_insertsRow() {
    QSqlDatabase db = QSqlDatabase::database(m_connName);
    ConfigurationModel model(nullptr, db);
    QString json = R"({"param":42})";
    bool ok = model.addConfigurationFromJson("simple", 1, "T1", json);
    QVERIFY(ok);
    QCOMPARE(model.rowCount(), 1);
    auto types = model.distinctTypes();
    QVERIFY(types.contains("simple"));
}

void ConfigurationModelTest::updateConfigurationFromJson_invalidRowFails() {
    QSqlDatabase db = QSqlDatabase::database(m_connName);
    ConfigurationModel model(nullptr, db);
    QVERIFY(!model.updateConfigurationFromJson(-1, "{}"));
    QVERIFY(!model.updateConfigurationFromJson(100, "{}"));
}

QTEST_MAIN(ConfigurationModelTest)
#include "ConfigurationModelTest.moc"
