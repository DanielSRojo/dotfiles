# Port of fish/conf.d/abbr.fish. Expansions are plain strings that reedline
# substitutes on space or enter, so what runs and what history records is the
# expanded command -- same contract as fish's `abbr -a`.
#
# Merged rather than assigned so a per-machine autoload/*work*.nu can add its
# own regardless of which file nushell sources first.

# Copy stdin to the clipboard: pbcopy on macOS, wl-copy under Wayland. Bound
# out here and spread in below because a record literal takes no conditionals.
let clipboard = if (which pbcopy | is-not-empty) {
    {clip: "pbcopy"}
} else if (which wl-copy | is-not-empty) {
    {clip: "wl-copy"}
} else {
    {}
}

$env.config.abbreviations = ($env.config.abbreviations | merge {
    # System
    l: "eza -l --icons"
    ll: "eza -l"
    la: "eza -la --icons"
    lt: "eza -aT --icons --group-directories-first"
    "l.": r#'eza -a | grep -e '^\.''#
    v: "nvim"
    grn: "grep -rni"
    curlhc: 'curl -s -o /dev/null -I -w "%{http_code}"'
    # `ls` is a nushell builtin returning a table, and abbreviations expand
    # after a pipe too, so aliasing it away would break structured pipelines.
    # ls: "eza"
    cat: "bat -p"
    cy: "bat --language=yaml"
    fvim: "fzf --print0 | xargs -0 -o vim"
    ...$clipboard

    grep: "grep --color=auto"
    fgrep: "fgrep --color=auto"
    egrep: "egrep --color=auto"
    untar: "tar -zxvf"
    wget: "wget -c"
    "..": "cd .."

    # Go
    gr: "go run ."

    # Jujutsu
    j: "jj"
    js: "jj st"
    jl: "jj log"
    jll: 'jj log -r "all()" --limit 40'
    jls: "jj log --stat"
    jd: "jj diff"
    jds: "jj diff --stat"
    jdn: "jj diff --name-only"
    jsh: "jj show"
    jc: "jj commit"
    jcm: "jj commit -m"
    jde: "jj describe -m"
    jn: "jj new"
    je: "jj edit"
    jb: "jj bookmark"
    jbl: "jj bookmark list"
    jbm: "jj bookmark move"
    jt: "jj tug"
    jrb: "jj rebase"
    jf: "jj git fetch --all-remotes"
    jp: "jj git push"
    jsq: "jj squash"
    jab: "jj abandon"
    ju: "jj undo"
    jop: "jj op log"
    jd1: "jj diff --from @-"
    jdm: 'jj diff --from "trunk()" --to @'
    jbv: "jj bookmark list --all-remotes"
    jswm: 'jj new "trunk()"'
    jrbm: 'jj rebase -b @ -d "trunk()"'

    # Terraform
    tf: "terragrunt"
    tfi: "terragrunt init"
    tfv: "terragrunt validate"
    tfp: "terragrunt plan"
    tfa: "terragrunt apply"
    tfr: "terragrunt refresh"
    tff: "terragrunt fmt"

    # Kubernetes
    k: "kubectl"
    ka: "kubectl get --all-namespaces"
    kg: "kubectl get pods --all-namespaces | grep"
    ks: "kubectl --namespace=kube-system"
    ke: "kubectl edit"
    kgp: "kubectl get pods"
    kgd: "kubectl get deployments --all-namespaces"
    kga: "kubectl get services,deployments,pods --all-namespaces"
    kgnr: 'kubectl get pods -A | grep -Ev "Running|Completed"'
    ksdr1: "kubectl scale deployment --replicas=1 --all"
    kdebug: "kubectl run -i --tty --rm debug --image=busybox --restart=Never -- sh"
    kgno: "kubectl get nodes"
    kgnow: "kubectl get nodes -o wide"
    kgo: "kubectl get deployments.apps,svc,pods,cm,secrets"
    kgep: "kubectl get pod --all-namespaces --field-selector=status.phase==Failed"
    kdep: "kubectl delete pod --all-namespaces --field-selector=status.phase==Failed"
    # `set -x` has no nushell equivalent; assigning $env directly is the port.
    ekc: '$env.KUBECONFIG = ("~/.kube/config.d/local" | path expand)'
    kcn: "kubectl config set-context --current --namespace"
    kgn: "kubectl get namespace"
})
