#!/usr/bin/env bash

py=python3
venv="$HOME/.goad/.venv"
requirement_file="requirements.yml"

# Check if we're in offline mode
OFFLINE_MODE=0
if [ -d "cache/pip-packages" ] && [ "$(ls -A cache/pip-packages)" ]; then
    OFFLINE_MODE=1
    echo "[+] Detected cached packages - running in offline mode"
fi

if [ ! -d "$venv" ]
then
  # Get the Python version (removes 'Python' from output)
  version=$($py --version 2>&1 | awk '{print $2}')
  echo "Python version in use : $version"
  # Convert the version to comparable format (removes the dot and treats it as an integer)
  version_numeric=$(echo $version | awk -F. '{printf "%d%02d%02d\n", $1, $2, $3}')
  # Check if the version is >= 3.8.0
  if [ "$version_numeric" -ge 30800 ]; then
      # echo "Python version is >= 3.8.0
      echo 'python version >= 3.8 ok'
      if [ "$version_numeric" -lt 31100 ]; then
        # python version < 3.11
        requirement_file="requirements.yml"
      else
        # python version >= 3.11
        requirement_file="requirements_311.yml"
      fi
  else
      echo "Python version is < 3.8 please update python before install"
      exit
  fi

  if [ "$($py -m venv -h 2>/dev/null | grep -i 'usage:')" ]; then
    echo "venv module is installed. continue"
  else
    echo "venv module is not installed."
    echo "please install $py-venv according to your system"
    echo "exit"
    exit 0
  fi

  echo '[+] venv not found, start python venv creation'
  mkdir -p ~/.goad
  $py -m venv $venv
  source $venv/bin/activate
  if [ $? -eq 0 ]; then
    if [ $OFFLINE_MODE -eq 1 ]; then
        echo "[+] Installing packages from cache..."
        $py -m pip install --no-index --find-links=cache/pip-packages -r $requirement_file
    else
        $py -m pip install --upgrade pip
        export SETUPTOOLS_USE_DISTUTILS=stdlib
        $py -m pip install -r $requirement_file
    fi

    cd ansible
    if [ $OFFLINE_MODE -eq 1 ]; then
        echo "[+] Installing ansible collections from cache..."
        ansible-galaxy collection install cache/ansible-collections/*.tar.gz -p ~/.ansible/collections
    else
        ansible-galaxy install -r requirements.yml
    fi
    cd -

    if [ $? -eq 0 ]; then
        echo "Installation completed"
        echo "run : source ~/.goad/bin/activate"
        exit 0
    fi
  else
    echo "Error in venv creation"
    rm -rf $venv
    exit 0
  fi
fi

# launch the app
source $venv/bin/activate
$py goad.py $@
deactivate
