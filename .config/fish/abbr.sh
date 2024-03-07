# System 
abbr -a l 'eza -l --icons'
abbr -a ll 'eza -l'
abbr -a la 'eza -la --icons'
abbr -a v 'nvim'

# Go
abbr -a gr 'go run .'

# Git
abbr -a gd1 'git diff HEAD~1'
abbr -a gbv 'git branch -vv'
abbr -a gstall 'git stash --all'

# Terraform
abbr -a tf 'terraform'
abbr -a tfi 'terraform init'
abbr -a tfv 'terraform validate'
abbr -a tfp 'terraform plan'
abbr -a tfa 'terraform apply'
abbr -a tfr 'terraform refresh'
abbr -a tff 'terraform fmt'

# Kubernetes
abbr -a k 'kubectl'
abbr -a ekc 'export KUBECONFIG=~/.kube/config'
abbr -a ka 'kubectl get --all-namespaces'
abbr -a kg 'kubectl get pods --all-namespaces | grep'
abbr -a ks 'kubectl --namespace=kube-system'
abbr -a ke 'kubectl edit'
abbr -a kgp 'kubectl get pods'
abbr -a kgd 'kubectl get deployments --all-namespaces'
abbr -a kga 'kubectl get services,deployments,pods --all-namespaces'
abbr -a kgnr 'kubectl get pods -A | grep -v Running'
abbr -a ksdr1 'kubectl scale deployment --replicas=1 --all'
abbr -a kdebug 'kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh'
abbr -a kgno 'kubectl get nodes'
abbr -a kgnow 'kubectl get nodes -o wide'
abbr -a kgo 'kubectl get deployments.apps,svc,pods,cm,secrets'
abbr -a kgep 'kubectl get pod --all-namespaces --field-selector=status.phase==Failed'
abbr -a kdep 'kubectl delete pod --all-namespaces --field-selector=status.phase==Failed'
abbr -a ekc 'set -x KUBECONFIG ~/.kube/config'
abbr -a kcn 'kubectl config set-context --current --namespace'
abbr -a kgn 'kubectl get namespace'


# Docker
abbr -a drma 'docker rm -f (docker ps -a -q)'
abbr -a dcu 'docker compose up'
abbr -a dcud 'docker compose up --detach'
abbr -a dcd 'docker compose down'

# Openstack
abbr -a os 'openstack'

