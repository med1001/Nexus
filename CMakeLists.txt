# Updated CMakeLists.txt
# Key changes:
#  - Use qt_add_resources(...) to generate resource source files and add them
#    via target_sources (instead of passing the .qrc into a FILES list).
#  - Keep QML files handled by qt_add_qml_module (remove them from .qrc to
#    avoid duplication; prefer one approach).
#  - Small comments to guide future edits.

cmake_minimum_required(VERSION 3.16)

project(configurationManager VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

# Find Qt components
find_package(Qt6 REQUIRED COMPONENTS Quick Sql QuickControls2)

qt_standard_project_setup(REQUIRES 6.8)

# Add executable sources
qt_add_executable(appconfigurationManager
    main.cpp
    Configuration.cpp
    ConfigurationModel.cpp
    TemplateManager.cpp
    Configuration.h
    ConfigurationModel.h
    TemplateManager.h
)

# ------------------------------------------------------------------
# Resources: generate C++ sources from resources.qrc and attach to target
# ------------------------------------------------------------------
# IMPORTANT: resources.qrc should reference templates.json (and any other
# non-QML assets). Do NOT list QML files here if you also add them via
# qt_add_qml_module -- choose one mechanism to avoid duplication.

qt_add_resources(APP_RESOURCE_SOURCES resources.qrc)

# Add the generated resource sources to the executable
target_sources(appconfigurationManager
    PRIVATE
        ${APP_RESOURCE_SOURCES}
)

# ------------------------------------------------------------------
# QML module
# ------------------------------------------------------------------
# Keep QML files handled by qt_add_qml_module. If you prefer to embed
# QML in the qrc, remove them from QML_FILES and manage them via the .qrc
# (but avoid doing both).

qt_add_qml_module(appconfigurationManager
    URI configurationManager
    VERSION 1.0
    QML_FILES
        Main.qml
)

# Link against Qt libraries
target_link_libraries(appconfigurationManager
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Sql
    PRIVATE Qt6::QuickControls2
)

# Set target properties (keeps the values you had previously)
set_target_properties(appconfigurationManager PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# End of file
