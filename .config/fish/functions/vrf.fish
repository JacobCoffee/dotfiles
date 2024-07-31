# Oneshot to forcefully destroy a Vagrant host and then recreate it

function vrf
    vagrant destroy -f $argv[1]
    vagrant up $argv[1]
end
