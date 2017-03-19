#!/bin/bash

#############################################################################
#																			#
#	@author			Øystein "iRock" Jacobsen								#
#	@email			irock.dev@gmail.com										#
#	@title			VirtualBox.sh											#
#	@date			06.04.15 - 19.03.17 									#
#	@description	Installs VirtualBox repo and VirtualBox					#
#																			#
#############################################################################

	
	# -= SCRIPT VARIABLES =- #
	install=1																	# Install / Uninstall ( 1 / 0 ).
	package="VirtualBox-5.1 kernel-devel gcc dkms"								# Packages to install.
	user=`users`																# group permisssion.
	debug=1																		# Debugging.
	log=1																		# Logging ( 0 / 1 / 2 ) ( None / File / File & Terminal).
	log_file="$script_path/$script_name.log"									# Log file name ($0.log).


	# -= IMPORTING FUNCTIONS =-#
	source "`dirname "$0"`/framework/FunctionLibrary.sh"						# Importing FunctionLibrary.sh


	# -= ELEVATING PRIVILEGES =- #
	elevate_privileges															# Elevate privileges


	# -= CORE VARIABLES =- #
	core_variables																# Determines system-variables		


	# -= PRE INSTALL =- #
	repo_url="http://download.virtualbox.org/virtualbox/$pkg/`echo $distro | tr '[:upper:]' '[:lower:]'`/virtualbox.repo"	# URL to repo.

	# -= INSTALL REPOSITORY =- #																
	if [ $pkg == "rpm" ]; then
		install_repo "1" "$repo_url" "https://www.virtualbox.org/download/oracle_vbox.asc"
	elif [ $pkg == "deb" ]; then
		install_repo "1" "$repo_url" "https://www.virtualbox.org/download/oracle_vbox_2016.asc" "https://www.virtualbox.org/download/oracle_vbox.asc"
	fi


	# -= INSTALL =- #
	install_pkg "1" $package


	# -= POST INSTALL =- #
	if [ "`getent group vboxusers`" == "" ]; then										# If vboxusers group doesn't exist.
		groupadd vboxusers																	# Create vboxusers group.
	fi
	usermod -a -G vboxusers "$user"														# Add user to vboxusers.
	
	
	# BUILD DRIVERS #
	/usr/lib/virtualbox/vboxdrv.sh setup												# Build kernel modules.
	#/etc/init.d/vboxdrv setup															# Build kernel modules.
	#/sbin/rcvboxdrv setup																# Build kernel modules.
