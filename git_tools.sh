#!/bin/bash
# Script Name: git_tools.sh
# Description: Set of git helper fns.
# Author: Paul Caciula <paul.caciula@nbcuni.com>
# Date: 2024-11-19
# Version: 1.0

#================================= GIT TOOLS =================================#
# newBranch 12345 'feature' 'MyProject'
alias newBranch='newBranchFromMain'
# nb 12345 'feature' 'MyProject'
alias nb='newBranchFromMain'
alias rebase='rebaseMain'
alias r='rebaseMain'
# prr 12345 'feature' 'MyProject'
alias prr='checkoutPrReview'
alias refm='refreshMainBranch'
alias gpsu='pushSetUpstream'
alias gpfl='gitPushForceLease'
alias reMain='rebaseKeepingMainOnly'
alias reLocal='rebaseKeepingLocalOnly'
# commit "My commit Message"
alias commit='commitBranch'
# c "My commit Message"
alias c='commitBranch'
# ccommit -m="myCommitMsg" -t="chore" -s="myModule"
alias ccomit='commitBranchConventional'
# cc -m="myCommitMsg" -t="chore" -s="myModule"
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
  # $1: The content of the commit message (minus tqhe prefix).
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
    git rebase $(mainBranch) -X ours;
  }
  # Perform a rebase keeping local changes discarding upstream conflicts.
  rebaseKeepingLocalOnly() {
    # this is confusing but correct (reversed in rebase).
    git rebase $(mainBranch) -X theirs;
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
    # we haven't switched branches yet, so use the incoming prBranch
    # to get the upstreamName.
    upstream=$(upstreamName $prBranch);
    echo "Upstream Pr Branch: $upstream/$prBranch.";
    git fetch --all;
    echo "checking out $prBranch branch locally."
    git checkout "$prBranch";
    echo "Resetting hard to upstream ($upstream/$prBranch) to get latest changes."
    git reset --hard "$upstream/$prBranch"
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
  # $1: Optionally accept a passed branch name (defaults to current branch).
  upstreamName() {
    local=${1:-$(branch)};
    git config "branch.$local.remote";
  }
  # The main upstream branch (like "origin/master", "origin/dev", "origin/develop").
  mainBranch() {
    # default to origin if we don't know any better.
    # todo: parse git remotes to make a better guess for new branches
    # not tracking anything yet.
    upstreamName=${$(upstreamName):-origin};
    baseName="refs/remotes"
    longName=$(git symbolic-ref "$baseName/$upstreamName/HEAD");
    echo ${longName#$baseName/};
  }
  # The name of main branch
  mainBranchName(){
    withOrigin=${1:-$(mainBranch)};
    echo ${withOrigin#$(upstreamName)/}
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
          echo "Usage:
  commitBranchConventional -t='chore' -m='My Commit message'
  commitBranchConventional -t='feat' -s="MyModule" -m='My Commit message'"
          return 0
          ;;
        *)
          >&2 echo "Error: Invalid argument\n"
          return 1
          ;;
      esac
      shift
    done
    if [ -z "$msg" ]; then
      >&2 printf "Error: Missing required arg (--message|-m)\n"
      return 1;
    fi
    type=${t:-feat}
    if [ -z "s" ]; then
        pre="$type"
    else
        pre="$type($s)"
    fi
    echo "$pre: $msg";
  }
