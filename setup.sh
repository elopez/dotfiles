#!/bin/sh
set -e

# This setup.sh script requires:
#  * git
#  * sh

ROOT=$(cd $(dirname $0); git rev-parse --show-toplevel)

# To support dotfiles referencing other scripts and files
# without needing to copy them, we need a standard path
# they can reference. Let's standarize on "~/.dotfiles"
if [ "$ROOT" != "$HOME/.dotfiles" ]; then
	echo "ERROR: you must clone the repo as ~/.dotfiles/" >&2
	exit 1
fi

# Prepare backup directory
BACKUPS="$ROOT/backups/$(date +%s)/"
mkdir -p "$BACKUPS"

cd "$ROOT"
for module in configs/* configs-private/*; do
	# not a module - skip
	if [ ! -d "$module" ]; then
		continue;
	fi

	# incomplete module - skip
	if [ ! -f "$module/dotfiles" ]; then
		continue;
	fi

	# run build script if provided
	if [ -x "$module/build.sh" ]; then
		echo "Building dotfiles for $module"
		(cd "$module" && ./build.sh)
	fi

	echo "Installing dotfiles for $module"

	# install dotfiles - back up existing ones
	for dotfile in $(cat "$module/dotfiles"); do
		MODULE="$ROOT/$module"
		ORIG="$MODULE/$(echo $dotfile | cut -f1 -d:)"
		DEST="$HOME/$(echo $dotfile | cut -f2 -d:)"

		# if destination is unset, use default
		if [ "$DEST" = "$HOME/" ]; then
			DEST="$HOME/$ORIG"
		fi

		# if dotfile already exists, back it up
		if [ -f "$DEST" ] || [ -L "$DEST" ]; then
			mv "$DEST" "$BACKUPS/"
		fi

		# if destination directory doesn't exist, create it
		DESTDIR=$(dirname "$DEST")
		if [ ! -d "$DESTDIR/" ]; then
			mkdir -vp "$DESTDIR"
		fi

		# link the dotfile
		ln -vs "$ORIG" "$DEST"
	done		
done
