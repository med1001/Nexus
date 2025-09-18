#ifndef TEMPLATEMANAGER_H
#define TEMPLATEMANAGER_H

#include <QObject>
#include <QJsonObject>
#include <QVariantMap>
#include <QStringList>
#include <QMap>

class TemplateManager : public QObject
{
    Q_OBJECT
public:
    explicit TemplateManager(QObject *parent = nullptr);

    Q_INVOKABLE QStringList templates() const;
    Q_INVOKABLE QVariantMap getTemplate(const QString &name) const;

private:
    void loadTemplates();
    bool loadFromPath(const QString &path);
    void createDefaultTemplates();

    QMap<QString, QJsonObject> m_templates;
};

#endif // TEMPLATEMANAGER_H
