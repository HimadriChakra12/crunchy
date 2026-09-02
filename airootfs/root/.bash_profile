sudo pacman -Sy firefox ttf-jetbrains-mono-nerd --noconfirm
[ -d /root/.config/nvim ] || git clone https://github.com/HimadriChakra12/himstart.nvim /root/.config/nvim

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
  exec startx
fi
