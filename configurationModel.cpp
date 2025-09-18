#include "ConfigurationModel.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

ConfigurationModel::ConfigurationModel(QObject *parent, QSqlDatabase db)
    : QSqlTableModel(parent, db)
{
    setTable("configurations");
    setEditStrategy(QSqlTableModel::OnFieldChange);
    select();
}

bool ConfigurationModel::addConfigurationFromJson(const QString &type, int version, const QString &name, const QString &jsonData) {
    QSqlRecord record = this->record();
    // ensure fields exist: type, version, name, data
    record.setValue("type", type);
    record.setValue("version", version);
    record.setValue("name", name);
    record.setValue("data", jsonData);

    if (!insertRecord(-1, record)) {
        qWarning() << "Insert failed:" << lastError().text();
        return false;
    }
    if (!submitAll()) {
        qWarning() << "Submit failed after insert:" << lastError().text();
        return false;
    }
    select();
    return true;
}

bool ConfigurationModel::updateConfigurationFromJson(int row, const QString &jsonData) {
    if (row < 0 || row >= rowCount()) {
        qWarning() << "updateConfigurationFromJson: invalid row" << row;
        return false;
    }

    QSqlRecord record = this->record(row);
    record.setValue("data", jsonData);

    if (!setRecord(row, record)) {
        qWarning() << "setRecord failed:" << lastError().text();
        return false;
    }
    if (!submitAll()) {
        qWarning() << "Submit failed after update:" << lastError().text();
        return false;
    }
    select();
    return true;
}

bool ConfigurationModel::removeConfiguration(int row) {
    if (row < 0 || row >= rowCount()) {
        qWarning() << "removeConfiguration: invalid row" << row;
        return false;
    }
    if (!removeRow(row)) {
        qWarning() << "Remove failed:" << lastError().text();
        return false;
    }
    if (!submitAll()) {
        qWarning() << "Submit failed after remove:" << lastError().text();
        return false;
    }
    select();
    return true;
}

void ConfigurationModel::refresh() {
    select();
}

// Keep the same name so existing QML calls still work
void ConfigurationModel::setFilter(const QString &filter) {
    QSqlTableModel::setFilter(filter);
    select(); // refresh the model after applying the filter
}

// Return distinct type strings from the DB
QStringList ConfigurationModel::distinctTypes() const {
    QStringList result;
    QSqlQuery q(database());
    // Use the table name directly; DISTINCT returns unique non-null values
    if (!q.exec(QStringLiteral("SELECT DISTINCT type FROM configurations"))) {
        qWarning() << "distinctTypes query failed:" << q.lastError().text();
        return result;
    }
    while (q.next()) {
        // push back even empty/whitespace-trimmed strings (trimmed)
        QString t = q.value(0).toString().trimmed();
        if (!t.isEmpty())
            result << t;
    }
    return result;
}

// Legacy helpers (kept for compatibility)
bool ConfigurationModel::addConfiguration(const QString &name, int param) {
    // create a tiny JSON object { "param": param }
    QJsonObject obj;
    obj["param"] = param;
    QJsonDocument doc(obj);
    return addConfigurationFromJson(QStringLiteral("simple"), 1, name, QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
}

bool ConfigurationModel::updateConfiguration(int row, const QString &name, int param) {
    if (row < 0 || row >= rowCount()) return false;
    QSqlRecord record = this->record(row);
    record.setValue("name", name);
    QJsonObject obj;
    obj["param"] = param;
    QJsonDocument doc(obj);
    record.setValue("data", QString::fromUtf8(doc.toJson(QJsonDocument::Compact)));
    if (!setRecord(row, record)) {
        qWarning() << "setRecord failed:" << lastError().text();
        return false;
    }
    if (!submitAll()) {
        qWarning() << "Submit failed after update:" << lastError().text();
        return false;
    }
    select();
    return true;
}

// --- roles mapping ---
QHash<int, QByteArray> ConfigurationModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[Qt::UserRole + 1] = "id";
    roles[Qt::UserRole + 2] = "type";
    roles[Qt::UserRole + 3] = "version";
    roles[Qt::UserRole + 4] = "name";
    roles[Qt::UserRole + 5] = "data";
    return roles;
}

QVariant ConfigurationModel::data(const QModelIndex &index, int role) const {
    if (!index.isValid())
        return QVariant();

    if (role < Qt::UserRole)
        return QSqlTableModel::data(index, role);

    // map roles to column names
    QString fieldName;
    switch (role) {
    case Qt::UserRole + 1: fieldName = "id"; break;
    case Qt::UserRole + 2: fieldName = "type"; break;
    case Qt::UserRole + 3: fieldName = "version"; break;
    case Qt::UserRole + 4: fieldName = "name"; break;
    case Qt::UserRole + 5: fieldName = "data"; break;
    default:
        return QVariant();
    }

    QSqlRecord rec = this->record(index.row());
    int col = rec.indexOf(fieldName);
    if (col < 0) return QVariant();
    return QSqlTableModel::data(this->index(index.row(), col), Qt::DisplayRole);
}
