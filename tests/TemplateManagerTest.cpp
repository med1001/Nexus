#include <QtTest>
#include "templateManager.h"

class TemplateManagerTest : public QObject {
    Q_OBJECT

private slots:
    void defaultTemplatesWhenNoFile();
    void getTemplateContainsFields();
};

void TemplateManagerTest::defaultTemplatesWhenNoFile() {
    TemplateManager tm;
    QStringList keys = tm.templates();
    QVERIFY(keys.contains("simple"));
    QVERIFY(keys.contains("advanced"));
}

void TemplateManagerTest::getTemplateContainsFields() {
    TemplateManager tm;
    QVariantMap tpl = tm.getTemplate("simple");
    QVERIFY(tpl.contains("fields"));
}

QTEST_MAIN(TemplateManagerTest)
#include "TemplateManagerTest.moc"
