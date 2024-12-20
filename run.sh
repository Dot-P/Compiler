#!/bin/bash

# エラーが発生したらスクリプトを終了する
set -e

# 1. cmmを実行してmain.cを解析
echo "Running ./cmm < main.c"
output=$(./cmm < main.c 2>&1)  # 標準エラーもキャプチャ

# "error: syntax error" をチェック
if echo "$output" | grep -q "error"; then
    echo "Error detected in cmm!!"
    echo "OUTPUT:"
    echo "$output"
    exit 1
fi

# 2. pl0iを実行
echo "Running ../pl0i_src/pl0i code.output"
../pl0i_src/pl0i code.output

# 正常終了
echo "Script executed successfully."
