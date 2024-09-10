#!/bin/bash

## This script is used to install the necessary packages for a script to run.
## Author: Rosen Vitanov
## Date: 2024-09-10
Version="0.2"

## Here are stored all the necessary packages for the script to run"
DEPENDENCIES=( 

)

## This function checks if the necessary packages are installed.
## It uses the first parameter - as a list of packages to check.
## The function returns 0 if all packages are installed, otherwise it returns the number of missing packages.
## The function also prints the missing packages. 
## After it has printed the missing packages, it will ask the user if he wants to install them.
## If the user types "yes" or "y" the function will install the missing packages.
## If the user types "no" or "n" the function will exit with code 1.
## If the user types anything else, the function will ask the user to type "yes" or "no".
## The function will check if the package was installed successfully and will print a message.

function solve_dependencies() {
    local missing_packages=0
    local missing_packages_list=()
    
    local FLAG_SKIP_PROMPT=false
    local FLAG_YES_TO_ALL=false

    while getopts "hysi:" opt; do
        case $opt in
            i) 
                ## Input file or list of packages to check
                ## Check if the input parameter is a file or a list of packages
                ## If a file - check if the file exists and read the packages from it
                ## If a list of packages - read the packages from the input
                ## If the input is not a file or a list of packages - exit with code 1

                if [ -f "$OPTARG" ]; then
                    while IFS= read -r package; do
                        DEPENDENCIES+=("$package")
                    done < "$OPTARG"
                elif [ -n "$OPTARG" ]; then
                    IFS=',' read -ra packages <<< "$OPTARG"
                    DEPENDENCIES+=("${packages[@]}")
                else
                    echo "Invalid input parameter: $OPTARG" >&2
                    return 1
                fi

                ;;
            y)
                ## Automatically installs missing packages without asking for user intervention, but shows the missing packages.
                FLAG_YES_TO_ALL=true
                ;;
            s)
                ## Silent automated mode - installs missing packages without asking for any user intervention (exsept for sudo password)
                ## This automatically sets the -y flag
                FLAG_SKIP_PROMPT=true
                FLAG_YES_TO_ALL=true
                ;;
            h)
                echo "depresolver.sh - Dependency resolver script"
                echo "Version: $Version"
                echo "Usage: $0 [-i <file|packages>] [-y] [-s]"
                echo "Options:"
                echo "  -i <file|packages>  Input file or list of packages to install"
                echo "  -y                  Automatically installs missing packages without asking for user intervention, but will show the missing packages"
                echo "  -s                  Silent automated mode - installs missing packages without asking for any user intervention or giving any ourput"
                ;;
            \?)
                echo "Invalid option: -$OPTARG" >&2
                return 1
                ;;
        esac
    done

    [ "$FLAG_SKIP_PROMPT" = false ] && echo "Checking dependencies for $0"
    for package in "${DEPENDENCIES[@]}"; do
        [ "$FLAG_SKIP_PROMPT" = false ] && echo -n " - Checking $package...                    "
        
        if ! (dpkg -l | grep -w "$package") > /dev/null; then   
                missing_packages=$((missing_packages+1))
                missing_packages_list+=($package)
                [ "$FLAG_SKIP_PROMPT" = false ] && echo -e "\e[31m Missing \e[0m"
            else
                [ "$FLAG_SKIP_PROMPT" = false ] && echo -e "\e[32m OK \e[0m"
        fi
    done

    [ "$FLAG_SKIP_PROMPT" = false ] && echo ""
    if [ $missing_packages -eq 0 ]; then
        [ "$FLAG_SKIP_PROMPT" = false ] && echo "All dependencies are satisfied." 
        return 0
    else
        [ "$FLAG_SKIP_PROMPT" = false ] && echo "The following dependencies are missing:"
        for package in "${missing_packages_list[@]}"; do
            [ "$FLAG_SKIP_PROMPT" = false ] && echo $package
        done

        if [ "$skip_prompt" = false ] || [ "$install_all" = true ]; then
            for package in "${missing_packages_list[@]}"; do
                [ "$FLAG_SKIP_PROMPT" = false ] && echo -n " - Installing $package...                  "
                sudo apt-get install -y $package >> /dev/null
                if (dpkg -l | grep -w "$package") > /dev/null; then
                    [ "$FLAG_SKIP_PROMPT" = false ] && echo -e "\e[32m OK \e[0m"
                else
                    [ "$FLAG_SKIP_PROMPT" = false ] && echo -e "\e[31m Failed \e[0m"
                fi
            done
            return 0
        else
            [ "$FLAG_SKIP_PROMPT" = false ] && echo ""
            while true; do
                if [ "$FLAG_YES_TO_ALL" = true ]; then
                        answer="yes"
                    else
                        read -p "Do you want to install the missing dependencies? (yes/no): " answer
                fi
                case $answer in
                    [Yy]* ) 
                        for package in "${missing_packages_list[@]}"; do
                            [ "$FLAG_SKIP_PROMPT" = false ] && echo -n " - Installing $package...                  "
                            sudo apt-get install -y $package >> /dev/null
                            if (dpkg -l | grep -w "$package") > /dev/null; then
                                [ "$FLAG_SKIP_PROMPT" = false ] && echo -e "\e[32m OK \e[0m"
                            else
                                [ "$FLAG_SKIP_PROMPT" = false ] && echo -e "\e[31m Failed \e[0m"
                            fi
                        done
                        return 0
                        ;;
                    [Nn]* ) 
                        return 1
                        ;;
                    * ) 
                        [ "$FLAG_SKIP_PROMPT" = false ] && echo "Please answer yes or no."
                        ;;
                esac
            done
        fi
    fi
}
