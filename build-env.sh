#!/usr/bin/env bash
#
# Build a Docker-powered WordPress Develop environment.

declare -a ACTIVE_PLUGINS

PHP_VERSION="7.3-fpm"
ACTIVE_PLUGINS=()
WP_VERSION=trunk

# Print basic usage instructions.
print_usage() {
  echo 'Build a Docker-powered WordPress Develop environment.';
  echo
  echo 'Usage:'
  echo -e "\t${0} [options]"
  echo
  echo 'Options:'
  echo -e "\t-h,--help\tShow all available options.\n"
  echo -e "\t--plugin\tA WordPress plugin to install and activate."
  echo -e "\t\t\tThis argument may be used multiple times.\n"
  echo -e "\t\t\tAccepts valid <plugin> for \`wp plugin install\`:"
  echo -e "\t\t\thttps://developer.wordpress.org/cli/commands/plugin/install/\n"
  echo -e "\t--php\t\tThe version of PHP to use. Default is 7.3-fpm."
  echo -e "\n\t\t\tA full list of supported versions is available at:"
  echo -e "\t\t\thttps://hub.docker.com/r/wordpressdevelop/php/tags\n"
  echo -e "\t--wp\t\tThe version of WordPress to use. Default is trunk."
}

# Print example usage.
print_examples() {
  set -e
  echo 'Examples:'
  echo -e "\t# Create an environment for WordPress 5.2 on PHP 7.1"
  echo -e "\t${0} --wp=5.2 --php=7.1"
}

# Implode an array into a string
#
# Arguments:
#   $1: The string to separate entries.
#   $2: The array to join together.
function implode {
  local d=$1
  shift
  echo -n "$1"
  shift
  printf "%s" "${@/#/$d}"
}

# Parse arguments.
while [ $# -gt 0 ]; do
  case "$1" in
    --php=*)
      PHP_VERSION="${1#*=}"
      ;;
    --plugin=*)
      ACTIVE_PLUGINS+=("${1#*=}")
      ;;
    --wp=*)
      WP_VERSION="${1#*=}"
      ;;
    -h|--help|*)
      print_usage
      echo
      print_examples
      exit
      ;;
  esac
  shift
done

echo "PHP Version: ${PHP_VERSION}"
echo "WordPress Version: ${WP_VERSION}"
echo -n 'Active plugins: '
implode ', ' "${ACTIVE_PLUGINS[@]}"
echo

# Checkout WordPress trunk
svn checkout "https://develop.svn.wordpress.org/trunk/" "wordpress"
#svn switch "^/tags/${WP_VERSION}"

# Build the environment

set -ex

docker-compose up -d

# Create a configuration file
docker-compose run --rm cli wp config create --dbname=wordpress_develop --dbuser=root --dbpass=password --dbhost=mysql --path=/var/www/src --force

docker-compose run --rm php php -v
docker-compose run --rm php php -m
docker-compose run --rm cli wp core version
docker-compose run --rm cli wp --version

#if [ "${#ACTIVE_PLUGINS[@]}" -gt 0 ]; then
#  docker-compose run cli wp plugin install $(implode ' ' "${ACTIVE_PLUGINS[@]}")
#fi

# Shut everything down
#docker-compose -f down
