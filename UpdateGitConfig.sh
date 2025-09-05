#!/bin/bash

echo "Login into GitHub using github-cli?"
read -p "[y]es / [n]o: " ans
if [[ "$ans" =~ ^[Yy]$ ]]; then
    gh auth login
fi

cat <<'catEND' >> ~/.gitconfig
[alias]
	ac = !git add --all && git commit -m
	ch = !git checkout
	chb = !git checkout -b
	ba = !git branch -vva
	bu = !git branch -u
	bd = !git branch -d
	st = !git status -s
	logs = !git log --pretty=format:'%C(red)%h %C(yellow)%cn | %C(yellow)%cd (%cr) %C(reset)%C(white)%s' --date=format:'%a %Y/%m/%d %H:%M:%S'
catEND
