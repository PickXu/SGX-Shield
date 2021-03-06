#!/usr/bin/env bash
#
# Copyright (C) 2011-2016 Intel Corporation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
#   * Redistributions of source code must retain the above copyright
#     notice, this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in
#     the documentation and/or other materials provided with the
#     distribution.
#   * Neither the name of Intel Corporation nor the names of its
#     contributors may be used to endorse or promote products derived
#     from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#


set -e 

SCRIPT_DIR=$(dirname "$0")
source ${SCRIPT_DIR}/installConfig

# Generate the script to preload SGX ptrace library for gdb
SDK_DST_PATH=${SGX_PACKAGES_PATH}/${SDK_PKG_NAME}
GDB_SCRIPT=/usr/bin/sgx-gdb
SDK_LIB_PATH=${SDK_DST_PATH}/${LIB_DIR}

generate_gdb_script()
{
    cat > $GDB_SCRIPT <<EOF
#!/usr/bin/env bash
#
#  Copyright (c) 2011-2015, Intel Corporation.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License

shopt -s expand_aliases

GDB_SGX_PLUGIN_PATH=$SDK_LIB_PATH/gdb-sgx-plugin
SGX_LIBRARY_PATH=$SDK_LIB_PATH
export PYTHONPATH=\$GDB_SGX_PLUGIN_PATH
LD_PRELOAD=\$SGX_LIBRARY_PATH/libsgx_ptrace.so /usr/bin/gdb -iex "directory \$GDB_SGX_PLUGIN_PATH" -iex "source \$GDB_SGX_PLUGIN_PATH/gdb_sgx_plugin.py" -iex "set environment LD_PRELOAD" "\$@"
EOF

    chmod +x $GDB_SCRIPT
}

generate_gdb_script


cat > $SDK_DST_PATH/uninstall.sh <<EOF
#!/usr/bin/env bash

if test \$(id -u) -ne 0; then
    echo "Root privilege is required."
    exit 1
fi

# Removing the simulation runtime libraries
rm -f /usr/lib/libsgx_uae_service_sim.so
rm -f /usr/lib/libsgx_urts_sim.so

# Removing sgx-gdb script
rm -f $GDB_SCRIPT

# Removing the SDK folder
rm -fr $SDK_DST_PATH

EOF

chmod +x $SDK_DST_PATH/uninstall.sh

echo -e "uninstall.sh script generated in $SDK_DST_PATH\n"
echo -e "Installation successful! The SDK package can be found in $SDK_DST_PATH"

rm -fr $SDK_DST_PATH/scripts

exit 0

