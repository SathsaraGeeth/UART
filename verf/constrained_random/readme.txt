rm -rf build
cmake -S . -B build
cmake --build build --target dsim_build
cmake --build build --target dsim_run