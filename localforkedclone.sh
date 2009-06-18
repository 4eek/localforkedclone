#!/bin/sh

# Automatic configuration for local Git repository from a project fork
#
# Rationale:
# This method of forking helps minimise conflicts by encouraging pristine
# tracking of upstream master and edge branches. It also promotes organised 
# branching and encourages the frequent upstream assimilation of pull
# requests. It does this by allowing easy tracking of the upstream master and
# edge branches and providing a local development branch to submit pull
# requests to upstream via GitHub's forking system which provides a nice
# interface for managing pull requests.
#
# This script will create a local clone of the forked project Git repository
# located on GitHub. The specified project fork will be added as an additional
# remote repository and a new development branch created to track local
# development.
#
# Requirements:
# 1. working git installation
# 2. project fork repository on GitHub
# 
# Usage:
# localforkedcone.sh <YOUR_GITHUB_ACCOUNT_NAME> <FORKED_PROJECT_NAME> <UPSTREAM_GITHUB_ACCOUNT_NAME> [YOUR_DEV_BRANCH=dev] [BRANCH_TO_TRACK=edge]
#
##
# Original author: long @ insoshi who wrote a nice blog post about this at:
# http://blog.insoshi.com/2008/10/14/setting-up-your-git-repositories-for-open-source-projects-at-github/
#
# Modifications by: Colin Surprenant, http://github.com/colinsurprenant, http://eventuallyconsistent.com/blog/
#                   Kevin Fourie, http://github.com/4eek, http://blog.4e.co.za
#

# Error handling function
catch_error() {
  if [ $1 -ne "0" ]
  then
    echo "ERROR encountered: $2"
    exit 1
  fi
}

USAGE="Usage: localforkedcone.sh <YOUR_GITHUB_ACCOUNT_NAME> <FORKED_PROJECT_NAME> <UPSTREAM_GITHUB_ACCOUNT_NAME> [YOUR_DEV_BRANCH=dev] [BRANCH_TO_TRACK=edge]"

# Setup defaults if needed
case $4 in
'') DEV_BRANCH="dev" ;;
*) DEV_BRANCH="$4" ;;
esac
case $5 in
'') TRACK_BRANCH="edge" ;;
*) TRACK_BRANCH="$5" ;;
esac
REMOTE="YOUR_GITHUB_ACCOUNT_NAME"

# Print out the script help
print_help() {
echo
echo "-- Quick Help --"
echo "\"git push\" while having the *$DEV_BRANCH* branch checked out will push local commits to the $DEV_BRANCH, $TRACK_BRANCH and master branches of your forked repository."
echo "\"git pull\" while having the *$TRACK_BRANCH* branch checked out will pull changes from the upstream $TRACK_BRANCH and master branches into your local $TRACK_BRANCH and master branches."
echo
}

# Setup required params
case $1 in
'') echo $USAGE;print_help;exit 1 ;;
*) GITHUB_ACCOUNT="$1" ;;
esac
case $2 in
'') echo $USAGE;print_help;exit 1 ;;
*) MAIN_PROJECT="$2" ;;
esac
case $3 in
'') echo $USAGE;print_help;exit 1 ;;
*) MAIN_USER="$3" ;;
esac

MAIN_REPOSITORY="git://github.com/$MAIN_USER/$MAIN_PROJECT.git"
REMOTE="$GITHUB_ACCOUNT"
REMOTE_URL="git@github.com:$GITHUB_ACCOUNT/$MAIN_PROJECT.git"

# Clone official $MAIN_PROJECT repository
#
# This sets the local master branch to be equal to the official $MAIN_PROJECT
# master
#
echo "Cloning official [$MAIN_PROJECT] repository..."
git clone $MAIN_REPOSITORY
catch_error $? "cloning official $MAIN_PROJECT repository"

echo

# Change directory into local $MAIN_PROJECT repository
#
cd $MAIN_PROJECT

# Create a local branch that tracks the forked edge/development branch
#
echo "Creating local tracking branch for [$TRACK_BRANCH]..."
git branch --track $TRACK_BRANCH origin/$TRACK_BRANCH
catch_error $? "creating local tracking branch for $TRACK_BRANCH"

echo

# Create a local branch based off $TRACK_BRANCH
#
echo "Creating local development branch $DEV_BRANCH..."
git branch $DEV_BRANCH $TRACK_BRANCH
catch_error $? "creating local branch $DEV_BRANCH"

git checkout $DEV_BRANCH
catch_error $? "checking out local branch $DEV_BRANCH"

echo

# Add forked repository as a remote repository connection
#
# The GitHub account name will be used to refer to this repository
#
echo "Adding remote [$REMOTE] connection to forked repository..."
git remote add $REMOTE $REMOTE_URL
catch_error $? "adding remote $REMOTE"

echo

# Fetch branch information
#
echo "Fetching remote branch information from [$REMOTE]..."
git fetch $REMOTE
catch_error $? "fetching branches from remote $REMOTE"

echo

# Create the matching remote branch on the forked repository
#
# We need to explicitly create the branch via a push command
#
echo "Pushing local branch [$BRANCH] to remote [$REMOTE]..."
git push $REMOTE $DEV_BRANCH:refs/heads/$DEV_BRANCH
catch_error $? "pushing local branch $DEV_BRANCH to remote $REMOTE"

echo

# Configure the remote connection for the local branch
#
echo "Configuring remote [$REMOTE] for local branch [$DEV_BRANCH]..."
git config branch.$DEV_BRANCH.remote $REMOTE
catch_error $? "configuring remote $REMOTE for local branch $DEV_BRANCH"
git config branch.$DEV_BRANCH.merge refs/heads/$DEV_BRANCH
catch_error $? "configuring merge tracking for local branch $DEV_BRANCH"

echo
echo "-- Finished clone configuration --"
print_help

exit $?
