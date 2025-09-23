// Configuration.cpp
#include "configuration.h"

Configuration::Configuration(QObject *parent) : QObject(parent), m_param(0) {}

QString Configuration::name() const { return m_name; }
void Configuration::setName(const QString &name) {
    if (m_name != name) {
        m_name = name;
        emit nameChanged();
    }
}

int Configuration::param() const { return m_param; }
void Configuration::setParam(int value) {
    if (m_param != value) {
        m_param = value;
        emit paramChanged();
    }
}
