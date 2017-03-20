#!/bin/bash

	#############################################################################
	#																			#
	#	@author			Øystein "iRock" Jacobsen								#
	#	@email			irock.dev@gmail.com										#
	#	@title			Function Library										#
	#	@date			11.06.2016 - ?											#
	#	@description	A library of often used functions						#
	#																			#
	#############################################################################


	#################################################
	# 			-= ELEVATE PRIVILEGES =-			#
	# @description: Elevates privileges to root and #
	#				runs the calling script again.	#
	#################################################
	function elevate_privileges {
		#if [ $EUID != 0 ]; then																# If not root
		if [ `whoami` != root ]; then
			if [ $debug != 0 ]; then echo "Elevating privileges to root "; echo; fi
			if [ -t 1 ]; then																	# If run from terminal
				sudo sh "$0" "$@"																	# Elevating to root in terminal
				exit 0
			elif [ `gnome-shell --version | cut -d " " -f3 | cut -d "." -f1` -le 2 ]; then		# If run from Gnome 1 or 2
				gksudo "$0" "$@"																	# Elevating to root in Gnome 1 or 2
				exit 0
			elif [ `gnome-shell --version | cut -d " " -f3 | cut -d "." -f1` -ge 3 ]; then 		# If Gnome version is 3
				pkexec "$0" "$@"																	# Elevating to root in Gnome 3
				exit 0
			else																				# If desktop environment is undetermined
				if [ $debug != 0 ]; then echo "Can't determine desktop environment"; echo "Exiting"; echo; fi
				zenity --error --text="Can't determine desktop environment"
				exit -1
			fi
		fi
	}


	#################################################
	#			-= ENUMERATE DISTRO =-				#
	# @description:	Determines distribution,		#
	#				release, kernel and 			#
	#				architecture					#
	# @TODO:		Add distro unknown!				#
	#################################################
	function enumerate_distro {
		if [ $debug == 0 ]; then echo "Determining distro"; fi

		if [ -f /etc/lsb-release ]; then														# If "linux standard base" is present
			distro=`cat /etc/lsb-release | cut -d " " -f1`
			release=`cat /etc/lsb-release | cut -d " " -f3`
		elif [ -f /etc/debian_version ]; then													# If Debian based distro
			distro="Debian"  # XXX or Ubuntu??
			release=`cat /etc/debian_version`
		elif [ -f /etc/redhat-release ]; then													# If redhat based distro
			distro=`cat /etc/redhat-release | cut -d  " " -f1`
			release=`cat /etc/redhat-release | cut -d " " -f3`
		else																					# Else Install lsb
			if [ `rpm -qa dnf` -ne "" ]; then
				dnf -y install redhat-lsb-core
			elif [ `rpm -qa yum` -ne "" ]; then
				yum -y install redhat
			fi	

			distro=`lsb_release -si`
			release=`lsb_release -sr`
		fi
		#distro=`lsb_release -si`	#`lsb_release -i | cut -d":" -f2 | xargs`					# Distrobution name (Fedora / Debian / Ubuntu / Kali)
		#release=`lsb_release -sr`	#`rpm -E %distro`											# Release number (22 / 8.2 / 15.04 / 2.0)
		kernel=`uname -r | cut -d"." -f1-3`														# Kernel version (4.1.6-200)
		arch=`uname -m`				#$(uname -m | sed 's/x86_//;s/i[3-6]86/32/')				# Architecture (x86_64 / i686)
		
		# if [ -z "$distro" ] || [ -z "$relese" ] || [ -z #$kernel ] || [ z- "$arch ]; then 
		# echo "echo Could not enumerate distro!"
		# exit -1
		if [ $debug != 0 ]; then echo "$distro $release - $kernel-$arch"; echo; fi
	}
												

	#################################################
	#		-= DETERMINE PACKAGE ENVIRONMENT =-		#
	# @description:	Determines which packages and   #
	#				packamanager the system uses	#
	#################################################
	function determin_pkgman {
		if [ -z "$distro" ]; then
			enumerate_distro
		fi
		
		if [ $debug != 0 ]; then echo "Determining package manager"; fi
		case "$distro" in
			Fedora)
				if [ $release -le 21 ]; then
					pkgman="yum"
				elif [ $release -ge 22 ]; then
					pkgman="dnf"
				fi
				pkg="rpm"
			;;
			Debian)
				pkgman="apt-get"
				pkg="deb"
			;;
			Ubuntu)
				pkgman="apt-get"
				pkg="deb"
			;;
			Kali)
				pkgman="apt-get"
				pkg="deb"
			;;
			Raspbian)
				pkgman="apt-get"
				pkg="deb"
			;;
		esac
		
		
		if [ $debug != 0 ]; then echo "$pkgman / $pkg"; echo; fi
	}


	#################################################
	# 			-= ENUMERATE SCRIPT =-				#
	# @description:	Determines script related info	#
	#################################################
	function enumerate_script {	
		script_name=`basename "$0" ".sh"`														# Script name
		script_ext=`basename "$0" "$script_name"`												# Script extension
		script_path="`dirname "$0"`"															# Script path
	}


	#################################################
	# 			-= CORE VARIABLES =-				#
	# @description:	Determines operating system and #
	#				script related variables		#
	#################################################
	function core_variables {
		enumerate_distro																		# Determine distro, release, kernel and architecture.
		
		determin_pkgman																			# Determines package-manager.

		enumerate_script																		# Determines script-path, name and extension.
	}


	#################################################
	#			-= GET USER INPUT =-				#
	# @description:	Get userinput from terminal.	#
	#################################################
	function read_input {
		read input																				# Reads a line from the terminal.
	}

	
	#################################################
	#			-= CURRENT DATE =-					#
	# @description:	Get userinput from terminal.	#
	#################################################
	function get_date {
		date +%Y%m%d																			# Writes todays date in YYYYMMDD format.
	}


	#################################################
	# 			-= ADD USER =-						#
	# @description:	Adds a new user to linux. 		#
	# @parameters: 									#
	#			$1		username 		(string)	#
	#			$2-$N	groups 			(string)	#
	#################################################
	function add_user {
		echo "Adding user: $1"
		useradd "$1"																			# Add new user
		passwd "$1"																				# Prompt for password
		for group in "${@:2}"; do																# For all arguments except first
			adduser $group																		# Add user to group
		done
		echo
	}
	

	#################################################
	# 				-= SET HOSTNAME =-				#
	# @description:	Sets the hostname of the system.#
	# @parameters: 									#
	#			$1		hostname 		(string)	#
	#################################################
	function set_hostname {
		echo "Setting hostname: $1"
		temp=`hostname`																			# Find old hostname
		sed -i "s/$temp/$1/" /etc/hostname														# Replacing old hostname with new
		sed -i "s/$temp/$1/" /etc/hosts															# Replacing old hostname in known hosts
		hostname $1																				# Setting hostname for current session
		echo
	}


	#################################################
	#			-= IS PACKAGE INSTALLED =-			#
	# @description:	Determine if package is 		#
	#				installed.						#
	# @parameters:									#
	#			$1		install / remove	(1/0)	#
	#			$2		package name	(string)	#
	#################################################
	function is_pkg_installed {
		if [ -z $pkgman ]; then
			determin_pkgman
		fi

		which $2
		if [[ $? == 1 ] && [ $1 == 1 ]]; then
			install_pkg $1 $2
		fi
	}


	#################################################
	#			-= INSTALL PACKAGES =-	 			#
	# @description: Install/Remove packages			#
	# @parameters:									#
	#			$1:		install / remove	(1/0)	#	
	#			$2-$N:	packages to handle			#
	#################################################
	function install_pkg {
		if [ -z $pkgman ]; then
			determin_pkgman
		fi
		
		
		if [ $1 == 1 ]; then
			if [ $debug != 0 ]; then echo "Installing ${@:2} with $pkgman"; fi
			$pkgman -y install "${@:2}"
		elif [ $1 == 0 ]; then
			if [ $debug != 0 ]; then echo "Removing ${@:2} with $pkgman"; fi
			$pkgman -y remove "${@:2}"
		fi

		if [ $debug != 0 ]; then echo; fi
	}
	
	
	#################################################
	#			-= INSTALL ARCHIVE =-	 			#
	# @description: Install\Remove archive			#
	# @parameters:									#
	#			$1:		install / remove 	(1/0)	#
	#			$2:		install path		(string)#
	#			$3:		url to archive		(string)#
	#################################################
	function install_arch {		
		if [ $1 == 1 ]; then
			if [ ! -e `basename "$3"` ]; then				
				if [ $debug != 0 ]; then echo "Downloading $3"; fi	
				wget "$3"
				echo
			fi
			if [ $debug != 0 ]; then echo "Installing `basename "$3"` to $2"; fi
			if [ ! -d "$2" ]; then
				mkdir "$2"
			fi
			tar -xf `basename "$3"` -C "$2"
			if [ $debug != 0 ]; then echo "Deleting `basename "$3"`"; fi
			rm `basename "$3"`
		elif [ $1 == 0 ]; then
			if [ $debug != 0 ]; then echo "Deleting $2"; fi
			rm -rf "$2"
		fi

		if [ $debug != 0 ]; then echo; fi
	}
	
	
	#################################################
	#			-= INSTALL IMAGE =- 				#
	# @description: Install an image to a device.	#
	# @parameters:									#	
	#			$1		image_path 		(string)	#
	#			$2		install_device 	(string)	#
	#################################################
	function install_image {
		echo "Installing $1 to $2"
		if [ -e $1 ]; then
				if [ -e "/dev/$2" ]; then
					echo "Unmounting:"											# Unmount all partitions device
					df -h | grep "$2"
					df -h | grep "2" | cut -d' ' -f1 | while read line ; do umount $line ; done
					echo
					echo "Installing:"
					dd bs=4M if="$1" of="/dev/$2"								# Install image to device
					sync														# Flush cache 
					echo "Done"
				else
					echo "Could not find $2"
				fi
		else
			echo "Could not find image $1"
		fi
		echo
	}

	
	#################################################
	#			-= INSTALL REPOSITORY =- 			#
	# @description: Install/Remove repository		#
	# @parameters:									#
	#			$1:		install / remove	(1/0)	#
	#			$2:		repository package url		#
	#			$3-$N:	repository gpg key url		#
	# @TODO:	Add apt-get repo download			#
	#################################################	
	function install_repo {
		if [ -z $pkgman ]; then
			determin_pkgman
		fi
		
		if [ $debug != 0 ]; then echo "`date +%Y/%m/%d-%H:%M` - Installing $2"; fi
		
		repo_ext=`basename "$2" | awk -F "." '{print $NF}'`			# Repository extension
		repo_name=`basename "$2" ".$repo_ext"`						# Repository name
		
		if [ $pkgman == "yum" ] && [ "$repo_ext" == "rpm" ]; then
			$pkgman config-manager --add-repo "$2"
		elif [ $pkgman == "yum" ] && [ "$repo_ext" == "repo" ]; then
			rpm --import -f $2
		elif [ $pkgman == "dnf" ] && [ "$repo_ext" == "rpm" ]; then
			$pkgman -y install "$2"
		elif [ $pkgman == "dnf" ] && [ "$repo_ext" == "repo" ]; then
			curl -o /etc/yum.repos.d/"$repo_name.$repo_ext" $2
		fi
		
		if [ $debug != 0 ]; then echo "`date +%Y/%m/%d-%H:%M` - Adding repository gpg keys ${@:3}"; fi
		if [ $pkg == "rpm" ]; then
			for url in ${@:3} ; do
				rpm --import "$url"
			done
		elif [ $pkg == "deb" ]; then
			for url in ${@:3} ; do
				wget -q "$url" -O- | apt-key add -
			done
		fi
		
		if [ $debug != 0 ]; then echo; fi
	}
		
