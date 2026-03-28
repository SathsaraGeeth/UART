export DSIM_LICENSE=$HOME/metrics-ca/dsim-license.json
export PYGPI_PYTHON_BIN=$(which python)

rm -rf build
cmake -S . -B build
cmake --build build --target dsim_build
cmake --build build --target dsim_run


