@echo off
git init
git add .
git commit -m "Initial commit of customized LeftValues project with new ideologies"
git branch -M main
git remote add origin https://github.com/thermonuklear/literate-couscous.git
git push -u origin main
