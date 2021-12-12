cmake_minimum_required(VERSION 3.0)

project(space2meta)

add_executable(space2meta space2meta.c)
target_compile_options(space2meta PRIVATE -Wall -Wextra)

install(TARGETS space2meta RUNTIME DESTINATION bin)
