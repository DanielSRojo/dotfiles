# System
abbr -a l 'eza -l --icons'
abbr -a ll 'eza -l'
abbr -a la 'eza -la --icons'
abbr -a v nvim
abbr -a grn 'grep -rni'
abbr -a code codium
abbr -a curlhc 'curl -s -o /dev/null -I -w "%{http_code}"'
abbr -a clip wl-copy
abbr -a ls eza
abbr -a cat 'bat -p'
abbr -a cy 'bat --language=yaml'
abbr -a fvim 'fzf --print0 | xargs -0 -o vim'
abbr -a vim nvim

# Go
abbr -a gr 'go run .'

# Git
# abbr -a gd1 'git diff head~1'
# abbr -a gbv 'git branch -vv'
# abbr -a gstall 'git stash --all'
# abbr -a gswm 'git switch (__git.default_branch)'

# Jujutsu
abbr -a js 'jj st'
abbr -a jl 'jj log'
abbr -a jll 'jj log -r "all()" --limit 40'
abbr -a jls 'jj log --stat'
abbr -a jd 'jj diff'
abbr -a jds 'jj diff --stat'
abbr -a jsh 'jj show'
abbr -a jc 'jj commit'
abbr -a jcm 'jj commit -m'
abbr -a jde 'jj describe -m'
abbr -a jn 'jj new'
abbr -a je 'jj edit'
abbr -a jb 'jj bookmark list'
abbr -a jbm 'jj bookmark move'
abbr -a jt 'jj tug'
abbr -a jrb 'jj rebase'
abbr -a jf 'jj git fetch --all-remotes'
abbr -a jp 'jj git push'
abbr -a jsq 'jj squash'
abbr -a jab 'jj abandon'
abbr -a ju 'jj undo'
abbr -a jop 'jj op log'
abbr -a jd1 'jj diff --from @-'
abbr -a jdm 'jj diff --from "trunk()" --to @'
abbr -a jbv 'jj bookmark list --all-remotes'
abbr -a jswm 'jj new "trunk()"'
abbr -a jrbm 'jj rebase -b @ -d "trunk()"'

# Terraform
abbr -a tf terragrunt
abbr -a tfi 'terraform init'
abbr -a tfv 'terraform validate'
abbr -a tfp 'terraform plan'
abbr -a tfa 'terraform apply'
abbr -a tfr 'terraform refresh'
abbr -a tff 'terraform fmt'

# Kubernetes
abbr -a k kubectl
abbr -a ka 'kubectl get --all-namespaces'
abbr -a kg 'kubectl get pods --all-namespaces | grep'
abbr -a ks 'kubectl --namespace=kube-system'
abbr -a ke 'kubectl edit'
abbr -a kgp 'kubectl get pods'
abbr -a kgd 'kubectl get deployments --all-namespaces'
abbr -a kga 'kubectl get services,deployments,pods --all-namespaces'
abbr -a kgnr 'kubectl get pods -A | grep -Ev "Running|Completed"'
abbr -a ksdr1 'kubectl scale deployment --replicas=1 --all'
abbr -a kdebug 'kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh'
abbr -a kgno 'kubectl get nodes'
abbr -a kgnow 'kubectl get nodes -o wide'
abbr -a kgo 'kubectl get deployments.apps,svc,pods,cm,secrets'
abbr -a kgep 'kubectl get pod --all-namespaces --field-selector=status.phase==Failed'
abbr -a kdep 'kubectl delete pod --all-namespaces --field-selector=status.phase==Failed'
abbr -a ekc 'set -x KUBECONFIG ~/.kube/config.d/local'
abbr -a kcn 'kubectl config set-context --current --namespace'
abbr -a kgn 'kubectl get namespace'

# Docker
abbr -a drma 'docker rm -f (docker ps -a -q)'
abbr -a dcu 'docker compose up'
abbr -a dcud 'docker compose up --detach'
abbr -a dcd 'docker compose down'

# Nix
abbr -a rebuild 'sudo darwin-rebuild switch --flake ~/code/github.com/danielsrojo/nix#astrokube'
abbr -a update 'nix run ~/code/github.com/danielsrojo/nix#update'

# Custom
abbr -a todo 'todoer $HOME/.obsidian/ToDo.md && nvim $HOME/.obsidian/ToDo.md'
