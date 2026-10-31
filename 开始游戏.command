#!/bin/zsh
cd -- "${0:A:h}"
for orange_engine in "$HOME/Downloads/Godot.app/Contents/MacOS/Godot" "/Applications/Godot.app/Contents/MacOS/Godot"; do
  if [[ -x "$orange_engine" ]]; then
    exec "$orange_engine" --path "$PWD"
  fi
done
if command -v godot >/dev/null 2>&1; then
  exec godot --path "$PWD"
fi
printf '请先安装 Godot 4.3 或更新版本，然后打开本文件夹中的 project.godot，按 F6 或 F5 运行。\n'
read -k 1 '?按任意键关闭…'
