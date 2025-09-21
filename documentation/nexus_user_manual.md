# Configuration Manager - User Manual

## Table of Contents
1. [Introduction](#introduction)
2. [Installation and Setup](#installation-and-setup)
3. [User Interface](#user-interface)
4. [Configuration Management](#configuration-management)
5. [Template System](#template-system)
6. [Search and Filtering](#search-and-filtering)
7. [Advanced Features](#advanced-features)
8. [Troubleshooting](#troubleshooting)

---

## Introduction

The **Configuration Manager** is a modern Qt application designed to create, manage, and organize configurations for different types of equipment (sensors, devices, gateways). The application features an intuitive dark-themed interface and offers advanced filtering and search capabilities.

### Key Features
- ✨ Template-based configuration creation
- 🔍 Advanced search and filtering system
- 📊 Real-time statistics overview
- 🎨 Modern dark-themed interface
- 💾 Local storage with SQLite database
- 📝 Configurable templates via JSON files

---

## Installation and Setup

### System Requirements
- **Operating System:** Windows 10/11, macOS 10.15+, or Linux (Ubuntu 18.04+)
- **Qt Version:** 6.8 or higher
- **Disk Space:** ~50 MB free space
- **RAM:** Minimum 512 MB available

### Installation
1. **Download:** Obtain the `configurationManager` executable from your distribution source
2. **First Launch:** Run the application - it will automatically create:
   - A local database `configurations.db`
   - Default templates if not found
3. **Verification:** The interface should open with the purple dark theme

### File Structure
```
[Installation Directory]/
├── configurationManager(.exe)    # Main executable
├── configurations.db             # Database (created on first launch)
└── templates.json               # Configuration templates (optional)
```

---

## User Interface

### Overview
The application features a two-panel interface:
- **Left Panel:** Statistics and filtering controls
- **Main Panel:** Configuration list with actions

### Application Header
- **Title:** "⚙️ Configuration Manager" (displays as "Gestionnaire de Configurations")
- **Search Bar:** Real-time search through configuration names
- **"New Configuration" Button:** Quick access to configuration creation

### Side Panel

#### 1. Overview Card
Displays real-time statistics:
- **Configurations:** Number of currently displayed configurations (after filtering)
- **Templates:** Total number of available templates

#### 2. Filters Section
- **Type Checkboxes:** Dynamic filtering by configuration type
- **"Reset Filters" Button:** Restores all filters to their initial state

#### 3. Available Templates
Clickable list of templates for quick creation of new configurations.

### Main Configuration List

Each configuration is displayed in a card containing:
- **Header:** Configuration ID and type
- **Name:** Descriptive name of the configuration
- **Data Preview:** Compact preview of JSON content
- **Actions:**
  - **✏️ Edit:** Opens the configuration editor
  - **🗑 Delete:** Deletes after confirmation
  - **⋯ Details:** Shows complete JSON content

---

## Configuration Management

### Creating a New Configuration

#### Method 1: Main Button
1. Click **"New Configuration"** in the header
2. Select a template from the dropdown list
3. Fill in required fields (marked with an asterisk *)
4. Click **"OK"** to save

#### Method 2: Quick Access via Template
1. In the side panel, click on a template in "Available Templates"
2. The dialog opens automatically with the selected template

### Editing a Configuration
1. Click **"✏️ Edit"** on the desired configuration
2. Modify the necessary fields
3. Click **"OK"** to save changes

**Note:** The template type cannot be modified after creation.

### Deleting a Configuration
1. Click **"🗑 Delete"** on the configuration
2. Confirm deletion in the dialog
3. This action is **irreversible**

### Viewing Details
1. Click the **"⋯"** (details) button
2. A window opens with formatted JSON content
3. Use the **"Copy"** button to copy content to clipboard

---

## Template System

The Configuration Manager uses a flexible template system based on the `templates.json` file. This system allows you to define custom configuration types with specific fields and validation rules.

### Template File Location
The application looks for templates in the following order:
1. **Qt Resources:** `:/templates.json` (embedded in the application)
2. **Application Directory:** `templates.json` in the same folder as the executable
3. **Application Data Directory:** Platform-specific data directory
4. **Fallback:** Creates default templates if no file is found

### Current Template Structure

The current `templates.json` contains an array of three template definitions:

#### 1. Sensor Template
```json
{
  "type": "sensor",
  "version": 1,
  "title": "Configuration — Capteur",
  "description": "Paramètres d'un capteur (mesure périodique).",
  "fields": [...]
}
```

**Available Fields:**
- **name** (string, required): Sensor name with placeholder "Ex: Température salle A"
- **model** (string, required): Hardware reference with placeholder "Ex: SHT31"
- **rate** (int, required): Sampling frequency in Hz (1-3600, default: 10)
- **unit** (string, required): Physical unit with options ["°C","°F","%","m/s","Pa","lux"]
- **precision** (int): Decimal places (0-6, default: 2)
- **enabled** (bool): Enable/disable toggle (default: true)
- **tags** (string): Comma-separated keywords

#### 2. Device Template
```json
{
  "type": "device",
  "version": 1,
  "title": "Configuration — Appareil",
  "description": "Paramètres d'un appareil réseau/edge.",
  "fields": [...]
}
```

**Available Fields:**
- **name** (string, required): Device name
- **hostname** (string, required): Network address or mDNS name
- **port** (int): Service port (1-65535, default: 1883)
- **protocol** (string, required): Communication protocol with options ["mqtt", "http", "coap", "custom"]
- **authType** (string): Authentication type with options ["none","basic","token","tls"]
- **timeout** (int): Network timeout in milliseconds (100-60000, default: 5000)

#### 3. Gateway Template
```json
{
  "type": "gateway",
  "version": 1,
  "title": "Configuration — Passerelle",
  "description": "Regroupe plusieurs devices et options de transmission.",
  "fields": [...]
}
```

**Available Fields:**
- **name** (string, required): Gateway name
- **location** (string): Physical location
- **uploadInterval** (int): Upload frequency in seconds (10-86400, default: 60)
- **backupEnabled** (bool): Enable local backup (default: true)
- **notes** (string): Free-form comments

### Customizing Templates

You can customize the templates by modifying the `templates.json` file according to your needs:

#### Field Definition Structure
Each field in a template can have the following properties:

```json
{
  "id": "unique_field_identifier",
  "label": "Display Label",
  "type": "string|int|bool",
  "required": true|false,
  "default": "default_value",
  "placeholder": "Placeholder text",
  "help": "Help text description",
  "min": 0,        // For int fields
  "max": 100,      // For int fields
  "step": 1,       // For int fields
  "options": ["option1", "option2"]  // For string fields with predefined values
}
```

#### Supported Field Types
- **string**: Text input field
- **int**: Numeric input with spinbox controls
- **bool**: Toggle switch for true/false values

#### Adding Custom Templates
1. **Edit templates.json**: Add your custom template to the array
2. **Define unique type**: Use a unique `type` identifier
3. **Set version**: Increment version for template updates
4. **Add fields**: Define all necessary fields with proper validation
5. **Restart application**: Changes take effect after restart

#### Template Validation
The application validates templates on startup:
- **Required fields**: `type`, `version`, `fields` array
- **Field validation**: Checks for valid field types and properties
- **Error handling**: Falls back to default templates if JSON is invalid

#### Example Custom Template
```json
{
  "type": "camera",
  "version": 1,
  "title": "Camera Configuration",
  "description": "Settings for surveillance cameras",
  "fields": [
    {
      "id": "name",
      "label": "Camera Name",
      "type": "string",
      "required": true,
      "placeholder": "Ex: Front Door Cam"
    },
    {
      "id": "resolution",
      "label": "Resolution",
      "type": "string",
      "options": ["720p", "1080p", "4K"],
      "default": "1080p",
      "required": true
    },
    {
      "id": "fps",
      "label": "Frames per Second",
      "type": "int",
      "min": 1,
      "max": 60,
      "default": 30
    },
    {
      "id": "nightVision",
      "label": "Night Vision",
      "type": "bool",
      "default": false
    }
  ]
}
```

---

## Search and Filtering

### Text Search
- **Location:** Search bar in the header
- **Functionality:** Instant search with 250ms delay
- **Scope:** Searches through configuration names
- **Case Insensitive:** "SENSOR" will find "sensor"

### Type Filtering
- **Location:** "Filters" section in side panel
- **Dynamic Types:** Available types are automatically detected
- **Multiple Selection:** Several types can be selected simultaneously
- **Automatic Update:** Filters update when adding/removing configurations

### Filter Combination
- Search and type filters combine with logical AND
- The "result(s)" counter updates in real-time
- Use "Reset Filters" to return to full display

---

## Advanced Features

### Data Validation
The application performs multiple validation levels:
- **Required Fields:** Verification before saving
- **Data Types:** Validation of integers, booleans, etc.
- **Value Ranges:** Respect for min/max limits defined in templates
- **Error Messages:** Clear display of encountered issues

### Supported Field Types

#### Text Field (`string`)
- Free text input
- Placeholder text support
- Presence validation for required fields
- Options list support for predefined values

#### Numeric Field (`int`)
- SpinBox interface with +/- controls
- Configurable limits (min/max)
- Custom increment step
- Automatic range validation

#### Boolean Field (`bool`)
- Switch interface for on/off
- Configurable default value
- Clear visual state indication

### Error Handling
- **Contextual Messages:** Precise error descriptions
- **Error Popup:** Non-blocking interface
- **Real-time Validation:** Prevention of input errors

### Adaptive Interface
- **Resizable Windows:** Minimum size respected (1000x600)
- **Draggable Dialogs:** Click-drag on title bar
- **Scroll Bars:** Automatic appearance when needed

---

## Troubleshooting

### Startup Issues

**Symptom:** Application won't start
**Solutions:**
1. Verify Qt 6.8+ is installed on the system
2. Check write permissions in the installation directory
3. Try running as administrator/sudo

**Symptom:** "Cannot open SQLite database" error
**Solutions:**
1. Check available disk space
2. Verify write permissions in the directory
3. Delete `configurations.db` to recreate it

### Functionality Issues

**Symptom:** Templates don't load
**Solutions:**
1. Check for the presence of `templates.json` file
2. Application will create default templates if file is missing
3. Verify JSON syntax of the templates file
4. Check application console/debug output for parsing errors

**Symptom:** Search doesn't work
**Solutions:**
1. Wait 250ms after typing (debounce delay)
2. Verify that configurations match the criteria
3. Reset filters if necessary

**Symptom:** Cannot save a configuration
**Solutions:**
1. Verify all required fields are filled
2. Check that numeric values are within allowed ranges
3. Restart the application if the problem persists

### Interface Issues

**Symptom:** Interface poorly displayed or cut off
**Solutions:**
1. Check screen resolution (minimum 1000x600)
2. Manually adjust window size
3. Restart the application

**Symptom:** Incorrect theme or colors
**Solutions:**
1. Application forces Material Design dark theme
2. Restart application if display is incorrect
3. Check graphics drivers

### Data Recovery

**In case of data loss:**
- Configurations are stored in `configurations.db`
- Perform regular backups of this file
- File can be copied to another installation

**Backup Format:**
- Standard SQLite format
- Viewable with tools like DB Browser for SQLite
- Table structure: `id, type, version, name, data, created_at`

### Template Issues

**Symptom:** Custom templates not appearing
**Solutions:**
1. Verify `templates.json` syntax with a JSON validator
2. Check that the file is in the correct location
3. Restart the application after template changes
4. Check console output for template parsing errors

**Symptom:** Field validation not working correctly
**Solutions:**
1. Verify field type definitions in templates
2. Check min/max values for numeric fields
3. Ensure required fields are properly marked
4. Validate JSON structure of templates

---

## Support and Contact

For any issues not resolved by this manual:
1. First check the application console/log messages
2. Collect information about your environment (OS, Qt version)
3. Note the exact steps that reproduce the problem
4. Contact technical support with this information

**Useful System Information:**
- Application version
- Operating system and version
- Size of the `configurations.db` database
- Content of `templates.json` file (if modified)
- Console error messages or debug output