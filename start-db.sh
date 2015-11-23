#!/bin/bash -e
# ./start-db.sh -p port

get_script_dir () {
     SOURCE="${BASH_SOURCE[0]}"

     while [ -h "$SOURCE" ]; do
          DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
          SOURCE="$( readlink "$SOURCE" )"
          [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
     done
     cd -P "$( dirname "$SOURCE" )"
     pwd
}

DOCKER_PORT_OPTS=""
while getopts ":p:" opt; do
  case ${opt} in 
    p )
      DOCKER_PORT_OPTS="-p $OPTARG:5432"
      ;;
    \? )
      echo "Invalid option: $OPTARG" 1>&2
      ;;
    : )
      echo "Invalid option: $OPTARG requires an argument" 1>&2
      ;;
  esac
done
shift $((OPTIND -1))

if groups $USER | grep &>/dev/null '\bdocker\b'; then
    DOCKER="docker"
else
    DOCKER="sudo docker"
fi

$DOCKER rm --force analyticsdb 2> /dev/null | true
$DOCKER run --name analyticsdb $DOCKER_PORT_OPTS \
    -v $(get_script_dir)/sql:/docker-entrypoint-initdb.d/ \
    -e POSTGRES_PASSWORD=test -d postgres:9.4.5

$DOCKER exec analyticsdb \
    /bin/bash -c 'while ! pg_isready -U postgres ; do sleep 1; done'
