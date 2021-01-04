find_program(GETTEXT_MSGFMT_EXECUTABLE msgfmt)

if(NOT GETTEXT_MSGFMT_EXECUTABLE)
  message("------
                 NOTE: msgfmt not found. Translations will *not* be installed
------"
  )
else(NOT GETTEXT_MSGFMT_EXECUTABLE)

  set(catalogname plasma_applet_org.kde.plasma.qalculate)

  file(GLOB PO_FILES po/*.po)
  set(GMO_FILES)

  add_custom_target(translations ALL DEPENDS ${GMO_FILES})

  foreach(_poFile ${PO_FILES})
    get_filename_component(_poFileName ${_poFile} NAME)
    string(REGEX REPLACE "^${catalogname}_?" "" _langCode ${_poFileName})
    string(REGEX REPLACE "\\.po$" "" _langCode ${_langCode})

    if(_langCode)
      # GET_FILENAME_COMPONENT(_lang ${_poFile} NAME_WE)
      string(REGEX REPLACE "\\.po$" "" _lang ${_poFileName})
      set(_gmoFile ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.gmo)

      add_custom_command(
        TARGET translations
        COMMAND
          ${GETTEXT_MSGFMT_EXECUTABLE} --check -o ${_gmoFile} ${_poFile}
          DEPENDS ${_poFile}
      )
      install(
        FILES ${_gmoFile}
        DESTINATION ${LOCALE_INSTALL_DIR}/${_langCode}/LC_MESSAGES/
        RENAME ${catalogname}.mo
      )
      list(APPEND GMO_FILES ${_gmoFile})
    endif(_langCode)

  endforeach(_poFile ${PO_FILES})

endif(NOT GETTEXT_MSGFMT_EXECUTABLE)
