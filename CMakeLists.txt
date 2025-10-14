cmake_minimum_required(VERSION 3.16)

project(configurationManager VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

# Find Qt components
find_package(Qt6 REQUIRED COMPONENTS Quick Sql QuickControls2)

qt_standard_project_setup(REQUIRES 6.8)

# ----------------------------
# Sources core -> library
# ----------------------------
set(SRC_CORE
    configuration.cpp
    configurationModel.cpp
    templateManager.cpp
)

set(HEADER_CORE
    configuration.h
    configurationModel.h
    templateManager.h
)

# Build a library target so tests can link it easily
add_library(configmanager STATIC
    ${SRC_CORE}
    ${HEADER_CORE}
)

target_include_directories(configmanager
    PUBLIC ${CMAKE_SOURCE_DIR}        # pour que les tests puissent inclure "configuration.h"
)

target_link_libraries(configmanager
    PUBLIC Qt6::Sql
    PUBLIC Qt6::Core
)

# ----------------------------
# Executable (QML app)
# ----------------------------
qt_add_executable(appconfigurationManager
    main.cpp
)

# Resources: generate sources from resources.qrc
qt_add_resources(APP_RESOURCE_SOURCES resources.qrc)

target_sources(appconfigurationManager
    PRIVATE
        ${APP_RESOURCE_SOURCES}
)

# QML module
qt_add_qml_module(appconfigurationManager
    URI configurationManager
    VERSION 1.0
    QML_FILES
        Main.qml
)

# Link exe against our library and Qt
target_link_libraries(appconfigurationManager
    PRIVATE configmanager    # <-- link the library with core logic
    PRIVATE Qt6::Quick
    PRIVATE Qt6::QuickControls2
)

# Keep previous target properties if needed
set_target_properties(appconfigurationManager PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

# ----------------------------
# Enable testing and add tests dir
# ----------------------------
enable_testing()
add_subdirectory(tests)
