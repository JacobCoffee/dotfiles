function vswp -d "Switch PDM virtual environment" -a env_name
  set -l verbose_flag 0
  set -l activation_command

  for arg in $argv
    switch $arg
      case -v --verbose
        set verbose_flag 1
      case '*'
        if not set -q env_name
          set env_name $arg
        end
    end
  end

  if test -z "$env_name"
    echo "Usage: vswp [-v | --verbose] <environment_name>"
    return 1
  end

  # Attempt to activate the environment and capture the activation command.
  set activation_command (pdm venv activate $env_name 2>&1 | string match -r "source '/.*'")

  if test $verbose_flag -eq 1
    echo $activation_command
  end

  # If the activation command is not empty, execute it.
  if test -n "$activation_command"
    eval $activation_command
    echo "Activated the '$env_name' environment."
  else
    echo "Failed to activate the environment '$env_name'."
    return 1
  end
end
