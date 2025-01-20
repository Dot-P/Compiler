import streamlit as st

# スタック操作をシミュレートするクラス
class AssemblySimulator:
    def __init__(self):
        self.stack = [None] * 20  # スタックを20領域で初期化
        self.stack_pointer = 0  # スタックポインタ (最初は一番下)
        self.instructions = []  # アセンブリ命令
        self.current_line = 0  # 現在の実行行
        self.highlight_sp = False  # SPを目立たせるフラグ
        self.is_program_finished = False  # プログラム終了フラグ

    def load_instructions(self, content):
        """アセンブリコードを読み込む"""
        self.instructions = [line.strip() for line in content.splitlines() if line.strip()]

    def reset(self):
        """シミュレーションをリセット"""
        self.stack = [None] * 20  # スタックの初期化 (空の20領域を持つ)
        self.stack_pointer = 0  # スタックポインタを一番下に設定
        self.current_line = 0
        self.highlight_sp = False
        self.is_program_finished = False  # プログラム終了フラグをリセット

    def execute_next(self):
        """次の命令を1ステップ実行"""
        if self.is_program_finished:
            return False  # プログラムが終了している場合、何もしない

        while self.current_line < len(self.instructions):
            line = self.instructions[self.current_line]
            self.current_line += 1

            # 命令の解析
            parts = line.strip("()").split(", ")
            if len(parts) < 3:
                return True  # 不完全な行はスキップ

            opcode = parts[0].strip()
            argument = int(parts[2].strip()) if len(parts) > 2 else 0

            # デフォルトでSPの強調をリセット
            self.highlight_sp = False

            # 命令の実行
            if opcode == "LIT":  # LIT: SPを上げて値を配置
                self.stack_pointer += 1
                if self.stack_pointer >= len(self.stack):
                    self.stack.append(None)  # 必要ならスタックを拡張
                self.stack[self.stack_pointer] = argument
                break
            elif opcode == "STO":  # STO: SPの値を指定された位置に配置 (SPは移動しない)
                target_position = argument
                self.stack[target_position] = self.stack[self.stack_pointer]
                break
            elif opcode == "LOD":  # LOD: 指定されたスタック位置の値をSPの位置に格納
                self.stack[self.stack_pointer] = self.stack[argument]
                break
            elif opcode == "OPR":  # OPR: 操作（加算、減算、比較など）
                if argument == 0:  # OPR, 0, 0 はプログラムの終了
                    self.is_program_finished = True
                    return False
                self.execute_operation(argument)
                break
            elif opcode == "INT":  # INT: スタックポインタを移動
                self.adjust_stack_pointer(argument)
                break
            elif opcode == "CSP":  # CSP: 特殊命令
                if argument == 1:
                    self.highlight_sp = True
                elif argument == 2:  # CSP, 0, 2 はスルー
                    continue
                break
            elif opcode == "JMP":  # JMP: 指定されたLABまでジャンプ
                self.jump_to_label(argument)
                continue  # ジャンプ後に即座に次の命令を処理
            elif opcode == "JPC":  # JPC: 条件付きジャンプ
                if self.stack[self.stack_pointer] == 0:  # SPの値が0ならジャンプ
                    self.stack[self.stack_pointer] = None  # SPの値を消費 (None に設定)
                    self.jump_to_label(argument)
                    continue  # ジャンプ後に即座に次の命令を処理
                else:  # 0でない場合はSPの値をNoneにし、次の命令へ
                    self.stack[self.stack_pointer] = None
                break
            return True

    def execute_operation(self, operation):
        """スタック上の演算を実行"""
        if self.stack_pointer < 1:
            raise ValueError("Not enough values on the stack for operation.")

        b = self.stack[self.stack_pointer]
        a = self.stack[self.stack_pointer - 1]
        self.stack[self.stack_pointer] = None  # SPの値を消費
        self.stack_pointer -= 1

        if operation == 2:  # ADD
            self.stack[self.stack_pointer] = a + b
        elif operation == 3:  # SUB
            self.stack[self.stack_pointer] = a - b
        elif operation == 4:  # MUL
            self.stack[self.stack_pointer] = a * b
        elif operation == 5:  # DIV
            self.stack[self.stack_pointer] = a // b
        elif operation == 6:  # ODD
            self.stack[self.stack_pointer+1] = a % 2
        elif operation == 7:  # POW
            self.stack[self.stack_pointer] = a ** b
        elif operation == 8:  # EQ
            self.stack[self.stack_pointer] = 1 if a == b else 0
        elif operation == 9:  # NEQ
            self.stack[self.stack_pointer] = 1 if a != b else 0
        elif operation == 10:  # LT (<)
            self.stack[self.stack_pointer] = 1 if a < b else 0
        elif operation == 11:  # GE (>=)
            self.stack[self.stack_pointer] = 1 if a >= b else 0
        elif operation == 12:  # GT (>)
            self.stack[self.stack_pointer] = 1 if a > b else 0
        elif operation == 13:  # LE (<=)
            self.stack[self.stack_pointer] = 1 if a <= b else 0
        else:
            raise ValueError(f"Unsupported operation code: {operation}")

    def adjust_stack_pointer(self, amount):
        """INT命令の処理: スタックポインタの移動"""
        self.stack_pointer += amount
        if self.stack_pointer > len(self.stack):
            self.stack.extend([None] * (self.stack_pointer - len(self.stack)))

    def jump_to_label(self, label_number):
        """指定されたLAB番号までジャンプする"""
        for i, instruction in enumerate(self.instructions):
            parts = instruction.strip("()").split(", ")
            if parts[0].strip() == "LAB" and int(parts[2].strip()) == label_number:
                self.current_line = i
                return
        raise ValueError(f"LAB {label_number} not found")

# Streamlit アプリ
def main():
    st.title("Assembly Stack Visualizer")

    # ファイルアップロード
    uploaded_file = st.file_uploader("Upload Assembly File (.output)", type="output")
    if not uploaded_file:
        st.warning("Please upload a valid .output file to continue.")
        return

    # アセンブリファイルの読み込み
    content = uploaded_file.read().decode("utf-8")
    if "simulator" not in st.session_state:
        st.session_state.simulator = AssemblySimulator()
        st.session_state.simulator.load_instructions(content)
        st.session_state.simulator.reset()

    simulator = st.session_state.simulator

    # ボタンで制御
    col1, col2 = st.columns(2)
    with col1:
        next_step_disabled = simulator.is_program_finished  # プログラム終了時はボタンを無効化
        if st.button("Next Step", disabled=next_step_disabled):
            simulator.execute_next()
    with col2:
        if st.button("Reset"):
            simulator.reset()

    # レイアウト
    col1, col2 = st.columns(2)

    # 左: アセンブリコード
    with col1:
        st.subheader("Assembly Code")
        for i, line in enumerate(simulator.instructions):
            if i == simulator.current_line - 1:  # 実行中の行を赤色で表示
                st.markdown(f"<p style='color:red; margin:0;'>{line}</p>", unsafe_allow_html=True)
            else:
                st.markdown(f"<p style='margin:0;'>{line}</p>", unsafe_allow_html=True)

    # 右: スタック
    with col2:
        st.subheader("Stack")
        stack_display = simulator.stack

        # スタックの視覚化
        for i in range(len(stack_display) - 1, -1, -1):
            value = stack_display[i]
            if i == simulator.stack_pointer:  # スタックポインタの位置を表示
                if simulator.highlight_sp:  # SPを目立たせる
                    st.markdown(
                        f"<div style='border: 2px solid black; background-color: yellow; color: black; text-align: center; font-weight: bold;'>{value}</div>",
                        unsafe_allow_html=True,
                    )
                else:
                    st.markdown(
                        f"<div style='border: 1px solid black; background-color: blue; color: white; text-align: center;'>{value}</div>",
                        unsafe_allow_html=True,
                    )
            else:
                st.markdown(
                    f"<div style='border: 1px solid black; text-align: center;'>{value}</div>",
                    unsafe_allow_html=True,
                )

if __name__ == "__main__":
    main()
