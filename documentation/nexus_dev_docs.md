# Configuration Manager - Developer Documentation

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Build System](#build-system)
4. [Code Structure](#code-structure)
5. [Database Layer](#database-layer)
6. [Template System](#template-system)
7. [QML Frontend](#qml-frontend)
8. [API Reference](#api-reference)
9. [Development Guidelines](#development-guidelines)
10. [Testing and Debugging](#testing-and-debugging)

---

## Project Overview

### Technology Stack
- **Framework:** Qt 6.8+
- **Language:** C++ (backend), QML/JavaScript (frontend)
- **Database:** SQLite 3
- **Build System:** CMake
- **UI Framework:** Qt Quick Controls 2 with Material Design
- **Resource System:** Qt Resource System (QRC)

### Project Structure
```
configurationManager/
├── CMakeLists.txt              # Build configuration
├── main.cpp                    # Application entry point
├── resources.qrc              # Resource definitions
├── templates.json             # Template definitions
├── Main.qml                   # Main UI interface
├── Configuration.[h|cpp]      # Configuration model class
├── ConfigurationModel.[h|cpp] # Database model
└── TemplateManager.[h|cpp]    # Template management
```

### Dependencies
- **Qt6::Quick** - QML engine and Quick controls
- **Qt6::Sql** - Database connectivity
- **Qt6::QuickControls2** - Modern UI controls
- **SQLite** - Embedded database (included with Qt)

---

## Architecture

### Design Pattern
The application follows a **Model-View-Controller (MVC)** pattern:
- **Model:** `ConfigurationModel` (QSqlTableModel-based)
- **View:** QML interface with Material Design
- **Controller:** C++ backend classes with QML integration

### Component Overview
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   QML Frontend  │◄──►│  C++ Backend     │◄──►│   SQLite DB     │
│   (Main.qml)    │    │  Model Classes   │    │ (configurations │
│                 │    │                  │    │      .db)       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
         ▲                       ▲
         │                       │
         ▼                       ▼
┌─────────────────┐    ┌──────────────────┐
│ Template System │    │  Resource System │
│ (templates.json)│    │  (resources.qrc) │
└─────────────────┘    └──────────────────┘
```

### Data Flow
1. **Application Startup:** Database initialization and template loading
2. **User Interaction:** QML interface triggers C++ model methods
3. **Data Processing:** Models handle validation and database operations
4. **UI Updates:** Qt's signal-slot mechanism updates the interface

---

## Build System

### CMake Configuration
The project uses modern CMake (3.16+) with Qt-specific functions:

#### Key CMake Functions Used
- `qt_standard_project_setup()` - Sets up Qt project defaults
- `qt_add_executable()` - Creates the main executable
- `qt_add_resources()` - Processes resource files
- `qt_add_qml_module()` - Handles QML module setup

#### Build Process
```bash
# Configure
cmake -B build -S .

# Build
cmake --build build

# Install (optional)
cmake --install build
```

### Resource Management
Resources are embedded using Qt's resource system:
- **templates.json** - Template definitions
- **Main.qml** - Main interface (via qt_add_qml_module)

---

## Code Structure

### C++ Classes

#### 1. Configuration Class
```cpp
// Configuration.h
class Configuration : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int param READ param WRITE setParam NOTIFY paramChanged)
    
public:
    explicit Configuration(QObject *parent = nullptr);
    // Getters and setters...
    
signals:
    void nameChanged();
    void paramChanged();
    
private:
    QString m_name;
    int m_param;
};
```

**Purpose:** Simple data model for configuration objects
**Usage:** Legacy class, primarily used for basic configuration representation

#### 2. ConfigurationModel Class
```cpp
// ConfigurationModel.h
class ConfigurationModel : public QSqlTableModel {
    Q_OBJECT
    
public:
    explicit ConfigurationModel(QObject *parent = nullptr, QSqlDatabase db = QSqlDatabase());
    
    // QML-accessible methods
    Q_INVOKABLE bool addConfigurationFromJson(const QString &type, int version, const QString &name, const QString &jsonData);
    Q_INVOKABLE bool updateConfigurationFromJson(int row, const QString &jsonData);
    Q_INVOKABLE bool removeConfiguration(int row);
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void setFilter(const QString &filter);
    Q_INVOKABLE QStringList distinctTypes() const;
    
protected:
    QHash<int, QByteArray> roleNames() const override;
    QVariant data(const QModelIndex &index, int role) const override;
};
```

**Purpose:** Database interface layer between QML and SQLite
**Key Features:**
- Template-based configuration management
- Dynamic filtering and searching
- JSON data serialization
- QML role mapping for ListView integration

#### 3. TemplateManager Class
```cpp
// TemplateManager.h
class TemplateManager : public QObject {
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
```

**Purpose:** Template system management and JSON processing
**Key Features:**
- Multi-source template loading (resources, filesystem)
- Fallback to default templates
- QML integration for template access

### Database Schema
```sql
CREATE TABLE configurations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    type TEXT,                    -- Template type (sensor, device, gateway)
    version INTEGER,              -- Template version
    name TEXT,                    -- User-defined name
    data TEXT,                    -- JSON configuration data
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### QML Structure
The main interface is built using Qt Quick Controls 2 with Material Design:

#### Main Components
- **ApplicationWindow:** Root container with Material theme
- **ToolBar:** Header with search and actions
- **RowLayout:** Two-panel layout (sidebar + main content)
- **ListView:** Configuration display with custom delegates
- **Dialog:** Modal dialogs for create/edit/delete operations

#### Key QML Properties
```qml
// Theme configuration
Material.theme: Material.Dark
Material.accent: Material.Purple
Material.primary: Material.DeepPurple

// Custom color palette
property color backgroundColor: "#1E1E2E"
property color cardColor: "#2A2A3A"
property color highlightColor: "#BB86FC"
```

---

## Database Layer

### Connection Management
Database connection is established in `main.cpp`:
```cpp
QSqlDatabase db = QSqlDatabase::addDatabase("QSQLITE");
db.setDatabaseName(dbFile);
if (!db.open()) {
    qFatal("Cannot open SQLite database");
}
```

### Model Integration
The `ConfigurationModel` extends `QSqlTableModel` for seamless Qt integration:

#### Key Methods
- **addConfigurationFromJson()** - Creates new configurations from JSON
- **updateConfigurationFromJson()** - Updates existing configurations
- **removeConfiguration()** - Deletes configurations with proper cleanup
- **distinctTypes()** - Returns available configuration types for filtering
- **setFilter()** - Applies SQL WHERE clauses for search/filter

#### Role Mapping
Custom roles for QML ListView integration:
```cpp
QHash<int, QByteArray> ConfigurationModel::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[Qt::UserRole + 1] = "id";
    roles[Qt::UserRole + 2] = "type";
    roles[Qt::UserRole + 3] = "version";
    roles[Qt::UserRole + 4] = "name";
    roles[Qt::UserRole + 5] = "data";
    return roles;
}
```

### Data Validation
Validation occurs at multiple levels:
1. **QML Frontend:** Real-time field validation
2. **Template System:** Type and range validation
3. **Database Model:** SQL constraint validation
4. **JSON Processing:** Parse and structure validation

---

## Template System

### Template Loading Hierarchy
1. **Qt Resources:** `:/templates.json`
2. **Application Directory:** `./templates.json`
3. **User Data Directory:** Platform-specific location
4. **Fallback:** Programmatically generated defaults

### Template Structure
```json
{
  "type": "template_id",
  "version": 1,
  "title": "Display Title",
  "description": "Template description",
  "fields": [
    {
      "id": "field_identifier",
      "label": "Field Label",
      "type": "string|int|bool",
      "required": true|false,
      "default": "default_value",
      "placeholder": "Placeholder text",
      "help": "Help description",
      "min": 0,           // int fields only
      "max": 100,         // int fields only
      "step": 1,          // int fields only
      "options": ["opt1", "opt2"] // string fields only
    }
  ]
}
```

### Template Processing
Templates are loaded and validated at startup:
```cpp
void TemplateManager::loadTemplates() {
    // Try multiple sources in priority order
    if (loadFromPath(":/templates.json")) return;
    if (loadFromPath(appDirPath)) return;
    if (loadFromPath(userDataPath)) return;
    
    // Fallback to defaults
    createDefaultTemplates();
}
```

### Field Type Mapping
| Template Type | QML Control | Validation |
|---------------|-------------|------------|
| `string` | TextField | Required, length, options |
| `int` | SpinBox | Required, min/max, step |
| `bool` | Switch | Default value |

---

## QML Frontend

### Component Architecture
The QML interface uses a modular approach with reusable components:

#### Main Window Structure
```qml
ApplicationWindow {
    // Header with search and actions
    header: ToolBar { ... }
    
    // Main content area
    RowLayout {
        // Left sidebar
        ColumnLayout {
            // Statistics card
            // Filters section
            // Template quick access
        }
        
        // Right main area
        ColumnLayout {
            // Configuration list
            ListView {
                model: configModel
                delegate: configurationDelegate
            }
        }
    }
}
```

#### State Management
The interface maintains several state variables:
- **currentSearchText:** Search query
- **selectedTypes:** Active type filters
- **displayedCount:** Filtered result count
- **deleteIndex:** Item pending deletion
- **suppressModelReload:** Prevents recursive updates

### Dialog System
Modal dialogs for configuration management:

#### Add/Edit Dialog Structure
```qml
Dialog {
    property var template: ({})
    property var formData: ({})
    property int templateVersion: 0  // Forces UI updates
    
    // Template selection
    ComboBox { model: templateManager.templates() }
    
    // Dynamic form generation
    Repeater {
        model: template.fields
        delegate: fieldDelegate  // Varies by field type
    }
}
```

### Data Binding
QML uses property bindings for reactive UI updates:
```qml
// Automatic count updates
Label {
    text: displayedCount + " result(s)"
}

// Dynamic filtering
function applyFilters() {
    var filter = buildFilterString()
    configModel.setFilter(filter)
    displayedCount = configModel.rowCount()
}
```

---

## API Reference

### ConfigurationModel API

#### Methods
```cpp
// Configuration management
Q_INVOKABLE bool addConfigurationFromJson(const QString &type, int version, const QString &name, const QString &jsonData);
Q_INVOKABLE bool updateConfigurationFromJson(int row, const QString &jsonData);
Q_INVOKABLE bool removeConfiguration(int row);

// Data access
Q_INVOKABLE void refresh();
Q_INVOKABLE void setFilter(const QString &filter);
Q_INVOKABLE QStringList distinctTypes() const;

// Legacy methods (for compatibility)
Q_INVOKABLE bool addConfiguration(const QString &name, int param);
Q_INVOKABLE bool updateConfiguration(int row, const QString &name, int param);
```

#### Signals
Inherits from `QSqlTableModel`:
- `rowsInserted(const QModelIndex &parent, int first, int last)`
- `rowsRemoved(const QModelIndex &parent, int first, int last)`
- `modelReset()`

### TemplateManager API

#### Methods
```cpp
Q_INVOKABLE QStringList templates() const;
Q_INVOKABLE QVariantMap getTemplate(const QString &name) const;
```

#### Internal Methods
```cpp
void loadTemplates();                           // Load from all sources
bool loadFromPath(const QString &path);         // Load from specific path
void createDefaultTemplates();                  // Generate fallback templates
```

### QML Integration

#### Exposed Objects
```cpp
// In main.cpp
engine.rootContext()->setContextProperty("configModel", &model);
engine.rootContext()->setContextProperty("templateManager", &tmplMgr);
```

#### Usage in QML
```qml
// Access model data
ListView {
    model: configModel
    delegate: Item {
        Text { text: model.name }      // Uses custom role mapping
        Text { text: model.type }
        Text { text: model.data }
    }
}

// Access templates
ComboBox {
    model: templateManager.templates()
    onCurrentTextChanged: {
        var template = templateManager.getTemplate(currentText)
        // Use template data...
    }
}
```

---

## Development Guidelines

### Code Style
- **C++ Standard:** C++17
- **Naming Convention:** camelCase for variables, PascalCase for classes
- **Include Guards:** Use `#pragma once` or traditional guards
- **Qt Conventions:** Follow Qt naming patterns (signals/slots)

### QML Guidelines
- **Property Naming:** Use camelCase consistently
- **Component Organization:** Separate complex delegates into components
- **State Management:** Minimize stateful components
- **Performance:** Use `Loader` for complex conditional UI

### Database Practices
- **Transactions:** Use transactions for multiple operations
- **Error Handling:** Always check SQL operation results
- **Prepared Statements:** Use for dynamic queries
- **Connection Management:** Reuse database connections

### Memory Management
- **Qt Object Tree:** Leverage Qt's parent-child ownership
- **QML Objects:** Avoid circular references
- **Smart Pointers:** Use when appropriate (rare in Qt applications)

### Template Design
- **Validation:** Include comprehensive field validation
- **Versioning:** Increment version for breaking changes
- **Documentation:** Include help text for complex fields
- **Defaults:** Provide sensible default values

---

## Testing and Debugging

### Debug Output
The application includes extensive debug logging:
```cpp
qDebug() << "Loading templates from:" << path;
qDebug() << "Template loaded:" << templateName;
qDebug() << "Filter applied:" << filterString;
```

### Common Debug Scenarios

#### Template Loading Issues
```cpp
// Check resource availability
if (QFile::exists(":/templates.json")) {
    qDebug() << "Resource file found";
} else {
    qDebug() << "Resource file missing";
}

// List all resources
QDir resourceDir(":/");
qDebug() << "Available resources:" << resourceDir.entryList();
```

#### Database Debugging
```cpp
// Check query execution
if (!query.exec("SELECT * FROM configurations")) {
    qWarning() << "Query failed:" << query.lastError().text();
}

// Verify table structure
QSqlQuery schemaQuery("PRAGMA table_info(configurations)");
while (schemaQuery.next()) {
    qDebug() << "Column:" << schemaQuery.value("name").toString();
}
```

#### QML Debugging
```qml
// Console output
console.log("Template data:", JSON.stringify(template))
console.log("Form data:", JSON.stringify(formData))

// Property debugging
onTemplateChanged: console.log("Template changed:", template)
```

### Performance Monitoring
- **Model Updates:** Monitor `select()` call frequency
- **Filter Operations:** Profile complex SQL WHERE clauses
- **QML Rendering:** Use Qt Quick Profiler for UI performance
- **Memory Usage:** Monitor with system tools or Qt Creator

### Unit Testing Approaches
```cpp
// Example test structure (using Qt Test framework)
class TestConfigurationModel : public QObject {
    Q_OBJECT
    
private slots:
    void testAddConfiguration();
    void testUpdateConfiguration();
    void testFilteringLogic();
    void testTemplateLoading();
};
```

### Build Configurations
```cmake
# Debug build with extra output
set(CMAKE_BUILD_TYPE Debug)
add_compile_definitions(QT_QML_DEBUG)

# Release build optimized
set(CMAKE_BUILD_TYPE Release)
add_compile_definitions(QT_NO_DEBUG_OUTPUT)
```

---

## Extending the Application

### Adding New Field Types
1. **Extend Template Schema:** Add new type to template validation
2. **Update QML Forms:** Add new delegate type for field rendering
3. **Implement Validation:** Add validation logic in ConfigurationModel
4. **Update Documentation:** Document the new field type

### Adding New Features
1. **Database Schema:** Modify if new columns needed
2. **Model Layer:** Extend ConfigurationModel with new methods
3. **QML Interface:** Add UI components and interactions
4. **Template Support:** Update template system if needed

### Internationalization
The application currently uses French labels but can be extended:
1. **Qt Linguist:** Use `tr()` functions for translatable strings
2. **QML Translation:** Use `qsTr()` for QML strings
3. **Template i18n:** Support multiple language templates

### Plugin Architecture
For advanced extensibility:
1. **QPluginLoader:** Load external configuration plugins
2. **Interface Definition:** Define plugin contracts
3. **Dynamic Templates:** Load templates from plugins
4. **Custom Validators:** Plugin-provided validation logic

---

This developer documentation provides comprehensive coverage of the Configuration Manager's architecture, implementation details, and extension points for future development.