# Установка

Клонируем конфиги

```
git clone git@github.com:senya/awesome.git ~/.config/awesome
git clone git@github.com:senya/alacritty-config.git ~/.config/alacritty
git clone git@github.com:senya/fish-config.git ~/.config/fish
git clone --branch my git@github.com:senya/kickstart.nvim.git ~/.config/nvim
```


awesome дополнительно ничего не требует, alacritty тоже.

Для fish ставим плагин-менеджер:

Идем в https://github.com/jorgebucaran/fisher?ysclid=mpwtmfsfrb902143511
и читаем как поставить.
Дальше этот fisher должен подтянуть то что в fish_plugins

# Заметки

"scratch" was originally taken by

```
git clone http://git.sysphere.org/awesome-configs ~/.config/awesome/awesome-configs
cp -r ~/.config/awesome/awesome-configs/scratch ~/.config/awesome
```

now it's removed from default branch of that repo, so,
I just copy it.

awesome-wm-widgets is copied from commmit 3bb3d56c26ac3500aab33381af0cccebf6aaa05c
https://github.com/streetturtle/awesome-wm-widgets.git
