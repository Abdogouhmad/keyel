# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "rust_lib_keyel")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
# NOTE: the Windows path depth differs from Linux/macOS on purpose. Flutter
# builds this plugin through the symlink
#   windows/flutter/ephemeral/.plugin_symlinks/rust_lib_keyel/windows/
# and Windows collapses `..` LEXICALLY, before following that symlink (POSIX
# resolves the symlink first). So `../../rust` would collapse to the bogus
# `.plugin_symlinks/rust`; we must walk all the way up to the repo root, which
# is 6 levels from here. This mirrors the flutter_rust_bridge Windows template
# (../../../../../../). See docs/DECISIONS.md.
apply_cargokit(${PROJECT_NAME} ../../../../../../rust rust_lib_keyel "")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(rust_lib_keyel_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  PARENT_SCOPE
)
