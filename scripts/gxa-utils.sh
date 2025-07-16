source ./config/gxa-build.conf

L4T_VERSION=$1

echoblue() {
  echo -e "\033[1;34m$1\033[0m"
}

echored() {
  local text=$1
  echo -e "\033[1;33m$text\033[0m"
}

echogreen() {
  local text=$1

  # If no = sign is present, just print the text in green
  if [[ ! "$text" =~ = ]]; then
    echo -e "\033[1;32m$text\033[0m"
    return
  fi

  # Text before '=' is colored green
  local green_text=$(echo "$text" | sed 's/=.*//') # Extract text before '='
  local rest_text=$(echo "$text" | sed 's/^[^=]*=//') # Extract text after '='
  echo -e "\033[1;32m$green_text\033[0m=$rest_text" # Print the whole line with the first part in green
}

#######################################################
#
# Download and extract archive files
#
#######################################################
function download_and_extract() {
  local url=$1
  local dest_dir=$2
  local filename=$(basename $url)

  # if the destination directory does not exist, create it
  if [ ! -d $dest_dir ]; then
    echoblue "Creating directory $dest_dir"
    mkdir -p $dest_dir
  fi

  if [ ! -f $SOURCES/$filename ]; then
    echoblue "Downloading $filename"
    wget ${WGET_EXTRA_ARGS} -O $SOURCES/$filename $url
  else
    echogreen "File $filename already exists, skipping download"
    return 0
  fi
  # Extract the file to the destination directory
  if [[ $filename == *.tar.gz || $filename == *.tgz ]]; then
    echogreen "Extracting $filename"
    tar -xzf $SOURCES/$filename -C $dest_dir
  elif [[ $filename == *.tar.bz2 || $filename == *.tbz2 ]]; then
    echogreen "Extracting $filename"
    tar -xjf $SOURCES/$filename -C $dest_dir
  elif [[ $filename == *.zip ]]; then
    echogreen "Extracting $filename"
    unzip -q $SOURCES/$filename -d $dest_dir
  else
    echogreen "Unsupported file format: $filename"
    return 1
  fi
}

#######################################################
#
# Download &  Extract sources if not present
#
#######################################################
function get_default(){
    test=$(xmllint --xpath "string(/l4tSources/versions)" ${XML_FILE})
    num_versions=$(echo "$test" | sed -n '2p')
    # Strip whitespace
    num_versions=$(echo $num_versions | xargs)
    echogreen "Number of versions=$num_versions"

    # Check if L4T_VERSION is set in the environment
      echogreen "Latest L4T version=${L4T_VERSION}"
    if [ -z $L4T_VERSION ]; then
      L4T_VERSION=$(echo "$test" | sed -n "$((num_versions+2))p")
      #trim whitespace and "l4t" from the version
      L4T_VERSION=$(echo $L4T_VERSION | xargs)
      L4T_VERSION=$(echo $L4T_VERSION | sed 's/l4t//')
      echogreen "Latest L4T version=${L4T_VERSION}"
    fi
    export L4T_VERSION

    # If /version file does not exist then return
    if [ ! -f $PROJECT_ROOT/version ]; then
        return
    fi
    # Read major, minor, patch and suffix from ./version file
    RELEASE_MAJOR=$(sed -n '1p' $PROJECT_ROOT/version | tr -d '\n')
    RELEASE_MINOR=$(sed -n '2p' $PROJECT_ROOT/version | tr -d '\n')
    RELEASE_PATCH=$(sed -n '3p' $PROJECT_ROOT/version | tr -d '\n')
    RELEASE_SUFFIX=$(sed -n '4p' $PROJECT_ROOT/version | tr -d '\n')
    # Check suffix is not empty
    if [ -z "$RELEASE_SUFFIX" ]; then
        BSP_VERSION="$RELEASE_MAJOR.$RELEASE_MINOR.$RELEASE_PATCH"
    else
        BSP_VERSION="$RELEASE_MAJOR.$RELEASE_MINOR.$RELEASE_PATCH-$RELEASE_SUFFIX"
    fi
    echogreen "BSP Version=$BSP_VERSION"
    export BSP_VERSION
}
