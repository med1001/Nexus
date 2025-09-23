#include "templateManager.h"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QDir>
#include <QResource>
#include <QStandardPaths>

TemplateManager::TemplateManager(QObject *parent)
    : QObject(parent)
{
    loadTemplates();
}

void TemplateManager::loadTemplates()
{
    qDebug() << "=== Starting template loading process ===";

    // Debug: Check if resource exists
    qDebug() << "Checking if resource file exists...";
    if (QFile::exists(":/templates.json")) {
        qDebug() << "Resource file exists in Qt resources";
    } else {
        qDebug() << "Resource file NOT found in Qt resources";
    }

    // List all available resources
    QDir resourceDir(":/");
    qDebug() << "All available resources:" << resourceDir.entryList();

    QDir templatesDir(":/templates");
    qDebug() << "Files in templates resource:" << templatesDir.entryList();

    // 1. Try to load from Qt resources first
    const QString qrcPath = QStringLiteral(":/templates.json");
    qDebug() << "Attempting to load from Qt resources:" << qrcPath;

    if (loadFromPath(qrcPath)) {
        qDebug() << "Templates loaded successfully from Qt resources";
        return;
    }

    qWarning() << "Cannot open template JSON in resources! Tried:" << qrcPath;

    // 2. Try to load from application directory
    QString appDirPath = QDir::current().filePath("templates.json");
    qDebug() << "Attempting to load from application directory:" << appDirPath;

    if (loadFromPath(appDirPath)) {
        qDebug() << "Templates loaded successfully from application directory";
        return;
    }

    // 3. Try to load from application data directory
    QString dataPath = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    qDebug() << "App data location:" << dataPath;

    QDir dataDir(dataPath);
    if (!dataDir.exists()) {
        qDebug() << "Creating app data directory:" << dataPath;
        dataDir.mkpath(".");
    }

    QString appDataPath = dataDir.filePath("templates.json");
    qDebug() << "Attempting to load from app data directory:" << appDataPath;

    if (loadFromPath(appDataPath)) {
        qDebug() << "Templates loaded successfully from app data directory";
        return;
    }

    // 4. Create default templates if no file is found
    qWarning() << "No template file found, creating default templates";
    createDefaultTemplates();
}

bool TemplateManager::loadFromPath(const QString &path)
{
    qDebug() << "Attempting to load from path:" << path;

    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qWarning() << "Failed to open file:" << path << "- Error:" << file.errorString();
        return false;
    }

    QByteArray raw = file.readAll();
    file.close();

    qDebug() << "File content size:" << raw.size() << "bytes";
    if (raw.size() > 0) {
        qDebug() << "First 100 chars of file:" << raw.left(100);
    }

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(raw, &err);
    if (err.error != QJsonParseError::NoError) {
        qWarning() << "JSON parse error in" << path << ":" << err.errorString() << "at offset" << err.offset;
        return false;
    }

    m_templates.clear();

    // Handle the specific structure of your templates.json
    if (doc.isObject()) {
        QJsonObject root = doc.object();
        qDebug() << "JSON root is an object with keys:" << root.keys();

        // Check if this is a single template definition with a "fields" array
        if (root.contains("fields") && root.value("fields").isArray()) {
            qDebug() << "Found 'fields' array in JSON object";
            QString templateName = root.value("title").toString("default");
            if (templateName.isEmpty()) {
                templateName = "default";
            }
            m_templates.insert(templateName, root);
            qDebug() << "Loaded template:" << templateName;
            return true;
        }
        // Handle other possible structures
        else if (root.contains("templates") && root.value("templates").isArray()) {
            qDebug() << "Found 'templates' array in JSON object";
            QJsonArray array = root.value("templates").toArray();
            for (const QJsonValue &val : array) {
                if (!val.isObject()) continue;
                QJsonObject obj = val.toObject();
                QString name = obj.value("type").toString();
                if (name.isEmpty()) name = obj.value("id").toString();
                if (name.isEmpty()) name = obj.value("name").toString();
                if (name.isEmpty()) name = QStringLiteral("template_%1").arg(m_templates.size()+1);
                m_templates.insert(name, obj);
                qDebug() << "Loaded template (root.templates):" << name;
            }
        } else {
            qDebug() << "Processing JSON object as key-value map";
            for (auto it = root.begin(); it != root.end(); ++it) {
                QString name = it.key();
                if (!it.value().isObject()) continue;
                QJsonObject obj = it.value().toObject();
                m_templates.insert(name, obj);
                qDebug() << "Loaded template (map):" << name;
            }
        }
    } else if (doc.isArray()) {
        qDebug() << "JSON root is an array";
        QJsonArray array = doc.array();
        for (const QJsonValue &val : array) {
            if (!val.isObject()) continue;
            QJsonObject obj = val.toObject();
            QString name = obj.value("type").toString();
            if (name.isEmpty()) name = obj.value("id").toString();
            if (name.isEmpty()) name = obj.value("name").toString();
            if (name.isEmpty()) name = QStringLiteral("template_%1").arg(m_templates.size()+1);
            m_templates.insert(name, obj);
            qDebug() << "Loaded template (array):" << name;
        }
    } else {
        qWarning() << "templates.json: unexpected JSON root (not array nor object)";
        return false;
    }

    qDebug() << "Total templates loaded:" << m_templates.size();
    return true;
}

void TemplateManager::createDefaultTemplates()
{
    qDebug() << "Creating default templates";
    m_templates.clear();

    // Template simple par défaut
    QJsonObject simpleTemplate;
    simpleTemplate["type"] = "simple";
    simpleTemplate["version"] = 1;
    simpleTemplate["label"] = "Configuration Simple";

    QJsonArray simpleFields;
    QJsonObject paramField;
    paramField["id"] = "param";
    paramField["label"] = "Paramètre";
    paramField["type"] = "int";
    paramField["default"] = 0;
    paramField["min"] = 0;
    paramField["max"] = 100;
    paramField["step"] = 1;
    paramField["required"] = true;
    simpleFields.append(paramField);

    simpleTemplate["fields"] = simpleFields;
    m_templates.insert("simple", simpleTemplate);

    // Template avancé par défaut
    QJsonObject advancedTemplate;
    advancedTemplate["type"] = "advanced";
    advancedTemplate["version"] = 1;
    advancedTemplate["label"] = "Configuration Avancée";

    QJsonArray advancedFields;

    QJsonObject hostField;
    hostField["id"] = "host";
    hostField["label"] = "Hôte";
    hostField["type"] = "string";
    hostField["default"] = "localhost";
    hostField["required"] = true;
    advancedFields.append(hostField);

    QJsonObject portField;
    portField["id"] = "port";
    portField["label"] = "Port";
    portField["type"] = "int";
    portField["default"] = 8080;
    portField["min"] = 1;
    portField["max"] = 65535;
    portField["required"] = true;
    advancedFields.append(portField);

    QJsonObject timeoutField;
    timeoutField["id"] = "timeout";
    timeoutField["label"] = "Délai d'expiration (ms)";
    timeoutField["type"] = "int";
    timeoutField["default"] = 5000;
    timeoutField["min"] = 100;
    timeoutField["max"] = 60000;
    advancedFields.append(timeoutField);

    advancedTemplate["fields"] = advancedFields;
    m_templates.insert("advanced", advancedTemplate);

    qDebug() << "Created default templates: simple, advanced";
}

QStringList TemplateManager::templates() const {
    return m_templates.keys();
}

QVariantMap TemplateManager::getTemplate(const QString &name) const {
    QVariantMap map;
    if (!m_templates.contains(name)) {
        qWarning() << "Template not found:" << name;
        return map;
    }
    QJsonObject obj = m_templates.value(name);
    return obj.toVariantMap();
}
