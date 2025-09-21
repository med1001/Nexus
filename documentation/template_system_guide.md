# Template System Guide

## Table of Contents
1. [Overview](#overview)
2. [Template Structure](#template-structure)
3. [Field Types](#field-types)
4. [Creating Custom Templates](#creating-custom-templates)
5. [Template Examples](#template-examples)
6. [Best Practices](#best-practices)
7. [Validation Rules](#validation-rules)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The Configuration Manager uses a flexible JSON-based template system that allows you to define custom configuration types with specific fields, validation rules, and UI controls. This system enables you to create tailored configuration forms for any type of equipment or system.

### How Templates Work
1. **Templates are defined** in JSON format
2. **UI forms are generated** automatically based on template definitions
3. **Data validation** is applied according to field specifications
4. **Configurations are stored** as JSON data matching the template structure

### Template Loading Priority
The application searches for templates in the following order:
1. **Qt Resources** (`:/templates.json`) - embedded in the application
2. **Application Directory** (`./templates.json`) - next to the executable
3. **User Data Directory** - platform-specific location
4. **Default Templates** - fallback if no file is found

---

## Template Structure

### Root Template Object
Each template is a JSON object with the following structure:

```json
{
  "type": "unique_identifier",
  "version": 1,
  "title": "Display Title",
  "description": "Template description (optional)",
  "fields": [
    // Array of field definitions
  ]
}
```

### Template Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `type` | string | ✅ | Unique identifier for the template |
| `version` | integer | ✅ | Template version (increment for changes) |
| `title` | string | ❌ | Human-readable title displayed in UI |
| `description` | string | ❌ | Optional description of the template |
| `fields` | array | ✅ | Array of field definitions |

### Template File Format
Templates can be organized in two ways:

#### Array Format (Recommended)
```json
[
  {
    "type": "template1",
    "version": 1,
    "fields": [...]
  },
  {
    "type": "template2", 
    "version": 1,
    "fields": [...]
  }
]
```

#### Object Format
```json
{
  "template1": {
    "type": "template1",
    "version": 1,
    "fields": [...]
  },
  "template2": {
    "type": "template2",
    "version": 1,
    "fields": [...]
  }
}
```

---

## Field Types

### String Fields
Text input fields for free-form text entry.

```json
{
  "id": "device_name",
  "label": "Device Name",
  "type": "string",
  "required": true,
  "default": "Default Name",
  "placeholder": "Enter device name...",
  "help": "Unique identifier for the device",
  "options": ["option1", "option2", "option3"]
}
```

**String Field Properties:**
- `options` - When provided, creates a dropdown instead of text field
- `placeholder` - Hint text shown in empty field
- `default` - Initial value when creating new configurations

### Integer Fields
Numeric input fields with spinbox controls.

```json
{
  "id": "timeout_ms",
  "label": "Timeout (ms)",
  "type": "int",
  "required": true,
  "default": 5000,
  "min": 100,
  "max": 60000,
  "step": 100,
  "help": "Network timeout in milliseconds"
}
```

**Integer Field Properties:**
- `min` - Minimum allowed value
- `max` - Maximum allowed value  
- `step` - Increment/decrement step size
- `default` - Initial numeric value

### Boolean Fields
Toggle switches for true/false values.

```json
{
  "id": "enabled",
  "label": "Enable Device",
  "type": "bool",
  "default": true,
  "help": "Whether the device is active"
}
```

**Boolean Field Properties:**
- `default` - Initial true/false state

### Common Field Properties

| Property | Type | Description | Applies To |
|----------|------|-------------|------------|
| `id` | string | Unique field identifier (used in JSON data) | All |
| `label` | string | Display label in the UI | All |
| `type` | string | Field type: "string", "int", or "bool" | All |
| `required` | boolean | Whether field must be filled | All |
| `default` | varies | Default value for new configurations | All |
| `help` | string | Help text displayed as tooltip | All |

---

## Creating Custom Templates

### Step 1: Plan Your Template
Before writing JSON, consider:
- What equipment/system type are you configuring?
- What fields are essential vs. optional?
- What validation rules are needed?
- Are there predefined options for any fields?

### Step 2: Create Template JSON
Create or modify the `templates.json` file:

```json
[
  {
    "type": "weather_station",
    "version": 1,
    "title": "Weather Station Configuration",
    "description": "Settings for environmental monitoring stations",
    "fields": [
      {
        "id": "station_id",
        "label": "Station ID",
        "type": "string",
        "required": true,
        "placeholder": "e.g., WS-001"
      },
      {
        "id": "location",
        "label": "Location",
        "type": "string",
        "required": true,
        "placeholder": "GPS coordinates or address"
      },
      {
        "id": "sensors",
        "label": "Sensor Types",
        "type": "string",
        "options": ["temperature", "humidity", "pressure", "wind", "rain"],
        "help": "Select the primary sensor type"
      },
      {
        "id": "sample_rate",
        "label": "Sample Rate (minutes)",
        "type": "int",
        "min": 1,
        "max": 1440,
        "default": 15,
        "required": true
      },
      {
        "id": "data_logging",
        "label": "Enable Data Logging",
        "type": "bool",
        "default": true
      }
    ]
  }
]
```

### Step 3: Test Your Template
1. Save the `templates.json` file
2. Restart the Configuration Manager application
3. Verify your template appears in the template list
4. Test creating a configuration with your template
5. Check that validation rules work correctly

### Step 4: Iterate and Refine
- Add help text for complex fields
- Adjust min/max values based on testing
- Consider adding more field options
- Update the version number for significant changes

---

## Template Examples

### Example 1: Network Camera
```json
{
  "type": "ip_camera",
  "version": 1,
  "title": "IP Camera Configuration",
  "fields": [
    {
      "id": "camera_name",
      "label": "Camera Name",
      "type": "string",
      "required": true,
      "placeholder": "Front Door Camera"
    },
    {
      "id": "ip_address",
      "label": "IP Address", 
      "type": "string",
      "required": true,
      "placeholder": "192.168.1.100"
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
      "label": "Frame Rate (FPS)",
      "type": "int",
      "min": 1,
      "max": 60,
      "default": 30
    },
    {
      "id": "night_vision",
      "label": "Night Vision",
      "type": "bool",
      "default": false
    },
    {
      "id": "motion_detection",
      "label": "Motion Detection",
      "type": "bool", 
      "default": true
    }
  ]
}
```

### Example 2: Solar Panel System
```json
{
  "type": "solar_panel",
  "version": 1,
  "title": "Solar Panel Configuration",
  "description": "Configuration for photovoltaic systems",
  "fields": [
    {
      "id": "system_name",
      "label": "System Name",
      "type": "string",
      "required": true
    },
    {
      "id": "panel_count",
      "label": "Number of Panels",
      "type": "int",
      "min": 1,
      "max": 1000,
      "required": true
    },
    {
      "id": "panel_wattage",
      "label": "Panel Wattage (W)",
      "type": "int",
      "min": 50,
      "max": 500,
      "step": 25,
      "default": 300
    },
    {
      "id": "inverter_type",
      "label": "Inverter Type",
      "type": "string",
      "options": ["string", "micro", "power_optimizer"],
      "required": true
    },
    {
      "id": "grid_connected",
      "label": "Grid Connected",
      "type": "bool",
      "default": true
    },
    {
      "id": "battery_backup",
      "label": "Battery Backup",
      "type": "bool",
      "default": false
    }
  ]
}
```

### Example 3: Industrial Sensor
```json
{
  "type": "industrial_sensor",
  "version": 1,
  "title": "Industrial Sensor Configuration",
  "fields": [
    {
      "id": "sensor_id",
      "label": "Sensor ID",
      "type": "string",
      "required": true,
      "help": "Unique identifier for tracking"
    },
    {
      "id": "measurement_type",
      "label": "Measurement Type",
      "type": "string",
      "options": ["temperature", "pressure", "flow", "level", "ph", "conductivity"],
      "required": true
    },
    {
      "id": "range_min",
      "label": "Range Minimum",
      "type": "int",
      "help": "Minimum measurement value"
    },
    {
      "id": "range_max", 
      "label": "Range Maximum",
      "type": "int",
      "help": "Maximum measurement value"
    },
    {
      "id": "accuracy",
      "label": "Accuracy (%)",
      "type": "int",
      "min": 1,
      "max": 100,
      "default": 95
    },
    {
      "id": "calibration_required",
      "label": "Requires Calibration",
      "type": "bool",
      "default": true
    }
  ]
}
```

---

## Best Practices

### Template Design
- **Use descriptive IDs**: Field IDs should be clear and meaningful
- **Provide helpful labels**: Use clear, concise labels that users understand  
- **Add help text**: Include help for complex or technical fields
- **Set reasonable defaults**: Provide sensible default values
- **Group related fields**: Organize fields logically in the array

### Field Validation  
- **Mark required fields**: Use `required: true` for essential fields
- **Set appropriate limits**: Use min/max for numeric fields
- **Use options wisely**: Provide dropdown options for finite sets of values
- **Consider step sizes**: Use meaningful step values for numeric inputs

### Versioning
- **Start with version 1**: Begin all templates with `"version": 1`
- **Increment for breaking changes**: Bump version when modifying field structure
- **Document changes**: Keep track of what changed between versions
- **Consider migration**: Plan how existing configurations will handle template updates

### Performance
- **Limit field count**: Too many fields can make forms unwieldy
- **Optimize options**: Don't create dropdowns with hundreds of options
- **Use appropriate types**: Choose the most suitable field type for each use case

---

## Validation Rules

### Built-in Validation
The application automatically validates:

#### String Fields
- **Required check**: Non-empty string for required fields
- **Option validation**: Value must be from options array (if provided)

#### Integer Fields  
- **Type validation**: Must be a valid integer
- **Range validation**: Must be between min and max values (if specified)
- **Required check**: Must have a value for required fields

#### Boolean Fields
- **Type validation**: Must be true or false
- **Default handling**: Uses default value if not specified

### Custom Validation
Currently, the application doesn't support custom validation rules beyond the built-in types. For complex validation:
- Use string fields with options for controlled input
- Set appropriate min/max ranges for integers
- Consider splitting complex fields into multiple simpler fields

### Error Handling
When validation fails, the application:
- Shows specific error messages
- Highlights problematic fields
- Prevents saving until all validation passes
- Lists all missing required fields

---

## Troubleshooting

### Template Not Appearing

**Issue**: Custom template doesn't show in the application

**Solutions**:
1. **Check JSON syntax**: Validate your JSON using an online validator
2. **Verify file location**: Ensure `templates.json` is in the correct directory
3. **Restart application**: Changes require an application restart
4. **Check console output**: Look for parsing error messages

### Field Not Displaying Correctly

**Issue**: Field appears different than expected

**Solutions**:
1. **Verify field type**: Ensure type is "string", "int", or "bool"
2. **Check required properties**: All fields need `id`, `label`, and `type`
3. **Validate property values**: Ensure min < max for integer fields
4. **Remove extra properties**: Unknown properties are ignored

### Validation Not Working

**Issue**: Validation rules not being enforced

**Solutions**:
1. **Check property spelling**: Ensure correct property names (`min`, not `minimum`)
2. **Verify data types**: Numeric properties should be numbers, not strings
3. **Test step by step**: Create simple test cases to isolate issues
4. **Review field definition**: Compare with working examples

### Performance Issues

**Issue**: Application slow when using custom templates

**Solutions**:
1. **Reduce field count**: Limit to essential fields only
2. **Optimize options arrays**: Keep dropdown lists reasonably sized
3. **Simplify help text**: Long help text can impact rendering
4. **Check for loops**: Avoid circular references in template structure

### Data Loss

**Issue**: Existing configurations not working with updated templates

**Solutions**:
1. **Increment version number**: Update template version for breaking changes
2. **Backup database**: Always backup `configurations.db` before template changes
3. **Test compatibility**: Verify existing data works with new template
4. **Consider migration**: Plan how to handle incompatible changes

---

## Advanced Topics

### Dynamic Templates
Currently, templates are static JSON files. Future enhancements might include:
- Loading templates from external APIs
- User-created templates through the UI
- Template inheritance and composition
- Conditional fields based on other field values

### Integration with External Systems
Templates can be designed to work with external systems:
- Use consistent field naming conventions
- Include metadata fields for system integration
- Design for data export/import compatibility
- Consider API requirements in field design

### Multi-language Support
For international deployments:
- Keep field IDs in English for consistency
- Translate labels and help text
- Consider cultural differences in default values
- Plan for right-to-left languages if needed

---

This template system provides a powerful foundation for creating custom configuration interfaces while maintaining type safety and user experience consistency.