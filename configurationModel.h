#ifndef CONFIGURATIONMODEL_H
#define CONFIGURATIONMODEL_H

#include <QSqlDatabase>
#include <QSqlTableModel>
#include <QSqlRecord>
#include <QHash>
#include <QByteArray>
#include <QVariant>
#include <QModelIndex>
#include <QStringList>

class ConfigurationModel : public QSqlTableModel {
    Q_OBJECT
public:
    explicit ConfigurationModel(QObject *parent = nullptr, QSqlDatabase db = QSqlDatabase());

    Q_INVOKABLE bool addConfigurationFromJson(const QString &type, int version, const QString &name, const QString &jsonData);
    Q_INVOKABLE bool updateConfigurationFromJson(int row, const QString &jsonData);
    Q_INVOKABLE bool removeConfiguration(int row);
    Q_INVOKABLE void refresh();

    // Expose filter to QML (keeps same name for compatibility with your QML)
    Q_INVOKABLE void setFilter(const QString &filter);

    // Provide distinct types to QML (robust solution)
    Q_INVOKABLE QStringList distinctTypes() const;

    // legacy convenience (optional)
    Q_INVOKABLE bool addConfiguration(const QString &name, int param); // maps to simple sensor template
    Q_INVOKABLE bool updateConfiguration(int row, const QString &name, int param);

protected:
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
};

#endif // CONFIGURATIONMODEL_H
