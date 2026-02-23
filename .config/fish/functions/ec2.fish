# EC2 usage reports for PSF/PyPI kops clusters

set -g __ec2_clusters \
    "psf:psf-kops:psf-cabotage.us-east-2.k8s.local" \
    "pypi:pypi-kops:pypi-cabotage.us-east-2.k8s.local"

function ec2 -d "EC2 usage reports for PSF infrastructure"
    set -l subcmd $argv[1]
    set -l region "us-east-2"

    switch "$subcmd"
        case summary ""
            __ec2_summary $region
        case list ls
            __ec2_list $region $argv[2]
        case json
            __ec2_json $region $argv[2]
        case cost costs
            __ec2_cost $region
        case help -h --help
            echo "Usage: ec2 <command> [cluster]"
            echo ""
            echo "Commands:"
            echo "  summary       Overview of all clusters (default)"
            echo "  list [name]   Detailed instance list (psf|pypi|all)"
            echo "  json [name]   JSON output (psf|pypi|all)"
            echo "  cost          Estimated monthly costs"
            echo "  help          Show this help"
            echo ""
            echo "Examples:"
            echo "  ec2              Show summary of all clusters"
            echo "  ec2 list psf     List PSF cluster instances"
            echo "  ec2 json pypi    PyPI cluster as JSON"
            echo "  ec2 cost         Monthly cost breakdown"
        case '*'
            echo "Unknown command: $subcmd"
            echo "Run 'ec2 help' for usage"
            return 1
    end
end

function __ec2_fetch -d "Fetch instances for a cluster"
    set -l region $argv[1]
    set -l profile $argv[2]
    set -l cluster $argv[3]

    aws ec2 describe-instances --region $region --profile $profile \
        --filters "Name=tag:KubernetesCluster,Values=$cluster" "Name=instance-state-name,Values=running" \
        --query 'Reservations[].Instances[].[InstanceId,InstanceType,PrivateIpAddress,State.Name,LaunchTime,Tags[?Key==`Name`].Value|[0],Placement.AvailabilityZone,CpuOptions.CoreCount,CpuOptions.ThreadsPerCore]' \
        --output json 2>/dev/null
end

function __ec2_summary -d "Show cluster summary"
    set -l region $argv[1]

    echo ""
    echo "PSF Infrastructure — EC2 Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    set -l grand_instances 0
    set -l grand_vcpu 0
    set -l grand_ram 0

    for entry in $__ec2_clusters
        set -l parts (string split ":" $entry)
        set -l name $parts[1]
        set -l profile $parts[2]
        set -l cluster $parts[3]

        set -l data (__ec2_fetch $region $profile $cluster)
        if test -z "$data" -o "$data" = "[]"
            echo "  $name: unable to fetch (check credentials)"
            continue
        end

        set -l masters (echo $data | python3 -c "
import sys, json
data = json.load(sys.stdin)
masters = [i for i in data if 'master' in (i[5] or '') or 'control-plane' in (i[5] or '')]
print(len(masters))
")
        set -l workers (echo $data | python3 -c "
import sys, json
data = json.load(sys.stdin)
workers = [i for i in data if 'node' in (i[5] or '') and 'master' not in (i[5] or '') and 'control-plane' not in (i[5] or '')]
print(len(workers))
")
        set -l total (echo $data | python3 -c "
import sys, json
print(len(json.load(sys.stdin)))
")
        set -l types (echo $data | python3 -c "
import sys, json
from collections import Counter
data = json.load(sys.stdin)
counts = Counter(i[1] for i in data)
parts = []
for t, c in sorted(counts.items()):
    parts.append(f'{c}x {t}')
print(', '.join(parts))
")
        set -l resources (echo $data | python3 -c "
import sys, json
data = json.load(sys.stdin)
vcpu_map = {
    'c8g.xlarge': 4, 'c7g.xlarge': 4, 'c6g.xlarge': 4,
    'm8g.2xlarge': 8, 'm7g.2xlarge': 8, 'm6g.2xlarge': 8,
    'm8g.xlarge': 4, 'm7g.xlarge': 4,
    't3.large': 2, 't3.xlarge': 4, 't3.medium': 2,
}
ram_map = {
    'c8g.xlarge': 8, 'c7g.xlarge': 8, 'c6g.xlarge': 8,
    'm8g.2xlarge': 32, 'm7g.2xlarge': 32, 'm6g.2xlarge': 32,
    'm8g.xlarge': 16, 'm7g.xlarge': 16,
    't3.large': 8, 't3.xlarge': 16, 't3.medium': 4,
}
total_vcpu = sum(vcpu_map.get(i[1], 0) for i in data)
total_ram = sum(ram_map.get(i[1], 0) for i in data)
print(f'{total_vcpu},{total_ram}')
")
        set -l vcpu (string split "," $resources)[1]
        set -l ram (string split "," $resources)[2]

        set -l az_dist (echo $data | python3 -c "
import sys, json
from collections import Counter
data = json.load(sys.stdin)
counts = Counter(i[6][-1] for i in data)
parts = []
for az in sorted(counts.keys()):
    parts.append(f'{az}:{counts[az]}')
print(' '.join(parts))
")

        set grand_instances (math $grand_instances + $total)
        set grand_vcpu (math $grand_vcpu + $vcpu)
        set grand_ram (math $grand_ram + $ram)

        echo "  ┌─ $name ($cluster)"
        echo "  │  Instances:  $total ($masters control plane, $workers workers)"
        echo "  │  Types:      $types"
        echo "  │  Compute:    $vcpu vCPU, $ram GiB RAM"
        echo "  │  AZ spread:  $az_dist"
        echo "  └"
        echo ""
    end

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Total: $grand_instances instances, $grand_vcpu vCPU, $grand_ram GiB RAM"
    echo ""
end

function __ec2_list -d "Show detailed instance list"
    set -l region $argv[1]
    set -l filter $argv[2]
    if test -z "$filter"
        set filter "all"
    end

    for entry in $__ec2_clusters
        set -l parts (string split ":" $entry)
        set -l name $parts[1]
        set -l profile $parts[2]
        set -l cluster $parts[3]

        if test "$filter" != "all" -a "$filter" != "$name"
            continue
        end

        echo ""
        echo "$name ($cluster)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        set -l data (__ec2_fetch $region $profile $cluster)
        if test -z "$data" -o "$data" = "[]"
            echo "  Unable to fetch (check credentials)"
            continue
        end

        echo $data | python3 -c "
import sys, json
from datetime import datetime, timezone

vcpu_map = {
    'c8g.xlarge': 4, 'c7g.xlarge': 4, 'c6g.xlarge': 4,
    'm8g.2xlarge': 8, 'm7g.2xlarge': 8, 'm6g.2xlarge': 8,
    'm8g.xlarge': 4, 'm7g.xlarge': 4,
    't3.large': 2, 't3.xlarge': 4, 't3.medium': 2,
}
ram_map = {
    'c8g.xlarge': 8, 'c7g.xlarge': 8, 'c6g.xlarge': 8,
    'm8g.2xlarge': 32, 'm7g.2xlarge': 32, 'm6g.2xlarge': 32,
    'm8g.xlarge': 16, 'm7g.xlarge': 16,
    't3.large': 8, 't3.xlarge': 16, 't3.medium': 4,
}

data = json.load(sys.stdin)
now = datetime.now(timezone.utc)

# Sort: control plane first, then by AZ
def sort_key(i):
    is_cp = 1 if ('control-plane' in (i[5] or '') or 'master' in (i[5] or '')) else 2
    return (is_cp, i[6] or '', i[5] or '')

data.sort(key=sort_key)

print(f'  {\"Role\":<15} {\"Type\":<14} {\"vCPU\":>4} {\"RAM\":>6} {\"AZ\":>4} {\"IP\":<16} {\"Uptime\":<12} {\"Instance ID\"}')
print(f'  {\"─\"*15} {\"─\"*14} {\"─\"*4} {\"─\"*6} {\"─\"*4} {\"─\"*16} {\"─\"*12} {\"─\"*21}')

for i in data:
    iid, itype, ip, state, launch, name, az = i[0], i[1], i[2], i[3], i[4], i[5] or '', i[6] or ''
    role = 'control-plane' if ('control-plane' in name or 'master' in name) else 'worker'
    vcpu = vcpu_map.get(itype, '?')
    ram = f'{ram_map.get(itype, \"?\")} GiB'
    az_short = az[-1] if az else '?'
    launched = datetime.fromisoformat(launch.replace('+00:00', '+00:00'))
    days = (now - launched).days
    if days > 365:
        uptime = f'{days // 365}y {days % 365}d'
    elif days > 0:
        uptime = f'{days}d'
    else:
        uptime = '<1d'
    print(f'  {role:<15} {itype:<14} {vcpu:>4} {ram:>6} {az_short:>4} {ip:<16} {uptime:<12} {iid}')
"
        echo ""
    end
end

function __ec2_json -d "Output instances as JSON"
    set -l region $argv[1]
    set -l filter $argv[2]
    if test -z "$filter"
        set filter "all"
    end

    set -l first true

    echo "{"
    for entry in $__ec2_clusters
        set -l parts (string split ":" $entry)
        set -l name $parts[1]
        set -l profile $parts[2]
        set -l cluster $parts[3]

        if test "$filter" != "all" -a "$filter" != "$name"
            continue
        end

        set -l data (__ec2_fetch $region $profile $cluster)
        if test -z "$data" -o "$data" = "[]"
            set data "[]"
        end

        if test "$first" = true
            set first false
        else
            echo ","
        end

        echo $data | python3 -c "
import sys, json
name = '$name'
cluster = '$cluster'
data = json.load(sys.stdin)

vcpu_map = {
    'c8g.xlarge': 4, 'c7g.xlarge': 4, 'c6g.xlarge': 4,
    'm8g.2xlarge': 8, 'm7g.2xlarge': 8, 'm6g.2xlarge': 8,
    'm8g.xlarge': 4, 'm7g.xlarge': 4,
    't3.large': 2, 't3.xlarge': 4, 't3.medium': 2,
}
ram_map = {
    'c8g.xlarge': 8, 'c7g.xlarge': 8, 'c6g.xlarge': 8,
    'm8g.2xlarge': 32, 'm7g.2xlarge': 32, 'm6g.2xlarge': 32,
    'm8g.xlarge': 16, 'm7g.xlarge': 16,
    't3.large': 8, 't3.xlarge': 16, 't3.medium': 4,
}
hourly_map = {
    'c8g.xlarge': 0.115, 'c7g.xlarge': 0.109, 'c6g.xlarge': 0.102,
    'm8g.2xlarge': 0.274, 'm7g.2xlarge': 0.259, 'm6g.2xlarge': 0.231,
    'm8g.xlarge': 0.137, 'm7g.xlarge': 0.130,
    't3.large': 0.083, 't3.xlarge': 0.166, 't3.medium': 0.042,
}

instances = []
for i in data:
    iid, itype, ip, state, launch, iname, az = i[0], i[1], i[2], i[3], i[4], i[5] or '', i[6] or ''
    role = 'control-plane' if ('control-plane' in iname or 'master' in iname) else 'worker'
    instances.append({
        'instance_id': iid,
        'type': itype,
        'role': role,
        'vcpu': vcpu_map.get(itype, 0),
        'ram_gib': ram_map.get(itype, 0),
        'ip': ip,
        'az': az,
        'launched': launch,
        'hourly_cost_usd': hourly_map.get(itype, 0),
        'monthly_cost_usd': round(hourly_map.get(itype, 0) * 730, 2),
    })

total_vcpu = sum(i['vcpu'] for i in instances)
total_ram = sum(i['ram_gib'] for i in instances)
total_monthly = round(sum(i['monthly_cost_usd'] for i in instances), 2)

output = {
    'cluster': cluster,
    'total_instances': len(instances),
    'total_vcpu': total_vcpu,
    'total_ram_gib': total_ram,
    'estimated_monthly_usd': total_monthly,
    'instances': instances,
}
print(f'  \"{name}\": ', end='')
print(json.dumps(output, indent=4).replace(chr(10), chr(10) + '  '))
" 2>/dev/null
    end
    echo "}"
end

function __ec2_cost -d "Show cost breakdown"
    set -l region $argv[1]
    set -l tmpfile (mktemp)

    echo ""
    echo "PSF Infrastructure — Estimated Monthly Costs (On-Demand)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Collect all cluster data, then let python do all formatting
    set -l all_json "{"
    set -l first true

    for entry in $__ec2_clusters
        set -l parts (string split ":" $entry)
        set -l name $parts[1]
        set -l profile $parts[2]
        set -l cluster $parts[3]

        set -l data (__ec2_fetch $region $profile $cluster)
        if test -z "$data" -o "$data" = "[]"
            set data "[]"
        end

        if test "$first" = true
            set first false
        else
            set all_json "$all_json,"
        end
        set all_json "$all_json \"$name\": {\"cluster\": \"$cluster\", \"instances\": $data}"
    end
    set all_json "$all_json }"

    echo $all_json | python3 -c "
import sys, json
from collections import Counter

hourly_map = {
    'c8g.xlarge': 0.115, 'c7g.xlarge': 0.109, 'c6g.xlarge': 0.102,
    'm8g.2xlarge': 0.274, 'm7g.2xlarge': 0.259, 'm6g.2xlarge': 0.231,
    'm8g.xlarge': 0.137, 'm7g.xlarge': 0.130,
    't3.large': 0.083, 't3.xlarge': 0.166, 't3.medium': 0.042,
}

data = json.load(sys.stdin)
grand_total = 0

for name, info in data.items():
    instances = info['instances']
    if not instances:
        print(f'  {name}: unable to fetch')
        continue

    counts = Counter(i[1] for i in instances)
    cluster_total = 0

    print(f'  {name} cluster')
    print(f'  ────────────────────────────────────────────────────')

    for itype in sorted(counts.keys()):
        count = counts[itype]
        hourly = hourly_map.get(itype, 0)
        monthly = hourly * 730
        subtotal = monthly * count
        cluster_total += subtotal
        print(f'  {count}x {itype:<14}  \${hourly:.3f}/hr  ×  730h  =  \${subtotal:>8,.2f}')

    print(f'  {\"Subtotal:\":<50} \${cluster_total:>8,.2f}/mo')
    print()
    grand_total += cluster_total

print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━')
print(f'  {\"EC2 Total:\":<50} \${grand_total:>8,.2f}/mo')
print()
print('  Additional estimated costs:')
print('  EBS volumes + snapshots              ~\$300-500/mo')
print('  Data transfer                        ~\$100-200/mo')
print('  Load balancers (2x NLB)              ~\$50/mo')
print('  S3 + Route 53                        ~\$40/mo')
print('  ────────────────────────────────────────────────────')
low = grand_total + 490
high = grand_total + 790
print(f'  {\"Estimated grand total:\":<50} \${low:>7,.0f}-\${high:,.0f}/mo')
print()
"
end
