#include <QtTest>
#include <QSignalSpy>
#include "configuration.h"

class ConfigurationTest : public QObject {
    Q_OBJECT

private slots:
    void defaultValues();
    void setNameEmitsOnceOnChange();
    void setParamEmitsOnceOnChange();
};

void ConfigurationTest::defaultValues() {
    Configuration cfg;
    QCOMPARE(cfg.name(), QString(""));
    QCOMPARE(cfg.param(), 0);
}

void ConfigurationTest::setNameEmitsOnceOnChange() {
    Configuration cfg;
    QSignalSpy spy(&cfg, SIGNAL(nameChanged()));
    cfg.setName("A");
    cfg.setName("A");
    QCOMPARE(spy.count(), 1);
}

void ConfigurationTest::setParamEmitsOnceOnChange() {
    Configuration cfg;
    QSignalSpy spy(&cfg, SIGNAL(paramChanged()));
    cfg.setParam(5);
    cfg.setParam(5);
    QCOMPARE(spy.count(), 1);
}

QTEST_MAIN(ConfigurationTest)
#include "ConfigurationTest.moc"
