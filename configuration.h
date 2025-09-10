#ifndef CONFIGURATION_H
#define CONFIGURATION_H
// Configuration.h
#pragma once
#include <QObject>

class Configuration : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int param READ param WRITE setParam NOTIFY paramChanged)
public:
    explicit Configuration(QObject *parent = nullptr);
    QString name() const;
    void setName(const QString &name);
    int param() const;
    void setParam(int value);

signals:
    void nameChanged();
    void paramChanged();

private:
    QString m_name;
    int m_param;
};

#endif // CONFIGURATION_H
