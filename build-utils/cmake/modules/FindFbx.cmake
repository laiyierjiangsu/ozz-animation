# This module will try to located FBX SDK folder, based on the standard
# directory structure proposed by Autodesk.
# On every platform, the module will look for libraries that matches the
# currently selected cmake generator.
# A version can be specified to the find_package function.
#
# Once done, it will define
#  FBX_FOUND - System has Fbx SDK installed
#  FBX_INCLUDE_DIRS - The Fbx SDK include directories
#  FBX_LIBRARIES - The libraries needed to use Fbx SDK
#  FBX_LIBRARIES_DEBUG - The libraries needed to use debug Fbx SDK
#  FBX_SHARED_LIBRARIES - The shared library file (dll, so) to use Fbx 
#  FBX_SHARED_LIBRARIES_DEBUG - The shared library file (dll, so) to use debug
#                               Fbx SDK
#
# A cmake target named fbx::sdk is also created. Adding this target to your
# project via target_link_libraries will setup everything automatically.
#
# It accepts the following variables as input:
#  FBX_SHARED - Optional. Select whether to use the shared version fbx sdk.
#  FBX_MSVC_RT_DLL - Optional. Select whether to use the DLL version or the
#                    static library version of the Visual C++ runtime library.
#                    Default is ON (aka, DLL version: /MD).
#
# Known issues:
# - On ALL platforms: If there are multiple FBX SDK version installed, the
# current implementation will select the first one it finds.
# - On MACOS: If there are multiple FBX SDK compiler supported (clang or gcc),
# the current implementation will select the first one it finds.

#----------------------------------------------------------------------------#
#                                                                            #
# ozz-animation is hosted at http://github.com/guillaumeblanc/ozz-animation  #
# and distributed under the MIT License (MIT).                               #
#                                                                            #
# Copyright (c) 2019 Guillaume Blanc                                         #
#                                                                            #
# Permission is hereby granted, free of charge, to any person obtaining a    #
# copy of this software and associated documentation files (the "Software"), #
# to deal in the Software without restriction, including without limitation  #
# the rights to use, copy, modify, merge, publish, distribute, sublicense,   #
# and/or sell copies of the Software, and to permit persons to whom the      #
# Software is furnished to do so, subject to the following conditions:       #
#                                                                            #
# The above copyright notice and this permission notice shall be included in #
# all copies or substantial portions of the Software.                        #
#                                                                            #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    #
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    #
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER        #
# DEALINGS IN THE SOFTWARE.                                                  #
#                                                                            #
#----------------------------------------------------------------------------#

###############################################################################
# Generic library search function definition
###############################################################################
function(FindFbxLibrariesGeneric _FBX_ROOT_DIR _OUT_FBX_LIBRARIES _OUT_FBX_LIBRARIES_DEBUG _OUT_FBX_SHARED_LIBRARIES _OUT_FBX_SHARED_LIBRARIES_DEBUG)
  # Directory structure depends on the platform:
  # - Windows: \lib\<compiler_version>\<processor_type>\<build_mode>
  # - Mac OSX: \lib\<compiler_version>\ub\<processor_type>\<build_mode>
  # - Linux: \lib\<compiler_version>\<build_mode>

  # Figures out matching compiler/os directory.
  
  if("x${CMAKE_CXX_COMPILER_ID}" STREQUAL "xMSVC")
    if(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19.10)
      set(FBX_CP_PATH "vs2017")
    elseif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 19)
      set(FBX_CP_PATH "vs2015")
    elseif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 18)
      set(FBX_CP_PATH "vs2013")
    elseif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 17)
      set(FBX_CP_PATH "vs2012")
    elseif(NOT CMAKE_CXX_COMPILER_VERSION VERSION_LESS 16)
      set(FBX_CP_PATH "vs2010")
    else()
      message ("Unsupported MSVC compiler version ${CMAKE_CXX_COMPILER_VERSION}.")
      return()
    endif()
  elseif(APPLE)
    set(FBX_CP_PATH "*")
  else()
    set(FBX_CP_PATH "*")
  endif()

  # Detects current processor type.
  if(NOT APPLE) # No <processor_type> on APPLE platform
    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      set(FBX_PROCESSOR_PATH "x64")
    else()
      set(FBX_PROCESSOR_PATH "x86")
    endif()
  endif()

  # Select whether to use the DLL version or the static library version of fbx sdk.
  if (FBX_SHARED)
    # Dynamic libraries
    set(FBX_SEARCH_LIB_NAMES ${FBX_SEARCH_LIB_NAMES} libfbxsdk.lib libfbxsdk.dylib libfbxsdk.so)
  else()
    # static library names
    set(FBX_SEARCH_LIB_NAMES ${FBX_SEARCH_LIB_NAMES} libfbxsdk.a libfbxsdk-static.a)

    # Select whether to use the DLL version or the static library version of the Visual C++ runtime library.
    # Default is "md", aka use the multithread DLL version of the run-time library.
    if (NOT DEFINED FBX_MSVC_RT_DLL OR FBX_MSVC_RT_DLL)
      set(FBX_SEARCH_LIB_NAMES ${FBX_SEARCH_LIB_NAMES} libfbxsdk-md.lib)
    else()
      set(FBX_SEARCH_LIB_NAMES ${FBX_SEARCH_LIB_NAMES} libfbxsdk-mt.lib)
    endif()
  endif()

  # Set search path.
  set(FBX_SEARCH_LIB_PATH "${_FBX_ROOT_DIR}lib/${FBX_CP_PATH}/${FBX_PROCESSOR_PATH}")

  find_library(FBX_LIB
    ${FBX_SEARCH_LIB_NAMES}
    HINTS "${FBX_SEARCH_LIB_PATH}/release/")

  if(FBX_LIB)
    # Searches debug version also
    find_library(FBX_LIB_DEBUG
      ${FBX_SEARCH_LIB_NAMES}
      HINTS "${FBX_SEARCH_LIB_PATH}/debug/")

    # Looks for shared libraries
    if (FBX_SHARED)
      set(FBX_SEARCH_SHARED_LIB_NAMES libfbxsdk.dll libfbxsdk.so libfbxsdk.dylib)

      find_file(FBX_SHARED_LIB
        ${FBX_SEARCH_SHARED_LIB_NAMES}
        HINTS "${FBX_SEARCH_LIB_PATH}/release/")
      find_file(FBX_SHARED_LIB_DEBUG
        ${FBX_SEARCH_SHARED_LIB_NAMES}
        HINTS "${FBX_SEARCH_LIB_PATH}/debug/")

      set(${_OUT_FBX_SHARED_LIBRARIES} ${FBX_SHARED_LIB} PARENT_SCOPE)
      set(${_OUT_FBX_SHARED_LIBRARIES_DEBUG} ${FBX_SHARED_LIB_DEBUG} PARENT_SCOPE)
    endif()

    # Create a target for a convenient use of the sdk with cmake
    if(FBX_SHARED)
      add_library(fbx::sdk SHARED IMPORTED GLOBAL)
      set_property(TARGET fbx::sdk PROPERTY IMPORTED_LOCATION ${FBX_SHARED_LIB})
      set_property(TARGET fbx::sdk PROPERTY IMPORTED_LOCATION_DEBUG ${FBX_SHARED_LIB_DEBUG})
      set_property(TARGET fbx::sdk PROPERTY IMPORTED_IMPLIB ${FBX_LIB})
      set_property(TARGET fbx::sdk PROPERTY IMPORTED_IMPLIB_DEBUG ${FBX_LIB_DEBUG})
      target_compile_definitions(fbx::sdk INTERFACE FBXSDK_SHARED)
    else()
      add_library(fbx::sdk STATIC IMPORTED GLOBAL)
      set_property(TARGET fbx::sdk PROPERTY IMPORTED_LOCATION ${FBX_LIB})
      set_property(TARGET fbx::sdk PROPERTY IMPORTED_LOCATION_DEBUG ${FBX_LIB_DEBUG})
    endif()
    target_include_directories(fbx::sdk INTERFACE "${_FBX_ROOT_DIR}include/")
    target_compile_options(fbx::sdk
      INTERFACE $<$<BOOL:${W_NULL_DEREFERENCE}>:-Wno-null-dereference>
      INTERFACE $<$<BOOL:${W_PRAGMA_PACK}>:-Wno-pragma-pack>)

    FindFbxVersion(${FBX_ROOT_DIR} PATH_VERSION)

    # 2019+ non-DLL SDK needs to link against bundled libxml and zlib
    if(PATH_VERSION GREATER_EQUAL "2019.1")
      if("x${CMAKE_CXX_COMPILER_ID}" STREQUAL "xMSVC")
        set(ADDITIONAL_LIB_SEARCH_PATH_RELEASE "${FBX_SEARCH_LIB_PATH}/release/")
        set(ADDITIONAL_LIB_SEARCH_PATH_DEBUG "${FBX_SEARCH_LIB_PATH}/debug/")
        if (NOT DEFINED FBX_MSVC_RT_DLL OR FBX_MSVC_RT_DLL)
          set(XML_SEARCH_LIB_NAMES libxml2-md.lib)
          set(Z_SEARCH_LIB_NAMES zlib-md.lib)
        else()
          set(XML_SEARCH_LIB_NAMES libxml2-mt.lib)
          set(Z_SEARCH_LIB_NAMES zlib-mt.lib)
        endif()
      else()
        set(ADDITIONAL_LIB_SEARCH_PATH_RELEASE "")
        set(ADDITIONAL_LIB_SEARCH_PATH_DEBUG "")
        set(XML_SEARCH_LIB_NAMES "xml2")
        set(Z_SEARCH_LIB_NAMES "z")
      endif()

      find_library(XML_LIB
        ${XML_SEARCH_LIB_NAMES}
        HINTS ${ADDITIONAL_LIB_SEARCH_PATH_RELEASE})
      find_library(XML_LIB_DEBUG
        ${XML_SEARCH_LIB_NAMES}
        HINTS ${ADDITIONAL_LIB_SEARCH_PATH_DEBUG})

      if(XML_LIB AND XML_LIB_DEBUG)
        target_link_libraries(fbx::sdk INTERFACE optimized ${XML_LIB})
        target_link_libraries(fbx::sdk INTERFACE debug ${XML_LIB_DEBUG})
      else()
        message(WARNING "FBX found but required libxml2 was not found!")
      endif()

      find_library(Z_LIB
        ${Z_SEARCH_LIB_NAMES}
        HINTS ${ADDITIONAL_LIB_SEARCH_PATH_RELEASE})          
      find_library(Z_LIB_DEBUG
        ${Z_SEARCH_LIB_NAMES} 
        HINTS ${ADDITIONAL_LIB_SEARCH_PATH_DEBUG})

      if(Z_LIB AND Z_LIB_DEBUG)
        target_link_libraries(fbx::sdk INTERFACE optimized ${Z_LIB})
        target_link_libraries(fbx::sdk INTERFACE debug ${Z_LIB_DEBUG})
      else()
        message(WARNING "FBX found but required zlib was not found!")
      endif()

      list(APPEND FBX_LIB ${XML_LIB} ${Z_LIB})
      list(APPEND FBX_LIB_DEBUG ${XML_LIB_DEBUG} ${Z_LIB_DEBUG})
    endif()

    # Other dependencies.
    if(APPLE)
      find_library(ICONV_LIB iconv)

      if(ICONV_LIB)
        target_link_libraries(fbx::sdk INTERFACE ${ICONV_LIB})
        list(APPEND FBX_LIB ${ICONV_LIB})
        list(APPEND FBX_LIB_DEBUG ${ICONV_LIB})
      else()
        message(WARNING "FBX found but required iconv was not found!")
      endif()

      find_library(CARBON_FRAMEWORK Carbon)
      if(CARBON_FRAMEWORK)
        target_link_libraries(fbx::sdk INTERFACE ${CARBON_FRAMEWORK})
        list(APPEND FBX_LIB ${CARBON_FRAMEWORK})
        list(APPEND FBX_LIB_DEBUG ${CARBON_FRAMEWORK})
      else()
        message(WARNING "FBX found but required Carbon was not found!")
      endif()
    endif()

    if(UNIX)
      find_package(Threads)
      target_link_libraries(fbx::sdk INTERFACE ${CMAKE_THREAD_LIBS_INIT} dl)
      list(APPEND FBX_LIB ${CMAKE_THREAD_LIBS_INIT} dl)
      list(APPEND FBX_LIB_DEBUG ${CMAKE_THREAD_LIBS_INIT} dl)
    endif()

    set(${_OUT_FBX_LIBRARIES} ${FBX_LIB} PARENT_SCOPE)
    set(${_OUT_FBX_LIBRARIES_DEBUG} ${FBX_LIB_DEBUG} PARENT_SCOPE)

  else()
    message ("A Fbx SDK was found, but doesn't match your compiler settings.")
  endif()

endfunction()

###############################################################################
# Deduce Fbx sdk version
###############################################################################
function(FindFbxVersion _FBX_ROOT_DIR _OUT_FBX_VERSION)
  # Opens fbxsdk_version.h in _FBX_ROOT_DIR and finds version defines.

  set(fbx_version_filename "${_FBX_ROOT_DIR}include/fbxsdk/fbxsdk_version.h")

  if(NOT EXISTS ${fbx_version_filename})
    message(SEND_ERROR "Unable to find fbxsdk_version.h")
  endif()

  file(READ ${fbx_version_filename} fbx_version_file_content)

  # Find version major
  if(fbx_version_file_content MATCHES "FBXSDK_VERSION_MAJOR[\t ]+([0-9]+)")
    set(fbx_version_file_major "${CMAKE_MATCH_1}")
  endif()

  # Find version minor
  if(fbx_version_file_content MATCHES "FBXSDK_VERSION_MINOR[\t ]+([0-9]+)")
    set(fbx_version_file_minor "${CMAKE_MATCH_1}")
  endif()

  # Find version patch
  if(fbx_version_file_content MATCHES "FBXSDK_VERSION_POINT[\t ]+([0-9]+)")
    set(fbx_version_file_patch "${CMAKE_MATCH_1}")
  endif()

  if (DEFINED fbx_version_file_major AND
      DEFINED fbx_version_file_minor AND
      DEFINED fbx_version_file_patch)
    set(${_OUT_FBX_VERSION} ${fbx_version_file_major}.${fbx_version_file_minor}.${fbx_version_file_patch} PARENT_SCOPE)
  else()
    message(SEND_ERROR "Unable to deduce Fbx version for root dir ${_FBX_ROOT_DIR}")
    set(${_OUT_FBX_VERSION} "unknown" PARENT_SCOPE)
  endif()
endfunction()

###############################################################################
# Main find package function
###############################################################################

# Tries to find FBX SDK path
set(FBX_SEARCH_PATHS
  "${FBX_DIR}"
  "$ENV{FBX_DIR}"
  "$ENV{ProgramW6432}/Autodesk/FBX/FBX SDK/*/"
  "$ENV{PROGRAMFILES}/Autodesk/FBX/FBX SDK/*/"
  "/Applications/Autodesk/FBX SDK/*/")

find_path(FBX_INCLUDE_DIR 
  NAMES "include/fbxsdk.h"
  PATHS ${FBX_SEARCH_PATHS})

if(FBX_INCLUDE_DIR)
  # Deduce SDK root directory.
  set(FBX_ROOT_DIR "${FBX_INCLUDE_DIR}/")

  # Fills CMake standard variables
  set(FBX_INCLUDE_DIRS "${FBX_INCLUDE_DIR}/include")

  # Searches libraries according to the current compiler
  FindFbxLibrariesGeneric(${FBX_ROOT_DIR} FBX_LIBRARIES FBX_LIBRARIES_DEBUG FBX_SHARED_LIBRARIES FBX_SHARED_LIBRARIES_DEBUG)
endif()

# Handles find_package arguments and set FBX_FOUND to TRUE if all listed variables and version are valid.
include(FindPackageHandleStandardArgs)

find_package_handle_standard_args(Fbx
  FOUND_VAR FBX_FOUND
  REQUIRED_VARS FBX_LIBRARIES FBX_INCLUDE_DIRS
  VERSION_VAR PATH_VERSION)

# Warn about how this script can fail to find the newest version.
if(NOT FBX_FOUND)
  message("-- Note that the FindFbx.cmake script can fail to find the newest Fbx sdk if there are multiple ones installed. Please set \"FBX_DIR\" environment or cmake variable to choose a specific version/location.")
endif()