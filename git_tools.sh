#!/bin/bash
# Script Name: git_tools.sh
# Description: Set of git helper fns.
# Author: Paul Caciula <paul.caciula@nbcuni.com>
# Date: 2024-11-19
# Version: 1.0

#================================= GIT TOOLS =================================#
alias newBranch='newBranchFromMain'
alias nb='newBranchFromMain'
alias rebase='rebaseMain'
alias r='rebaseMain'
alias prr='checkoutPrReview'
alias refm='refreshMainBranch'
alias gpsu='pushSetUpstream'
alias gpfl='gitPushForceLease'
alias reMain='rebaseKeepingMainOnly'
alias reLocal='rebaseKeepingLocalOnly'
alias commit='commitBranch'
alias c='commitBranch'
alias ccomit='commitBranchConventional'
alias cc='commitBranchConventional'

#-------- HELPER FUNCTIONS--------#
  # Create a new branch off the latest main branch from ticket number(at least).
  # $1: Ticket Number (required)...this doesn't strictly need to be numeric.
  # $2: Prefix (default "feature", "<none>" will ommit entirely)
  # $3: Project (default "KOCO", "<no-project>" will ommit including dash)
  newBranchFromMain() {
    refreshMainBranch && git checkout -b $(branchFromParts "$@")
  }
  # Simply commit the current branch with the message passed as the first param.
  # $1: The content of the commit message (minus the prefix).
  commitBranch() {
    branch=$(branch)
    msg=$1;
    git commit -am "\"$(branch): $1\"";
  }
  # Make a commit using conventional style - options must be passed as named.
  # usage: commitBranchConventional -m "My Commit Message" -t="chore" -s="myModule"
  # --type|-t: commit msg type (defaults feat)
  # --scope|-s: commit msg scope (defaults empty)
  # --message|-m: actual commit msg (description) (required).
  commitBranchConventional() {
    branch=$(branch)
    msg=$(conventionCommitFromArgs "$@");
    git commit -am "\"$msg\"";
  }
  # Refresh local copy of main branch from upstream. Assumes same name.
  refreshMainBranch() {
    mainBranch=$(mainBranch);
    git fetch --all && git checkout $(mainBranchName $mainBranch) && git reset --hard "$mainBranch";
  }
  # Force push current branch with lease.
  gitPushForceLease() {
    git push --force-with-lease;
  }
  # Push current branch for the first time setting upstream
  pushSetUpstream() {
    git push --set-upstream $(upstreamName) $(branch);
  }
  # Just rebase against upstream main branch.
  rebaseMain() {
    git rebase $(mainBranch);
  }
  # Perform a rebase keeping upstream changes discarding local conflicts.
  rebaseKeepingMainOnly() {
    # this is confusing but correct (reversed in rebase).
    git rebase -X ours;
  }
  # Perform a rebase keeping local changes discarding upstream conflicts.
  rebaseKeepingLocalOnly() {
    # this is confusing but correct (reversed in rebase).
    git rebase -X theirs;
  }
  # Merge latest changes from main branch into stage.
  elevateStage() {
    upstream=$(upstreamName);
    git fetch --all && git checkout stage && git reset --hard "$upstream/stage" && git merge $(getMainBranch);
  }
  # Checkout a branch for pr review from ticket number (at least).
  # $1: Ticket Number (required)...this doesn't strictly need to be numeric.
  # $2: Prefix (default "feature", "<none>" will omit entirely)
  # $3: Project (default "KOCO", "<no-project>" will ommit including dash)
  checkoutPrReview() {
    prBranch=$(branchFromParts "$@")
    upstream=$(upstreamName)
    git fetch --all;
    git checkout "$branch";
    git reset --hard "$upstream/$branch"
  }
  # Function create branch name from (at minimum) a ticket number.
  # $1: Ticket Number (required)...this doesn't strictly need to be numeric.
  # $2: Prefix (default "feature", "<none>" will omit entirely)
  # $3: Project (default "KOCO", "<no-project>" will ommit including dash)
  branchFromParts() {
    number=$1;
    prefix="${2:-feature}/";
    proj="${3:-KOCO}-";
    if [ "$2" = "<none>"  ]; then prefix=""; fi;
    if [ "$3" = "<no-project>" ]; then proj=""; fi;
    branch="${prefix}${proj}${number}";
    echo $branch;
  }
#--------- LOWER LEVEL TOOLS ---------#
  # Name of the current branch (without upstream/).
  branch() {
    git branch --show-current;
  }
  # Branch name w/upstream/ (like origin/feature/TICKET-12345).
  branchNameLong() {
    git rev-parse --abbrev-ref --symbolic-full-name @{u}
  }
  # The upstream of the current branch (like "origin").
  upstreamName() {
    local=$(branch);
    git config "branch.$local.remote"
  }
  # The main upstream branch (like "origin/master", "origin/dev", "origin/develop").
  mainBranch() {
    upstreamName=$(getUpstreamName);
    baseName="refs/remotes"
    longName=$(git symbolic-ref "$baseName/$upstreamName/HEAD");
    echo ${longName#$baseName/};
  }
  # The name of main branch
  mainBranchName(){
    withOrigin=${1:-$(getMainBranch)};
    echo ${withOrigin#$(getUpstreamName)/}
  }
  # Parse passed args and build conventional commit msg from them.
  # --type|-t: commit msg type (defaults feat)
  # --scope|-s: commit msg scope (defaults empty)
  # --message|-m: actual commit msg (description).
  conventionCommitFromArgs() {
    while [ $# -gt 0 ]; do
      case "$1" in
        --type*|-t*)
          if [[ "$1" != *=* ]]; then shift; fi # Value is next arg if no `=`
          t="${1#*=}"
          ;;
        --scope*|-s*)
          if [[ "$1" != *=* ]]; then shift; fi
          s="${1#*=}"
          ;;
        --message*|-m*)
          if [[ "$1" != *=* ]]; then shift; fi
          msg="${1#*=}"
          ;;
        --help|-h)
          printf "Eg: commitBranchConventional -t='chore' -m='My Commit message \n body'
          \n commitBranchConventional -t='feat' -s="MyModule" -m='My Commit message \n body' "
          exit 0
          ;;
        *)
          >&2 printf "Error: Invalid argument\n"
          exit 1
          ;;
      esac
      shift
    done
    if [ -z "$msg" ]; then
      >&2 printf "Error: Invalid argument\n"
      exit 1;
    fi
    type=${t:-feat}
    if [ -z "s" ]; then
        pre="$type"
    else
        pre="$type($s)"
    fi
    echo "$pre: $msg";
  }
