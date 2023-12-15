#!/bin/bash

sed -i 's/plugins=(git)/plugins=(git terraform)/' ~/.zshrc

echo "autoload -Uz compinit && compinit
complete -C '/usr/local/bin/aws_completer' aws" >> ~/.zshrc
