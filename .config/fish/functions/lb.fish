function connect_and_open
    set target $argv[1]
    set is_dev $argv[2]
    echo "Connecting to $target"
    
    lbk

    if test "$is_dev" = "true"
        set ssh_command "vagrant ssh-config loadbalancer > vagrant-ssh && ssh -F vagrant-ssh -L 4646:127.0.0.1:4646 vagrant@loadbalancer"
    else
        set ssh_command "ssh -L 4646:127.0.0.1:4646 $target.nyc1.psf.io"
    end
    
    eval "$ssh_command -N &"

    sleep 2 
    open "http://localhost:4646/haproxy?stats"
    
    wait
end

function lb
    if ssh -q -o ConnectTimeout=5 lb-a.nyc1.psf.io exit
        connect_and_open "lb-a" false
    else if ssh -q -o ConnectTimeout=5 lb-b.nyc1.psf.io exit
        connect_and_open "lb-b" false
    else
        echo "Neither lb-a nor lb-b is available."
        return 1
    end
end

function lba
    connect_and_open "lb-a" false
end

function lbb
    connect_and_open "lb-b" false
end

function lbd
    if not test -f vagrant-ssh
        echo "vagrant-ssh config not found. Creating it..."
        vagrant ssh-config loadbalancer > vagrant-ssh
    end
    
    connect_and_open "loadbalancer" true
end

function lbk
    echo "Terminating all load balancer SSH connections..."
    set killed (pkill -f "ssh -L 4646:127.0.0.1:4646")
    if test $status -eq 0
        echo "Successfully terminated" $killed "SSH connection(s)."
    else
        echo "No active load balancer SSH connections found."
    end
end
