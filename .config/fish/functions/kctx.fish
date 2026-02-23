function kctx --description "Switch Kubernetes context for PSF infrastructure clusters"
    set -l INFRA_DIR ~/git/internal/psf/kubernetes-infra

    # No args: list available clusters and current context
    if test (count $argv) -eq 0
        set -l current (kubectl config current-context 2>/dev/null; or echo "none")
        echo "Current context: $current"
        echo ""
        echo "Available clusters:"
        echo "  psf        - psf-cabotage.us-east-2 (kops)"
        echo "  pypi       - pypi-cabotage.us-east-2 (kops)"
        echo "  orbstack   - orbstack (local)"
        echo "  minikube   - minikube (local)"
        return 0
    end

    set -l cluster $argv[1]

    switch $cluster
        case psf psf-cabotage
            echo "Switching to psf-cabotage.us-east-2..."
            aws-profile psf-kops
            set -gx KUBERNETES_CLUSTER_TYPE kops
            set -gx KUBERNETES_CLUSTER_NAME psf-cabotage.us-east-2.k8s.local
            set -gx KUBERNETES_ENVIRONMENT psf
            set -gx KOPS_STATE_STORE s3://psf-kops-state
            set -gx KOPS_CLUSTER_NAME $KUBERNETES_CLUSTER_NAME
            set -gx KUBERNETES_CLUSTER_NICE_NAME psf-cabotage.us-east-2
            kops-132 export kubeconfig --admin
            kubectl config use-context $KUBERNETES_CLUSTER_NAME

        case pypi pypi-cabotage
            echo "Switching to pypi-cabotage.us-east-2..."
            aws-profile pypi-kops
            set -gx KUBERNETES_CLUSTER_TYPE kops
            set -gx KUBERNETES_CLUSTER_NAME pypi-cabotage.us-east-2.k8s.local
            set -gx KUBERNETES_ENVIRONMENT pypi
            set -gx KOPS_STATE_STORE s3://cabotage-psf-k8s-local-state-store
            set -gx KOPS_CLUSTER_NAME $KUBERNETES_CLUSTER_NAME
            set -gx KUBERNETES_CLUSTER_NICE_NAME pypi-cabotage.us-east-2
            kops-132 export kubeconfig --admin
            kubectl config use-context $KUBERNETES_CLUSTER_NAME

        case orbstack orb local
            echo "Switching to orbstack..."
            set -gx KUBERNETES_CLUSTER_TYPE orbstack
            set -gx KUBERNETES_CLUSTER_NAME orbstack
            set -gx KUBERNETES_CLUSTER_NICE_NAME orbstack
            # Clear kops vars if set
            set -e KOPS_STATE_STORE
            set -e KOPS_CLUSTER_NAME
            set -e KUBERNETES_ENVIRONMENT
            kubectl config use-context orbstack

        case minikube mk
            echo "Switching to minikube..."
            set -gx KUBERNETES_CLUSTER_TYPE minikube
            set -gx KUBERNETES_CLUSTER_NAME minikube
            set -gx KUBERNETES_CLUSTER_NICE_NAME minikube
            # Clear kops vars if set
            set -e KOPS_STATE_STORE
            set -e KOPS_CLUSTER_NAME
            set -e KUBERNETES_ENVIRONMENT
            kubectl config use-context minikube

        case '*'
            echo "Unknown cluster: $cluster"
            echo "Run 'kctx' with no args to see available clusters"
            return 1
    end
end

# Tab completions
complete -c kctx -f
complete -c kctx -n "not __fish_seen_subcommand_from psf pypi orbstack minikube" -a psf -d "psf-cabotage.us-east-2 (kops)"
complete -c kctx -n "not __fish_seen_subcommand_from psf pypi orbstack minikube" -a pypi -d "pypi-cabotage.us-east-2 (kops)"
complete -c kctx -n "not __fish_seen_subcommand_from psf pypi orbstack minikube" -a orbstack -d "orbstack (local)"
complete -c kctx -n "not __fish_seen_subcommand_from psf pypi orbstack minikube" -a minikube -d "minikube (local)"
