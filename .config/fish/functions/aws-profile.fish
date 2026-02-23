function aws-profile
    set -gx AWS_PROFILE $argv[1]
    set -gx AWS_DEFAULT_REGION (aws configure get region)
    set -gx AWS_ACCESS_KEY_ID (aws configure get aws_access_key_id)
    set -gx AWS_SECRET_ACCESS_KEY (aws configure get aws_secret_access_key)
end

function with-aws-profile
    set -l profile $argv[1]
    set -e argv[1]
    aws-profile $profile
    eval $argv
end
