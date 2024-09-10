#!/bin/bash

## This script is used to install the necessary packages for a script to run.
## Author: Rosen Vitanov
## Date: 2024-09-10
## Version: 1.0

## Here are stored all the necessary packages for the script to run"
DEPENDENCIES=( 
curl
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

    echo "Checking dependencies for $0"
    for package in "${DEPENDENCIES[@]}"; do
        echo -n " - Checking $package...                    "
        
        if ! (dpkg -l | grep -w "$package") > /dev/null; then   
                missing_packages=$((missing_packages+1))
                missing_packages_list+=($package)
                echo -e "\e[31m Missing \e[0m"
            else
                echo -e "\e[32m OK \e[0m"    
        fi
    done

    if [ $missing_packages -eq 0 ]; then
        echo "All dependencies are satisfied." 
        return 0
    else
        echo "The following dependencies are missing:"
        for package in "${missing_packages_list[@]}"; do
            echo $package
        done
        while true; do
            read -p "Do you want to install the missing dependencies? (yes/no): " answer
            case $answer in
                [Yy]* ) 
                    for package in "${missing_packages_list[@]}"; do
                        echo -n " - Installing $package...                  "
                        sudo apt-get install -y $package >> /dev/null
                        if (dpkg -l | grep -w "$package") > /dev/null; then
                            echo -e "\e[32m OK \e[0m"
                        else
                            echo -e "\e[31m Failed \e[0m"
                        fi
                    done
                    return 0
                    ;;
                [Nn]* ) 
                    return 1
                    ;;
                * ) 
                    echo "Please answer yes or no."
                    ;;
            esac
        done
    fi
}

solve_dependencies
